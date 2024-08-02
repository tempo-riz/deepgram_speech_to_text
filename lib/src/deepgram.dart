import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/src/types.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:universal_file/universal_file.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'types.dart';

/// Class used to transcribe live audio streams.
class DeepgramLiveTranscriber {
  /// Create a live transcriber with a start and close method
  DeepgramLiveTranscriber(this.apiKey,
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
  final StreamController<DeepgramSttResult> _outputTranscriptStream =
      StreamController<DeepgramSttResult>();
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
      _outputTranscriptStream.addError(DeepgramSttResult('', error: error));
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
        if (!_isPaused) {
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
  void _handleWebSocketMessage(dynamic event) {
    // Parse the event data as JSON.
    final message = jsonDecode(event);

    // Determine the message type and handle accordingly.
    if (message.containsKey('type')) {
      switch (message['type']) {
        case 'Results':
          _outputTranscriptStream.add(DeepgramSttResult(event));
          break;
        case 'UtteranceEnd':
          // Handle UtteranceEnd message.
          _outputTranscriptStream.add(DeepgramSttResult(event));
          break;
        case 'Metadata':
          // Handle Metadata message.
          _outputTranscriptStream.add(DeepgramSttResult(event));
          break;
        case 'SpeechStarted':
          // Handle Metadata message.
          _outputTranscriptStream.add(DeepgramSttResult(event));
          break;
        case 'Finalize':
          // Handle Metadata message.
          _outputTranscriptStream.add(DeepgramSttResult(event));
          break;
        default:
          // Handle unknown message type.
          print('Unknown message type: ${message['type']}');
      }
    } else {
      // If message type is not specified, handle as a generic message.
      _outputTranscriptStream.add(DeepgramSttResult(event));
    }
  }

  /// The result stream of the transcription process.
  Stream<DeepgramSttResult> get stream => _outputTranscriptStream.stream;

  /// Getter for isClosed stream variable
  bool get isClosed => _isClosed;
}

/// The Deepgram API client.
class Deepgram {
  Deepgram(
    this.apiKey, {
    this.baseQueryParams,
  });

  /// your Deepgram API key
  final String apiKey;
  final String _baseSttUrl = 'https://api.deepgram.com/v1/listen';
  final String _baseTtsUrl = 'https://api.deepgram.com/v1/speak';

  /// Deepgram parameters
  ///
  /// List of params here : https://developers.deepgram.com/reference/listen-file
  ///
  /// (if same params are present in both baseQueryParams and queryParams, the value from queryParams is used)
  final Map<String, dynamic>? baseQueryParams;

  /// Transcribe from raw data.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramSttResult> transcribeFromBytes(List<int> data,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseSttUrl, baseQueryParams, queryParams),
      headers: {
        Headers.authorization: 'Token $apiKey',
      },
      body: data,
    );

    return DeepgramSttResult(res.body);
  }

  /// Transcribe a local audio file.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramSttResult> transcribeFromFile(File file,
      {Map<String, dynamic>? queryParams}) {
    assert(file.existsSync());
    final Uint8List bytes = file.readAsBytesSync();

    return transcribeFromBytes(bytes, queryParams: queryParams);
  }

  /// Transcribe a local audio file from path.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramSttResult> transcribeFromPath(String path,
      {Map<String, dynamic>? queryParams}) {
    final file = File(path);
    assert(file.existsSync());
    final Uint8List bytes = file.readAsBytesSync();

    return transcribeFromBytes(bytes, queryParams: queryParams);
  }

  /// Transcribe a remote audio file from URL.
  ///
  /// https://developers.deepgram.com/reference/listen-remote
  Future<DeepgramSttResult> transcribeFromUrl(String url,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseSttUrl, baseQueryParams, queryParams),
      headers: {
        Headers.authorization: 'Token $apiKey',
        Headers.contentType: 'application/json',
        Headers.accept: 'application/json',
      },
      body: jsonEncode({'url': url}),
    );

    return DeepgramSttResult(res.body);
  }

  /// Create a live transcriber with a start and close method.
  ///
  /// see [DeepgramLiveTranscriber] which you can also use directly
  ///
  /// https://developers.deepgram.com/reference/listen-live
  DeepgramLiveTranscriber createLiveTranscriber(Stream<List<int>> audioStream,
      {Map<String, dynamic>? queryParams}) {
    return DeepgramLiveTranscriber(apiKey,
        inputAudioStream: audioStream,
        queryParams: mergeMaps(baseQueryParams, queryParams));
  }

  /// Transcribe a live audio stream.
  ///
  /// https://developers.deepgram.com/reference/listen-live
  Stream<DeepgramSttResult> transcribeFromLiveAudioStream(
      Stream<List<int>> audioStream,
      {Map<String, dynamic>? queryParams}) {
    DeepgramLiveTranscriber transcriber =
        createLiveTranscriber(audioStream, queryParams: queryParams);

    transcriber.start();
    return transcriber.stream;
  }

  /// Check if the API key is valid and if you still have credits
  ///
  /// (try to transcribe a 1 sec sample audio file)
  Future<bool> isApiKeyValid() async {
    http.Response res = await http.post(
      buildUrl(
          _baseSttUrl,
          {
            'language': 'fr',
          },
          null),
      headers: {
        Headers.authorization: 'Token $apiKey',
        Headers.contentType: 'audio/*',
      },
      body: getSampleAudioData(),
    );

    return res.statusCode == 200;
  }

  /// Convert text to speech.
  ///
  /// https://developers.deepgram.com/reference/text-to-speech-api
  Future<DeepgramTtsResult> speakFromText(String text,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseTtsUrl, baseQueryParams, queryParams),
      headers: {
        Headers.authorization: 'Token $apiKey',
        Headers.contentType: 'application/json',
      },
      body: jsonEncode({
        'text': toUt8(text),
      }),
    );

    return DeepgramTtsResult(data: res.bodyBytes, headers: res.headers);
  }
}
