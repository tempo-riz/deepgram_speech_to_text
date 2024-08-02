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
    'detect_language': true,
    'filler_words': false,
    'punctuation': true,
    //...
  };

  Deepgram deepgram = Deepgram(apiKey, baseQueryParams: params);

  // check if the API key is valid
  final isValid = await deepgram.isApiKeyValid();
  print('API key is valid: $isValid');

  // -------------------- From a file --------------------
  File audioFile = File('audio.wav');

  final res1 = await deepgram.transcribeFromFile(audioFile);
  print(res1.transcript);

  // -------------------- From a URL --------------------
  final res2 = await deepgram.transcribeFromUrl('https://somewhere/audio.wav');
  print(res2.transcript);

  // -------------------- From raw data --------------------
  final res = await deepgram.transcribeFromBytes(List.from([1, 2, 3, 4, 5]));
  print(res.transcript);

  // -------------------- From a stream  --------------------
  // For example : from a microphone https://pub.dev/packages/record (other packages would work too as long as they provide a stream)
  // final audioStream = await AudioRecorder().startStream(RecordConfig(
  //   encoder: AudioEncoder.pcm16bits,
  //   sampleRate: 16000,
  //   numChannels: 1,
  // ));

  Stream<List<int>> audioStream = audioFile.openRead(); // mic.stream ...

  Stream<DeepgramSttResult> resStream =
      deepgram.transcribeFromLiveAudioStream(audioStream);

  resStream.listen((res) {
    print(res.transcript);
  });

  // If you prefer to have more control over the stream:

  final DeepgramLiveTranscriber transcriber =
      deepgram.createLiveTranscriber(audioStream);

  transcriber.start();

  transcriber.stream.listen((json) {
    print(json);
  });
  transcriber.close();
  // after that you can call start() again, no need to create a new transcriber :)

  // -------------------- Text to Speech --------------------
  final dg = Deepgram(apiKey);
  final res3 = await dg.speakFromText('Hello, how are you?');
  // then use res as you like
  res3.data; // Uint8List of audio data
  res3.contentType; // 'audio/wav'
}
