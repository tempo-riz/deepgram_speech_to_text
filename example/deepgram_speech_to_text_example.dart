import 'dart:io';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';

void main() async {
  // Get your API key from the Deepgram console if you don't have one https://console.deepgram.com/
  String apiKey = "YOUR_API_KEY";

  // https://developers.deepgram.com/reference/deepgram-api-overview
  Map<String, dynamic> params = {
    'model': 'nova-2-general',
    'detect_language': true,
    'filler_words': false,
    'punctuation': true,
  };

  Deepgram deepgram = Deepgram(apiKey, baseQueryParams: params);

  // -------------------- Speech To Text --------------------
  deepgram.listen.file(File('audio.wav')); // or .path()
  deepgram.listen.url('https://somewhere/audio.wav');
  deepgram.listen.bytes(List.from([1, 2, 3, 4, 5]));

  // Streaming
  final audioStream = File('audio.wav').openRead(); // mic.stream ...

  deepgram.listen.live(audioStream); // or .liveListener()

  // -------------------- Text to Speech --------------------
  deepgram.speak.text('Hello World');

  // Streaming
  final textStream = Stream.fromIterable(['Hello', 'World']);

  deepgram.speak.live(textStream); // or .liveSpeaker()

  // -------------------- Debugging --------------------
  final isValid = await deepgram.isApiKeyValid();
  print('API key is valid: $isValid');
}
