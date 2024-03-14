import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';

import 'package:http/http.dart' as http;

class DeepgramLiveTranscriber {
  DeepgramLiveTranscriber(this.channel, this.inputAudioStream);

  final IOWebSocketChannel channel;
  final Stream<List<int>> inputAudioStream;
  final StreamController<String> _outputTranscriptStream = StreamController<String>();
  late StreamSubscription _channelSubscription;

  Future<void> start() async {
    await channel.ready;
    _channelSubscription = channel.stream.listen((event) {
      _outputTranscriptStream.add(event.toString());
    }, onDone: () {
      stop();
    }, onError: (error) {
      _outputTranscriptStream.addError(error);
    });

    await for (var data in inputAudioStream) {
      channel.sink.add(data);
    }
  }

  Future<void> stop() async {
    await _channelSubscription.cancel();
    await channel.sink.close();
    await _outputTranscriptStream.close();
  }

  Stream<String> get resultStream => _outputTranscriptStream.stream;
}

class Deepgram {
  Deepgram(this.apiKey);

  final String apiKey;
  final String _baseUrl = 'https://api.deepgram.com/v1/listen';
  final String _baseLiveUrl = 'wss://api.deepgram.com/v1/listen';

  /// Builds a URL with query parameters.
  Uri _buildUrl(String baseUrl, Map<String, dynamic>? queryParams) {
    if (queryParams == null) {
      return Uri.parse(baseUrl);
    }
    final uri = Uri.parse(baseUrl);
    final newUri = uri.replace(queryParameters: queryParams);
    return newUri;
  }

  /// Transcribe a local audio file. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<String> transcribeFromBytes(List<int> data, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      _buildUrl(_baseUrl, queryParams),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
      },
      body: data,
    );

    return res.body;
  }

  Future<String> transcribeFromFile(File file, {Map<String, dynamic>? queryParams}) {
    assert(file.existsSync());
    final Uint8List bytes = file.readAsBytesSync();

    return transcribeFromBytes(bytes, queryParams: queryParams);
  }

  /// Transcribe a remote audio file from URL. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-remote
  Future<String> transcribeFromUrl(String url, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      _buildUrl(_baseUrl, queryParams),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({'url': url}),
    );

    return res.body;
  }

  /// Create a live transcriber from a stream of audio data.
  ///
  /// https://developers.deepgram.com/reference/listen-live
  DeepgramLiveTranscriber createLiveTranscriber(Stream<List<int>> audioStream, {Map<String, String>? queryParams}) {
    final channel = IOWebSocketChannel.connect(
      _buildUrl(_baseLiveUrl, queryParams),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
      },
    );

    return DeepgramLiveTranscriber(channel, audioStream);
  }

  Stream<String> transcribeFromLiveAudioStream(Stream<List<int>> audioStream, {Map<String, String>? queryParams}) {
    DeepgramLiveTranscriber transcriber = createLiveTranscriber(audioStream, queryParams: queryParams);

    transcriber.start();
    return transcriber.resultStream;
  }
}
