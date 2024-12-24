import 'dart:convert';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/deepgram_live_transcriber.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:universal_file/universal_file.dart';

class DeepgramListen {
  DeepgramListen(
    this.client,
  ) {
    print('DeepgramListen constructor');
  }

  final String _baseSttUrl = 'https://api.deepgram.com/v1/listen';

  final Deepgram client;

  /// Transcribe from raw data.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramSttResult> transcribeFromBytes(List<int> data, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseSttUrl, client.baseQueryParams, queryParams),
      headers: {
        Headers.authorization: 'Token ${client.apiKey}',
      },
      body: data,
    );

    return DeepgramSttResult(res.body);
  }

  /// Transcribe a local audio file.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramSttResult> transcribeFromFile(File file, {Map<String, dynamic>? queryParams}) async {
    assert(file.existsSync());
    final bytes = await file.readAsBytes();

    return transcribeFromBytes(bytes, queryParams: queryParams);
  }

  /// Transcribe a local audio file from path.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<DeepgramSttResult> transcribeFromPath(String path, {Map<String, dynamic>? queryParams}) {
    final file = File(path);
    return transcribeFromFile(file, queryParams: queryParams);
  }

  /// Transcribe a remote audio file from URL.
  ///
  /// https://developers.deepgram.com/reference/listen-remote
  Future<DeepgramSttResult> transcribeFromUrl(String url, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseSttUrl, client.baseQueryParams, queryParams),
      headers: {
        Headers.authorization: 'Token ${client.apiKey}',
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
  DeepgramLiveTranscriber createLiveTranscriber(Stream<List<int>> audioStream, {Map<String, dynamic>? queryParams}) {
    return DeepgramLiveTranscriber(client.apiKey, inputAudioStream: audioStream, queryParams: mergeMaps(client.baseQueryParams, queryParams));
  }

  /// Transcribe a live audio stream.
  ///
  /// https://developers.deepgram.com/reference/listen-live
  Stream<DeepgramSttResult> transcribeFromLiveAudioStream(Stream<List<int>> audioStream, {Map<String, dynamic>? queryParams}) {
    DeepgramLiveTranscriber transcriber = createLiveTranscriber(audioStream, queryParams: queryParams);

    transcriber.start();
    return transcriber.stream;
  }
}
