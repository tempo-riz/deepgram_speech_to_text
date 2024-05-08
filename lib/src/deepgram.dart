import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:deepgram_speech_to_text/src/utils.dart';

import 'package:http/http.dart' as http;
import 'package:universal_file/universal_file.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class DeepgramLiveTranscriber {
  /// Create a live transcriber with a start and close method
  DeepgramLiveTranscriber(this.apiKey,
      {required this.inputAudioStream, this.queryParams});

  final Stream<List<int>> inputAudioStream;
  final StreamController<String> _outputTranscriptStream =
      StreamController<String>();
  final String apiKey;
  final String _baseLiveUrl = 'wss://api.deepgram.com/v1/listen';
  late WebSocketChannel wsChannel;

  final Map<String, dynamic>? queryParams;

  /// Start the transcription process.
  Future<void> start() async {
    wsChannel = WebSocketChannel.connect(
      buildUrl(_baseLiveUrl, null, queryParams),
      protocols: ['token', apiKey],
      // equivalent to: (which woudn't work if kPlatformWeb is not defined)
      // headers: {
      //   HttpHeaders.authorizationHeader: 'Token $apiKey',
      // },
    );
    await wsChannel.ready;

    //can listen only once to the channel
    wsChannel.stream.listen((event) {
      if (_outputTranscriptStream.isClosed) {
        close();
      } else {
        _outputTranscriptStream.add(event);
      }
    }, onDone: () {
      close();
    }, onError: (error) {
      _outputTranscriptStream.addError(error);
    });

    // listen to the input audio stream and send it to the channel if it's still open
    inputAudioStream.listen((data) {
      if (wsChannel.closeCode != null) {
        close();
      } else {
        wsChannel.sink.add(data);
      }
    }, onDone: () {
      close();
    });
  }

  /// End the transcription process.
  Future<void> close() async {
    await wsChannel.sink.close(status.normalClosure);
    await _outputTranscriptStream.close();
  }

  Stream<String> get jsonStream => _outputTranscriptStream.stream;
}

class Deepgram {
  /// if same params are present in both baseQueryParams and queryParams, the value from queryParams is used
  Deepgram(
    this.apiKey, {
    this.baseQueryParams,
  });

  final String apiKey;
  final String _baseUrl = 'https://api.deepgram.com/v1/listen';
  final Map<String, dynamic>? baseQueryParams;

  /// Transcribe from raw data. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<String> transcribeFromBytes(List<int> data,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseUrl, baseQueryParams, queryParams),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
      },
      body: data,
    );

    return res.body;
  }

  /// Transcribe a local audio file. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<String> transcribeFromFile(File file,
      {Map<String, dynamic>? queryParams}) {
    assert(file.existsSync());
    final Uint8List bytes = file.readAsBytesSync();

    return transcribeFromBytes(bytes, queryParams: queryParams);
  }

  /// Transcribe a remote audio file from URL. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-remote
  Future<String> transcribeFromUrl(String url,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseUrl, baseQueryParams, queryParams),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({'url': url}),
    );

    return res.body;
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

  /// Transcribe a live audio stream. Returns a stream of JSON strings.
  ///
  /// https://developers.deepgram.com/reference/listen-live
  Stream<String> transcribeFromLiveAudioStream(Stream<List<int>> audioStream,
      {Map<String, dynamic>? queryParams}) {
    DeepgramLiveTranscriber transcriber =
        createLiveTranscriber(audioStream, queryParams: queryParams);

    transcriber.start();
    return transcriber.jsonStream;
  }

  Future<bool> isApiKeyValid() async {
    http.Response res = await http.post(
      buildUrl(
          _baseUrl,
          {
            'language': 'fr',
          },
          null),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
        HttpHeaders.contentTypeHeader: 'audio/*',
      },
      body: getSampleAudioData(),
      encoding: Encoding.getByName('utf-8'),
    );

    return res.statusCode == 200;
  }
}

extension Transcript on Map<String, dynamic> {
  String get transcript =>
      toUt8(this['results']['channels'][0]['alternatives'][0]['transcript']);
}
