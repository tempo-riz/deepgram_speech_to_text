import 'dart:convert';
import 'dart:io';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load();

  final apiKey = env.getOrElse("DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
  final deepgram = Deepgram(apiKey);
  final file = File('assets/jfk.wav');

  Stream<List<int>> audioStream = file.openRead();

  final DeepgramLiveTranscriber transcriber = deepgram.createLiveTranscriber(audioStream);

  transcriber.resultStream.listen((json) {
    print('JSON: $json');
    Map<String, dynamic> map = jsonDecode(json);
    String transcript = map['channel']['alternatives'][0]['transcript'];

    print('Transcript: $transcript');
  }, onDone: () {
    print('Done');
  }, onError: (error) {
    print('Error: $error');
  });

  await transcriber.start();

  await Future.delayed(Duration(seconds: 5));

  await transcriber.stop();
}
