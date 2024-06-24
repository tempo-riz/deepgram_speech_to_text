import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:deepgram_speech_to_text/src/utils.dart';

import 'package:http/http.dart' as http;
import 'package:universal_file/universal_file.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Class used to transcribe live audio streams.
class DeepgramLiveTranscriber {
  /// Create a live transcriber with a start and close method
  DeepgramLiveTranscriber(this.apiKey,
      {required this.inputAudioStream, this.queryParams});

  /// your Deepgram API key
  final String apiKey;

  /// The audio stream to transcribe.
  final Stream<List<int>> inputAudioStream;

  /// The additionals query parameters.
  final Map<String, dynamic>? queryParams;

  final String _baseLiveUrl = 'wss://api.deepgram.com/v1/listen';
  final StreamController<DeepgramSttResult> _outputTranscriptStream =
      StreamController<DeepgramSttResult>();
  late WebSocketChannel _wsChannel;
  bool _isClosed = false;

  /// Start the transcription process.
  Future<void> start() async {
    _wsChannel = WebSocketChannel.connect(
      buildUrl(_baseLiveUrl, null, queryParams),
      protocols: ['token', apiKey],
      // equivalent to: (which woudn't work if kPlatformWeb is not defined)
      // headers: {
      //   Headers.authorizationHeader: 'Token $apiKey',
      // },
    );
    await _wsChannel.ready;
    _isClosed = false;

    // can listen only once to the channel
    _wsChannel.stream.listen((event) {
      if (_outputTranscriptStream.isClosed) {
        close();
      } else {
        _outputTranscriptStream.add(DeepgramSttResult(event));
      }
    }, onDone: () {
      close();
    }, onError: (error) {
      _outputTranscriptStream.addError(DeepgramSttResult('', error: error));
    });

    // listen to the input audio stream and send it to the channel if it's still open
    inputAudioStream.listen((data) {
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
    await _wsChannel.sink.close(status.normalClosure);
    await _outputTranscriptStream.close();
  }

  /// The result stream of the transcription process.
  Stream<DeepgramSttResult> get stream => _outputTranscriptStream.stream;
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

/// Represents the result of a TTS request.
class DeepgramTtsResult {
  /// The audio data.
  final Uint8List data;

  /// The headers returned by the Deepgram API.
  final Map<String, String> headers;

  /// The content type of the audio data. (e.g. 'audio/wav')
  String? get contentType => headers['content-type'];

  DeepgramTtsResult({
    required this.data,
    required this.headers,
  });

  @override
  String toString() {
    return 'DeepgramTtsResult -> contentType: "$contentType", data size: ${data.length} bytes';
  }
}

/// Represents the result of a STT request.
class DeepgramSttResult {
  DeepgramSttResult(this.json, {this.error});

  /// The JSON string returned by the Deepgram API.
  final String json;

  /// The JSON string parsed into a map.
  Map<String, dynamic> get map => jsonDecode(json);

  /// The transcription from the JSON string.
  // sync : ['results']['channels'][0]['alternatives'][0]['transcript']
  // stream : ['channel']['alternatives'][0]['transcript']
  String get transcript {
    return toUt8(map.containsKey('results')
        ? map['results']['channels'][0]['alternatives'][0]['transcript']
        : map['channel']['alternatives'][0]['transcript']);
  }

  /// Error maybe returned by the Deepgram API.
  final dynamic error;

  @override
  String toString() {
    return 'DeepgramSttResult -> transcript: "$transcript"${error != null ? ',\n error: $error' : ''} \n\n consider using .json .map or .transcript !';
  }
}
