import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Deepgram {
  Deepgram(this.apiKey);

  final String apiKey;
  final String _baseUrl = 'https://api.deepgram.com/v1/listen';

  /// Transcribe a local audio file. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<String> transcribeFromBytes(List<int> data, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
      },
      body: data,
    );

    return res.body;
  }

  /// Transcribe a remote audio file from URL. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-remote
  Future<String> transcribeFromUrl(String url, Map<String, dynamic>? queryParams) async {
    return "";
  }
}

//for later

//   final String _liveUrl = 'wss://api.deepgram.com/v1/listen';

// /// Transcribe live audio data. Returns a stream of JSON string.
//   ///
//   /// https://developers.deepgram.com/reference/listen-live
//   Stream<String> transcribeLiveAudio(String audioUrl, Map<String, String>? queryParams) {
//     return Stream.empty();
//   }