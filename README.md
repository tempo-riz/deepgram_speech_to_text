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

Transcribe audio from : File, URL, Stream or Raw data.

Currently only supports Speech-To-Text (STT). You need something else ? Just ask !

Feel free to create issues, contribute to this project or to ask for new features on [GitHub](https://github.com/tempo-riz/deepgram_speech_to_text) !


## Features

Speech to text transcription from:
- File
- URL
- Stream
- Raw data

## Getting started

All you need is a Deepgram API key. You can get a free one by signing up on [Deepgram](https://www.deepgram.com/)

## Usage

First create the client with optional parameters
```dart
String apiKey = 'your_api_key';

Deepgram deepgram = Deepgram(apiKey, baseQueryParams: {
    'model': 'nova-2-general',
    'language': 'fr',
    'filler_words': false,
    'punctuation': true,
  });
```
Then you can transcribe audio from different sources :


## File
```dart
File audioFile = File('audio.wav');
String json = await deepgram.transcribeFromFile(audioFile);
```

## URL
```dart
String json = await deepgram.transcribeFromUrl('https://somewhere/audio.wav');
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
```
then you got 2 options depending if you want to have more control over the stream or not :
```dart
// 1. you want the stream to manage itself automatically
Stream<String> jsonStream = deepgram.transcribeFromLiveAudioStream(micStream);

// 2. you want to manage the stream manually
DeepgramLiveTranscriber transcriber = deepgram.createLiveTranscriber(micStream);

transcriber.start();
transcriber.jsonStream.listen((json) {
    print(json);
});
transcriber.close(); // you can call start() after close() to restart the transcription
```

## Raw data
```dart
String json = await deepgram.transcribeFromBytes(List.from([1, 2, 3, 4, 5]));
```

For more detailed usage check `/example`



## Additional information

I created this package for my own needs since there are no dart sdk for deepgram. Happy to share !

Don't hesitate to ask for new features or to contribute !
