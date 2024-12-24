import 'dart:convert';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;

class DeepgramSpeak {
  DeepgramSpeak(this.client);

  final String _baseTtsUrl = 'https://api.deepgram.com/v1/speak';

  final Deepgram client;

  /// Convert text to speech.
  ///
  /// https://developers.deepgram.com/reference/text-to-speech-api
  Future<DeepgramTtsResult> speakFromText(String text, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      buildUrl(_baseTtsUrl, client.baseQueryParams, queryParams),
      headers: {
        Headers.authorization: 'Token ${client.apiKey}',
        Headers.contentType: 'application/json',
      },
      body: jsonEncode({
        'text': toUt8(text),
      }),
    );

    return DeepgramTtsResult(data: res.bodyBytes, headers: res.headers);
  }
}
