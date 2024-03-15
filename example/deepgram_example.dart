import 'dart:io';
import 'package:deepgram_speech_to_text/deepgram.dart';

void main() async {
  // Get your API key from the Deepgram console if you don't have one https://console.deepgram.com/
  String apiKey = "YOUR_API_KEY";

  // you can pass optional query parameters in :
  // - the constructore for all requests
  // - the method for a specific request
  // reference : https://developers.deepgram.com/reference/listen-file
  Map<String, dynamic> params = {
    'model': 'nova-2-general',
    'language': 'latest',
    'filler_words': false,
    'punctuation': true,
  };

  Deepgram deepgram = Deepgram(apiKey, baseQueryParams: params);

  // -------------------- From a file --------------------
  File audioFile = File('audio.wav');

  String json1 = await deepgram.transcribeFromFile(audioFile);
  print(json1);

  // -------------------- From a URL --------------------
  String json2 = await deepgram.transcribeFromUrl('https://somewhere/audio.wav');
  print(json2);

  // -------------------- From raw data --------------------
  String json3 = await deepgram.transcribeFromBytes(List.from([1, 2, 3, 4, 5]));
  print(json3);

  // -------------------- From a stream  --------------------
  Stream<List<int>> audioStream = audioFile.openRead(); // mic.stream ...

  Stream<String> jsonStream = deepgram.transcribeFromLiveAudioStream(audioStream);

  jsonStream.listen((json) {
    print(json);
  });

  // if you prefer to have more control over the stream:

  final DeepgramLiveTranscriber transcriber = deepgram.createLiveTranscriber(audioStream);

  transcriber.start();

  transcriber.jsonStream.listen((json) {
    print(json);
  });

  transcriber.close();
}
