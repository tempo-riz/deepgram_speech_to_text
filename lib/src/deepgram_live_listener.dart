import 'dart:async';
import 'dart:convert';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Class used to transcribe live audio streams.
class DeepgramLiveListener {
  /// Create a live transcriber with a start and close method
  DeepgramLiveListener(this.apiKey,
      {required this.inputAudioStream, this.queryParams});

  /// if transcriber was closed
  bool _isClosed = false;

  /// if transcriber is paused
  bool _isPaused = false;

  /// if web socket throwed error during initialization
  bool _hasInitializationException = false;

  /// Your Deepgram API key
  final String apiKey;

  /// The audio stream to transcribe.
  final Stream<List<int>> inputAudioStream;

  /// The additionals query parameters.
  final Map<String, dynamic>? queryParams;

  final String _baseLiveUrl = 'wss://api.deepgram.com/v1/listen';
  final StreamController<DeepgramListenResult> _outputTranscriptStream =
      StreamController<DeepgramListenResult>();
  late WebSocketChannel _wsChannel;
  Timer? _keepAliveTimer;

  /// Start the transcription process.
  Future<void> start() async {
    _wsChannel = WebSocketChannel.connect(
      buildUrl(_baseLiveUrl, null, queryParams),
      protocols: ['token', apiKey],
    );

    try {
      await _wsChannel.ready;
    } catch (_) {
      // Throw during initialization ws, assign exception to true
      _hasInitializationException = true;
      rethrow;
    }

    // reset state in case of restart
    _isClosed = false;
    _isPaused = false;

    // can listen only once to the channel
    _wsChannel.stream.listen((event) {
      if (_outputTranscriptStream.isClosed) {
        close();
      } else {
        _handleWebSocketMessage(event);
      }
    }, onDone: () {
      close();
    }, onError: (error) {
      _outputTranscriptStream.addError(DeepgramListenResult('', error: error));
    });

    // listen to the input audio stream and send it to the channel if it's still open
    inputAudioStream.listen((data) {
      if (_isClosed || _isPaused) return;

      if (_wsChannel.closeCode != null) {
        close();
        return;
      }

      _wsChannel.sink.add(data);
    }, onDone: () {
      close();
    });
  }

  /// End the transcription process.
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    _keepAliveTimer?.cancel();

    // Close ws sink only when ws has been connected, otherwise future will never complete
    if (!_hasInitializationException) {
      await _wsChannel.sink.close();
    } else {
      unawaited(_wsChannel.sink.close());
    }

    // If stream has listener then we can await for close result
    if (_outputTranscriptStream.hasListener) {
      await _outputTranscriptStream.close();
    } else {
      // Otherwise when stream does not have listener, close will never return future
      unawaited(_outputTranscriptStream.close());
    }
  }

  /// Stop sending audio data until resume is called.
  ///
  /// KeepAlive is sent every 8 seconds to keep the connection alive, you can disable it by setting keepAlive to false
  void pause({bool keepAlive = true}) {
    if (_isPaused) return;

    if (keepAlive) {
      // start the keep alive process https://developers.deepgram.com/docs/keep-alive
      // send every 8 seconds a keep alive message (closes after 10 seconds of inactivity)
      _keepAliveTimer = Timer.periodic(Duration(seconds: 8), (timer) {
        // if transcriber is resumed or closed, cancel the timer
        if (!_isPaused || isClosed) {
          timer.cancel();
          _keepAliveTimer = null;
          return;
        }
        try {
          _wsChannel.sink.add(jsonEncode({'type': 'KeepAlive'}));
        } catch (e) {
          print('KeepAlive error: $e');
        }
      });
    }
    _isPaused = true;
  }

  /// Resume the transcription process.
  void resume() {
    if (!_isPaused) return;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _isPaused = false;
  }

  /// Handle incoming WebSocket messages based on their type.
  void _handleWebSocketMessage(String json) {
    _outputTranscriptStream.add(DeepgramListenResult(json));
  }

  /// The result stream of the transcription process.
  Stream<DeepgramListenResult> get stream => _outputTranscriptStream.stream;

  /// Getter for isClosed stream variable
  bool get isClosed => _isClosed;
}
