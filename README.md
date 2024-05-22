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

A Deepgram client for Dart and Flutter, supporting all Speech-to-Text and Text-to-Speech features on every platform.

You need something else ? Just ask !

Feel free to create issues, contribute to this project or to ask for new features on [GitHub](https://github.com/tempo-riz/deepgram_speech_to_text) !


## Features

Speech to text (STT) transcription from:
- File
- URL
- Raw data
- Stream

  
Text to speech (TTS) is also supported
- Text to raw audio data

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

## Raw data
```dart
final res = await deepgram.transcribeFromBytes(List.from([1, 2, 3, 4, 5]));
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

## Text to speech

```dart
Deepgram deepgram = Deepgram(apiKey, baseQueryParams: {
  'model': 'aura-asteria-en',
  'encoding': "linear16",
  'container': "wav",
  // options here: https://developers.deepgram.com/reference/text-to-speech-api

  final res = await deepgram.speakFromText('Hello world');
  print(res.data); // raw audio data that you can use as you wish. Check flutter example for a simple player
});

```

For more detailed usage check the `/example` tab

There is a full flutter demo [here](https://github.com/tempo-riz/deepgram_speech_to_text/tree/main/example/flutter_example)

Tested on Android and iOS, but should work on other platforms too.

## Debugging common errors
- make sure your API key is valid and has enough credits

```dart
deepgram.isApiKeyValid()
```


- "Websocket was not promoted ..." : you are probably using wrong parameters, for example trying to use a whisper model with live streaming (not supported by deepgram)
- empty transcript/only metadata : if streaming check that you specified encoding and sample_rate properly and that it matches the audio stream
- double check the parameters you are using, some are not supported for streaming or for some models


## Additional information

I created this package for my own needs since there are no dart sdk for deepgram. Happy to share !

Don't hesitate to ask for new features or to contribute !

## Support

If you want to help me continue support of this project consider contributing here https://github.com/sponsors/tempo-riz :)
If you'd like to support this project, consider contributing [here](https://github.com/sponsors/tempo-riz). Thank you! :)
