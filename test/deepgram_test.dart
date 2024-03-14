import 'dart:typed_data';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  group('[API testing]', () {
    final env = DotEnv()..load();

    final apiKey = env.getOrElse("DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
    final deepgram = Deepgram(apiKey);

    test('transcribeFromBytes', () async {
      final file = File('assets/jfk.wav');

      expect(file.existsSync(), isTrue);

      final Uint8List bytes = file.readAsBytesSync();

      expect(bytes.length, greaterThan(0));

      final json = await deepgram.transcribeFromBytes(bytes);

      // Parse the JSON response
      Map<String, dynamic> map = jsonDecode(json);

      // Extract the transcript
      String transcript = map['results']['channels'][0]['alternatives'][0]['transcript'];
      expect(transcript, isNotEmpty);
    });

    test('transcribeFromFile', () async {
      final file = File('assets/jfk.wav');

      expect(file.existsSync(), isTrue);

      final json = await deepgram.transcribeFromFile(file);

      // Parse the JSON response
      Map<String, dynamic> map = jsonDecode(json);

      String transcript = map['results']['channels'][0]['alternatives'][0]['transcript'];
      expect(transcript, isNotEmpty);
    });
  });
}
