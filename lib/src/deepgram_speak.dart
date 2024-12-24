import 'dart:convert';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/deepgram_live_speaker.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;

/// The Text to Speech API.
class DeepgramSpeak {
  DeepgramSpeak(this._client);

  final String _baseTtsUrl = 'https://api.deepgram.com/v1/speak';

  final Deepgram _client;

  /// Convert text to speech.
  ///
  /// https://developers.deepgram.com/reference/text-to-speech-api
  Future<DeepgramSpeakResult> text(String text, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseTtsUrl, _client.baseQueryParams, queryParams),
      headers: {
        Headers.authorization: 'Token ${_client.apiKey}',
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
  /// see [DeepgramLiveSpeaker] which you can also use directly
  ///
  /// https://developers.deepgram.com/docs/streaming-text-to-speech
  DeepgramLiveSpeaker liveSpeaker(Stream<String> audioStream, {Map<String, dynamic>? queryParams}) {
    return DeepgramLiveSpeaker(_client.apiKey, inputTextStream: audioStream, queryParams: mergeMaps(_client.baseQueryParams, queryParams));
  }

  /// Convert live text to speech.
  ///
  /// https://developers.deepgram.com/docs/streaming-text-to-speech
  Stream<DeepgramSpeakResult> live(Stream<String> audioStream, {Map<String, dynamic>? queryParams}) {
    DeepgramLiveSpeaker transcriber = liveSpeaker(audioStream, queryParams: queryParams);

    transcriber.start();

    return transcriber.stream;
  }
}
