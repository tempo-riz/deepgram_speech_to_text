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

# Deepgram Dart

![Pub Version](https://img.shields.io/pub/v/deepgram_speech_to_text)
![Pub Likes](https://img.shields.io/pub/likes/deepgram_speech_to_text)
![Pub Monthly Downloads](https://img.shields.io/pub/dm/deepgram_speech_to_text)


[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M71BK1YJ)

A Deepgram client for Dart and Flutter, supporting all Speech-to-Text and Text-to-Speech features on every platform.



Feel free to create issues, contribute to this project or to ask for new features on [GitHub](https://github.com/tempo-riz/deepgram_speech_to_text) !

## Features

| **Speech-to-Text**           | **Status** | **Methods**                              |
|------------------------------|------------|------------------------------------------|
| From File                    | ✅         | `listen.file()`, `listen.path()`         |
| From URL                     | ✅         | `listen.url()`                           |
| From Byte                    | ✅         | `listen.bytes()`                         |
| From Audio Stream            | ✅         | `listen.live()`, `listen.liveListener()` |


| **Text-to-Speech**           | **Status** | **Methods**                              |
|------------------------------|------------|------------------------------------------|
| From Text                    | ✅         | `speak.text()`                           |
| From Text Stream             | ✅         | `speak.live()`, `speak.liveSpeaker()`    |


| **Agent Interaction**        | **Status** | **Methods**                              |
|------------------------------|------------|------------------------------------------|
| Agent Interaction            | 🚧         | `agent.live()`                           |

_PRs are welcome for all work-in-progress 🚧 features_


## Getting started

All you need is a Deepgram API key. You can get a free one by signing up on [Deepgram](https://www.deepgram.com/)

## Usage

First create the client with your api key.
```dart
Deepgram deepgram = Deepgram('your_api_key');
```

## Pre-recorded
Then you can call the methods you need under the propper listen or speak subclass:

```dart
// Speech to text
DeepgramListenResult res = await deepgram.listen.file(File('audio.wav'), queryParams: {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuate': true,
  // options here : https://developers.deepgram.com/reference/listen-file
});

// Text to speech
DeepgramSpeakResult res = await deepgram.speak.text('Hello world', queryParams: {
  'model': 'aura-asteria-en'
  // options here : https://developers.deepgram.com/reference/text-to-speech-api
});
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

final sttStreamParams = {
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
Stream<DeepgramListenResult> stream = deepgram.listen.live(micStream, queryParams: sttStreamParams);

// 2. you want to manage the stream manually
DeepgramLiveListener listener = deepgram.liveListener(micStream, queryParams: sttStreamParams);
listener.stream.listen((res) {
    print(res.transcript);
});
// connect to the servers and start sending data
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
final ttsStreamParams = {
  'model': 'aura-asteria-en',
  'encoding': "linear16",
  'sample_rate': 16000,
// options here: https://developers.deepgram.com/reference/text-to-speech-api
};
```

then again you got 2 options:
```dart
final textStream = ...
// 1. you want the stream to manage itself automatically
Stream<DeepgramSpeakResult> stream = deepgram.speak.live(textStream, queryParams: ttsStreamParams);

// 2. you want to manage the stream manually
DeepgramLiveSpeaker speaker = deepgram.liveListener(textStream, queryParams: ttsStreamParams);
speaker.stream.listen((res) {
    print(res);
    // if you want to use the audio, simplest way is to use Deepgram.toWav(res.data) !
});

// start sending data to the servers
speaker.start();

// https://developers.deepgram.com/docs/tts-ws-flush 
speaker.flush();

//https://developers.deepgram.com/docs/tts-ws-clear
speaker.clear();

// then close the stream when you're done, you can call start() again if you want to restart a transcription 
speaker.close(); 
```


For more detailed usage check the `/example` tab

- Flutter demo [here](https://github.com/tempo-riz/deepgram_speech_to_text/tree/main/example/flutter_demo)

- Dart demo [here](https://github.com/tempo-riz/deepgram_speech_to_text/tree/main/example/dart_demo)

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
