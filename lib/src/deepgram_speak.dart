import 'dart:convert';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;

/// The Text to Speech API.
class DeepgramSpeak {
  DeepgramSpeak(this._client) {
    _baseTtsUrl = '${_client.baseUrl}/speak';
  }

  late final String _baseTtsUrl;

  final Deepgram _client;

  /// Convert text to speech.
  ///
  /// https://developers.deepgram.com/reference/text-to-speech-api
  Future<DeepgramSpeakResult> text(String text,
      {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseTtsUrl, _client.baseQueryParams, queryParams),
      headers: {
        Headers.authorization: _client.isJwt ? 'Bearer ${_client.apiKey}' : 'Token ${_client.apiKey}',
        Headers.contentType: 'application/json',
      },
      body: jsonEncode({
        'text': toUt8(text),
      }),
    );

    return DeepgramSpeakResult(data: res.bodyBytes, metadata: res.headers);
  }

  /// Create a live speaker with a start(), flush(), clear() and close() method.
  ///
  /// (currently only wav is supported)
  ///
  /// see [DeepgramLiveSpeaker] which you can also use directly
  ///
  /// https://developers.deepgram.com/docs/streaming-text-to-speech
  DeepgramLiveSpeaker liveSpeaker(
    Stream<String> audioStream, {
    Map<String, dynamic>? queryParams,
    String encoding = 'linear16',
    int sampleRate = 16000,
  }) {
    // make sure encoding and sample rate are set
    final requiredParams = {
      'encoding': encoding,
      'sample_rate': sampleRate,
    };

    final baseParams = mergeMaps(requiredParams, _client.baseQueryParams);

    return DeepgramLiveSpeaker(_client.apiKey,
        inputTextStream: audioStream,
        queryParams: mergeMaps(baseParams, queryParams));
  }

  /// Convert live text to speech. (currently only wav is supported)
  ///
  /// https://developers.deepgram.com/docs/streaming-text-to-speech
  Stream<DeepgramSpeakResult> live(
    Stream<String> audioStream, {
    Map<String, dynamic>? queryParams,
    String encoding = 'linear16',
    int sampleRate = 16000,
  }) {
    DeepgramLiveSpeaker transcriber = liveSpeaker(audioStream,
        queryParams: queryParams, encoding: encoding, sampleRate: sampleRate);

    transcriber.start();

    return transcriber.stream;
  }
}
