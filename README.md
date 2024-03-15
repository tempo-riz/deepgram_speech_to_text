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

A simple Deepgram client for Dart and Flutter.  

You can simply transcribe audio from : File, URL, Stream or Raw data.

Currently only supports Speech-To-Text (STT), maybe more in the future. 
Feel free to contribute to this project or to ask for new features on [GitHub](https://github.com/tempo-riz/deepgram_speech_to_text) !


## Features

Speech to text transcription from:
- File
- URL
- Stream
- Raw data

## Getting started

All you need is a Deepgram API key. You can get a free one by signing up on [Deepgram](https://www.deepgram.com/)

## Usage
For a bit more detailed usage check `/example`

```dart
String apiKey = 'your_api_key';
Deepgram deepgram = Deepgram(apiKey, baseQueryParams: params);

// -------------------- From a file --------------------
File audioFile = File('audio.wav');
String json1 = await deepgram.transcribeFromFile(audioFile);

// -------------------- From a URL --------------------
String json2 = await deepgram.transcribeFromUrl('https://somewhere/audio.wav');

// -------------------- From raw data --------------------
String json3 = await deepgram.transcribeFromBytes(List.from([1, 2, 3, 4, 5]));

// -------------------- From a stream  --------------------
Stream<String> jsonStream = deepgram.transcribeFromLiveAudioStream(mic.stream);

// or to have more control over the stream
DeepgramLiveTranscriber transcriber = deepgram.createLiveTranscriber(mic.stream);

transcriber.start();
transcriber.jsonStream.listen(print);
transcriber.close();
```


## Additional information

I created this package for my own needs since there are no dart sdk for deepgram. Happy to share !

Don't hesitate to ask for new features or to contribute !
