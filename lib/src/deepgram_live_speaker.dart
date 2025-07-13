import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Class used to transcribe live audio streams.
///
/// https://developers.deepgram.com/reference/transform-text-to-speech-websocket
class DeepgramLiveSpeaker {
  /// Create a live transcriber with a start and close method
  DeepgramLiveSpeaker(this.apiKey, {required this.inputTextStream, this.queryParams, this.isJwt = false});

  /// if transcriber was closed
  bool _isClosed = false;

  /// if web socket throwed error during initialization
  bool _hasInitializationException = false;

  /// Your Deepgram API key
  final String apiKey;

  /// The text stream to speak.
  final Stream<String> inputTextStream;

  /// Whether or not the apiKey is a short-lived JWT
  final bool isJwt;

  /// The additionals query parameters.
  final Map<String, dynamic>? queryParams;
  final String _baseLiveUrl = 'wss://api.deepgram.com/v1/speak';
  final StreamController<DeepgramSpeakResult> _outputAudioStream = StreamController<DeepgramSpeakResult>();
  late WebSocketChannel _wsChannel;

  /// Start the transcription process.
  Future<void> start() async {
    _wsChannel = WebSocketChannel.connect(buildUrl(_baseLiveUrl, queryParams), protocols: buildAuthProtocols(isJwt, apiKey));

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
      if (_outputAudioStream.isClosed) {
        close();
      } else {
        _handleWebSocketMessage(event);
      }
    }, onDone: () {
      close();
    }, onError: (error) {
      _outputAudioStream.addError(DeepgramSpeakResult(error: error));
    });

    // listen to the input text stream and send it to the channel if it's still open
    inputTextStream.listen((text) {
      if (_isClosed) return;

      if (_wsChannel.closeCode != null) {
        close();
        return;
      }

      final msg = {
        'type': 'Speak',
        'text': text,
      };

      _wsChannel.sink.add(jsonEncode(msg));
    }, onDone: () {
      close();
    });
  }

  /// https://developers.deepgram.com/docs/tts-ws-flush
  Future<void> flush() async {
    if (_isClosed) return;

    final msg = {
      'type': 'Flush',
    };

    _wsChannel.sink.add(jsonEncode(msg));
  }

  /// https://developers.deepgram.com/docs/tts-ws-clear
  Future<void> clear() async {
    if (_isClosed) return;

    final msg = {
      'type': 'Clear',
    };

    _wsChannel.sink.add(jsonEncode(msg));
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
    if (_outputAudioStream.hasListener) {
      await _outputAudioStream.close();
    } else {
      // Otherwise when stream does not have listener, close will never return future
      unawaited(_outputAudioStream.close());
    }
  }

  /// Handle incoming WebSocket messages based on their type.
  void _handleWebSocketMessage(dynamic msg) {
    // first msg is json with metadata :
    // {"type":"Metadata","request_id":"1b051972-4d9e-47d3-83d0-6685786db1f2","model_name":"aura-asteria-en","model_version":"2024-11-19.0","model_uuid":"ecb76e9d-f2db-4127-8060-79b05590d22f"}
    try {
      if (msg is String) {
        return _outputAudioStream.add(DeepgramSpeakResult(metadata: jsonDecode(msg)));
      }
      // then raw audio data
      if (msg is Uint8List) {
        // final int? sampleRate = queryParams?['sample_rate'];
        // assert(sampleRate != null, 'sample_rate is required');

        // final wavData = toWav(msg, sampleRate!);
        return _outputAudioStream.add(DeepgramSpeakResult(data: msg));
      }
    } catch (e) {
      print('Error in _handleWebSocketMessage: $e');
      return _outputAudioStream.addError(DeepgramSpeakResult(error: e));
    }
  }

  /// The result stream of the transcription process.
  Stream<DeepgramSpeakResult> get stream => _outputAudioStream.stream;

  /// Getter for isClosed stream variable
  bool get isClosed => _isClosed;
}
