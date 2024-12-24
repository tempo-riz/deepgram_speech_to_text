import 'dart:async';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Class used to transcribe live audio streams.
///
/// https://developers.deepgram.com/docs/streaming-text-to-speech
class DeepgramLiveSpeaker {
  /// Create a live transcriber with a start and close method
  DeepgramLiveSpeaker(this.apiKey, {required this.inputTextStream, this.queryParams});

  /// if transcriber was closed
  bool _isClosed = false;

  /// if web socket throwed error during initialization
  bool _hasInitializationException = false;

  /// Your Deepgram API key
  final String apiKey;

  /// The text stream to speak.
  final Stream<String> inputTextStream;

  /// The additionals query parameters.
  final Map<String, dynamic>? queryParams;
  final String _baseLiveUrl = 'wss://api.deepgram.com/v1/speak';
  final StreamController<DeepgramListenResult> _outputTranscriptStream = StreamController<DeepgramListenResult>();
  late WebSocketChannel _wsChannel;

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
    inputTextStream.listen((data) {
      if (_isClosed) return;

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

  /// Handle incoming WebSocket messages based on their type.
  void _handleWebSocketMessage(dynamic event) {
    // If message type is not specified, handle as a generic message.
    _outputTranscriptStream.add(DeepgramListenResult(event));
  }

  /// The result stream of the transcription process.
  Stream<DeepgramListenResult> get stream => _outputTranscriptStream.stream;

  /// Getter for isClosed stream variable
  bool get isClosed => _isClosed;
}
