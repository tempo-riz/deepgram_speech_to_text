import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class Deepgram {
  Deepgram(this.apiKey);

  final String apiKey;
  final String _baseUrl = 'https://api.deepgram.com/v1/listen';

  /// Builds a URL with query parameters.
  Uri _buildUrl(Map<String, dynamic>? queryParams) {
    if (queryParams == null) {
      return Uri.parse(_baseUrl);
    }
    final uri = Uri.parse(_baseUrl);
    final newUri = uri.replace(queryParameters: queryParams);
    return newUri;
  }

  /// Transcribe a local audio file. Returns the transcription as a JSON string.
  ///
  /// https://developers.deepgram.com/reference/listen-file
  Future<String> transcribeFromBytes(List<int> data, {Map<String, dynamic>? queryParams}) async {
    http.Response res = await http.post(
      _buildUrl(queryParams),
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
      _buildUrl(queryParams),
      headers: {
        HttpHeaders.authorizationHeader: 'Token $apiKey',
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({'url': url}),
    );

    return res.body;
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