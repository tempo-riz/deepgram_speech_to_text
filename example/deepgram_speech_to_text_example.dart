import 'dart:io';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';

void main() async {
  // Get your API key from the Deepgram console if you don't have one https://console.deepgram.com/
  String apiKey = "YOUR_API_KEY";

  // You can pass optional query parameters in :
  // - the constructore for all requests
  // - the method for a specific request
  // reference : https://developers.deepgram.com/reference/listen-file
  Map<String, dynamic> params = {
    'model': 'nova-2-general',
    'language': 'fr',
    'filler_words': false,
    'punctuation': true,
  };

  Deepgram deepgram = Deepgram(apiKey, baseQueryParams: params);

  // -------------------- From a file --------------------
  File audioFile = File('audio.wav');

  String json1 = await deepgram.transcribeFromFile(audioFile);
  print(json1);

  // -------------------- From a URL --------------------
  String json2 =
      await deepgram.transcribeFromUrl('https://somewhere/audio.wav');
  print(json2);

  // -------------------- From a stream  --------------------
  // For example : from a microphone https://pub.dev/packages/record (other packages would work too as long as they provide a stream)
  // final audioStream = await AudioRecorder().startStream(RecordConfig(
  //   encoder: AudioEncoder.pcm16bits,
  //   sampleRate: 16000,
  //   numChannels: 1,
  // ));

  Stream<List<int>> audioStream = audioFile.openRead(); // mic.stream ...

  Stream<String> jsonStream =
      deepgram.transcribeFromLiveAudioStream(audioStream);

  jsonStream.listen((json) {
    print(json);
  });

  // If you prefer to have more control over the stream:

  final DeepgramLiveTranscriber transcriber =
      deepgram.createLiveTranscriber(audioStream);

  transcriber.start();

  transcriber.jsonStream.listen((json) {
    print(json);
  });
  transcriber.close();
  // after that you can call start() again, no need to create a new transcriber :)

  // -------------------- From raw data --------------------
  String json3 = await deepgram.transcribeFromBytes(List.from([1, 2, 3, 4, 5]));
  print(json3);
}
