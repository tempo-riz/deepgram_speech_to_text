import 'dart:convert';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:universal_file/universal_file.dart';

/// The Speech to Text API.
class DeepgramListen {
  DeepgramListen(this._client) {
    _baseSttUrl = '${_client.baseUrl}/listen';
  }
  late final String _baseSttUrl;

  final Deepgram _client;

  /// Transcribe from raw data.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramListenResult> bytes(List<int> data,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseSttUrl, queryParams),
      headers: {
        Headers.authorization: _client.authHeader,
      },
      body: data,
    );
    // make sure it's utf8 encoded
    return DeepgramListenResult(utf8.decode(res.bodyBytes));
  }

  /// Transcribe a local audio file.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramListenResult> file(File file,
      {Map<String, dynamic>? queryParams}) async {
    assert(file.existsSync());
    final data = await file.readAsBytes();

    return bytes(data, queryParams: queryParams);
  }

  /// Transcribe a local audio file from path.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramListenResult> path(String path,
      {Map<String, dynamic>? queryParams}) {
    final f = File(path);
    return file(f, queryParams: queryParams);
  }

  /// Transcribe a remote audio file from URL.
  ///
  /// https://developers.deepgram.com/reference/listen-remote
  Future<DeepgramListenResult> url(String url,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseSttUrl, queryParams),
      headers: {
        Headers.authorization: _client.authHeader,
        Headers.contentType: 'application/json',
        Headers.accept: 'application/json',
      },
      body: jsonEncode({'url': url}),
    );

    return DeepgramListenResult(utf8.decode(res.bodyBytes));
  }

  /// Create a live transcriber with a start and close method.
  ///
  /// see [DeepgramLiveListener] which you can also use directly
  ///
  /// https://developers.deepgram.com/reference/listen-live
  DeepgramLiveListener liveListener(
    Stream<List<int>> audioStream, {
    Map<String, dynamic>? queryParams,
    String encoding = "linear16",
    int sampleRate = 16000,
  }) {
    // make sure encoding and sample rate are set
    final requiredParams = {
      'encoding': encoding,
      'sample_rate': sampleRate,
    };
    return DeepgramLiveListener(_client,
        inputAudioStream: audioStream,
        queryParams: mergeMaps(requiredParams, queryParams));
  }

  /// Transcribe a live audio stream.
  ///
  /// https://developers.deepgram.com/reference/listen-live
  Stream<DeepgramListenResult> live(
    Stream<List<int>> audioStream, {
    Map<String, dynamic>? queryParams,
    String encoding = "linear16",
    int sampleRate = 16000,
  }) {
    final transcriber = liveListener(audioStream,
        queryParams: queryParams, encoding: encoding, sampleRate: sampleRate);

    transcriber.start();
    return transcriber.stream;
  }
}
