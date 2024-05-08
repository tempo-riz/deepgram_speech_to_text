<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 

commands :

dart doc
dart format .
flutter pub publish --dry-run
-->

A Deepgram client for Dart and Flutter. 

Currently supports Speech-To-Text (STT) features.

You need something else ? Just ask !

Feel free to create issues, contribute to this project or to ask for new features on [GitHub](https://github.com/tempo-riz/deepgram_speech_to_text) !


## Features

Speech to text (STT) transcription from:
- File
- URL
- Raw data
- Stream

  
Text to speech (TTS) soon !

## Getting started

All you need is a Deepgram API key. You can get a free one by signing up on [Deepgram](https://www.deepgram.com/)

## Usage

First create the client with optional parameters
```dart
String apiKey = 'your_api_key';

Deepgram deepgram = Deepgram(apiKey, baseQueryParams: {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuation': true,
    // more options here : https://developers.deepgram.com/reference/listen-file
});
```
Then you can transcribe audio from different sources :

## STT Result
All STT methods return a `DeepgramSttResult` object with the following properties : 
```dart
class DeepgramSttResult {
  final String json; // raw json response
  final Map<String, dynamic> map; // parsed json response into a map
  final String transcript; // the transcript extracted from the response
}
```

## File
```dart
File audioFile = File('audio.wav');
DeepgramSttResult res = await deepgram.transcribeFromFile(audioFile);
print(res.transcript); // you can also acces .json and .map (json already parsed)
```

## URL
```dart
final res = await deepgram.transcribeFromUrl('https://somewhere/audio.wav');
```



## Stream
let's say from a microphone :
```dart
//  https://pub.dev/packages/record (other packages would work too)
Stream<List<int>> micStream = await AudioRecorder().startStream(RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
));

final streamParams = {
  'detect_language': false, // not supported by streaming API
  'language': 'en',
  // must specify encoding and sample_rate according to the audio stream
  'encoding': 'linear16',
  'sample_rate': 16000,
};
```
then you got 2 options depending if you want to have more control over the stream or not :
```dart
// 1. you want the stream to manage itself automatically
Stream<DeepgramSttResult> stream = deepgram.transcribeFromLiveAudioStream(micStream, queryParams:streamParams);

// 2. you want to manage the stream manually
DeepgramLiveTranscriber transcriber = deepgram.createLiveTranscriber(micStream, queryParams:streamParams);

transcriber.start();
transcriber.stream.listen((res) {
    print(res.transcript);
});
transcriber.close(); // you can call start() after close() to restart the transcription
```

## Raw data
```dart
final res = await deepgram.transcribeFromBytes(List.from([1, 2, 3, 4, 5]));
```

For more detailed usage check the `/example` tab

There is a full flutter demo [here](https://github.com/tempo-riz/deepgram_speech_to_text/tree/main/example/flutter_example)

Tested on Android and iOS, but should work on other platforms too.



## Additional information

I created this package for my own needs since there are no dart sdk for deepgram. Happy to share !

Don't hesitate to ask for new features or to contribute !
