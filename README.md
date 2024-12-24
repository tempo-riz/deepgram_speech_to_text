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

You need something else ? Feel free to create issues, contribute to this project or to ask for new features on [GitHub](https://github.com/tempo-riz/deepgram_speech_to_text) !


## Features

| Feature                | Status        | Method(s)            |
|------------------------|---------------|----------------------|
| File Transcription      | ✅ Implemented | `listen.file()` or `listen.path()`     |
| URL Transcription       | ✅ Implemented | `listen.url()`       |
| Byte Transcription      | ✅ Implemented | `listen.bytes()`     |
| Streaming Transcription | ✅ Implemented | `listen.live()` or `listen.liveListener()`   |
| Text-to-Speech          | ✅ Implemented | `speak.text()`       |
| Live Text-to-Speech     | ✅ Implemented | `speak.live()` or `speak.liveSpeaker()`      |
| Agent Interaction       | 🚧 (PR appreciated) | `agent.live()` |



## Getting started

All you need is a Deepgram API key. You can get a free one by signing up on [Deepgram](https://www.deepgram.com/)

## Usage

First create the client with optional parameters
```dart
String apiKey = 'your_api_key';

// you can pass params here or in every method call depending on your needs
final params = {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuation': true,
  // more options here : https://developers.deepgram.com/reference/listen-file
};

Deepgram deepgram = Deepgram(apiKey, baseQueryParams: params);
```
Then you can call the methods you need :

```dart
// Speech to text
DeepgramListenResult res = await deepgram.listen.file(File('audio.wav'));

// Text to speech
DeepgramSpeakResult res = await deepgram.speak.text('Hello world');
```

## STT Result
All STT methods return a `DeepgramListenResult` object with the following properties : 
```dart
class DeepgramListenResult {
  final String json; // raw json response
  final Map<String, dynamic> map; // parsed json response into a map
  final String? transcript; // the transcript extracted from the response
  final String? type; // the response type (Result, Metadata, ...) non-null for streaming
}
```

## TTS Result
All TTS methods return a `DeepgramSpeakResult` object with the following properties : 
```dart
class DeepgramSpeakResult {
  final Uint8List? data; // raw audio data
  final Map<String, dynamic>? metadata; /// The headers or metadata if streaming
}
```


## Streaming
### Speech to text
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
Stream<DeepgramListenResult> stream = deepgram.listen.live(micStream);

// 2. you want to manage the stream manually
DeepgramLiveListener listener = deepgram.liveListener(micStream);
listener.stream.listen((res) {
    print(res.transcript);
});

listener.start();

// you can pause and resume the transcription (stop sending audio data to the server)
listener.pause(); 
// ...
listener.resume();

// then close the stream when you're done, you can call start() again if you want to restart a transcription 
listener.close(); 
```

### Text to speech
```dart
Deepgram deepgram = Deepgram(apiKey, baseQueryParams: {
  'model': 'aura-asteria-en',
  'encoding': "linear16",
  'sample_rate': 16000,
// options here: https://developers.deepgram.com/reference/text-to-speech-api
});
```

then again you got 2 options:
```dart
final textStream = ...
// 1. you want the stream to manage itself automatically
Stream<DeepgramSpeakResult> stream = deepgram.speak.live(textStream);

// 2. you want to manage the stream manually
DeepgramLiveSpeaker speaker = deepgram.liveListener(textStream);
speaker.stream.listen((res) {
    print(res);
    // if you want to use the audio, simplest way is to use Deepgram.toWav(res.data) !
});

speaker.start();
// https://developers.deepgram.com/docs/tts-ws-flush 
speaker.flush(); 
//https://developers.deepgram.com/docs/tts-ws-clear
speaker.clear();

// then close the stream when you're done, you can call start() again if you want to restart a transcription 
speaker.close(); 
```


For more detailed usage check the `/example` tab

There is a flutter demo [here](https://github.com/tempo-riz/deepgram_speech_to_text/tree/main/example/flutter_demo)

And a dart demo [here](https://github.com/tempo-riz/deepgram_speech_to_text/tree/main/example/dart_demo)

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

Don't hesitate to ask for new features or to contribute on [GitHub](https://github.com/tempo-riz/deepgram_speech_to_text) !

## Support

If you'd like to support this project, consider contributing [here](https://github.com/sponsors/tempo-riz). Thank you! :)
