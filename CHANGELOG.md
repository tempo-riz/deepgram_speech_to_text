## 4.0.1
- avoid JSON parsing multiple times in DeepgramListenResult

## 4.0.0
- **Breaking change**: Remove baseParams from `DeepgramClient` since it creates confusion.
- Support using short-lived JWT tokens instead of API KEY (thanks @danielmahon)

## 3.1.0
- allow custom `baseUrl` for Deepgram Client

## 3.0.4
- fix utf8 encoding

## 3.0.3
- removed unnecessary exports

## 3.0.2
- Updated docs

## 3.0.1
- Updated docs
- added missing exports

## 3.0.0
**Breaking changes**

Now you can find all method under deepgram.listen and deepgram.speak
- `deepgram.transcribeFromFile()` -> `deepgram.listen.file()`
- `deepgram.speakFromText()` -> `deepgram.speak.text()`
  
- Added support for  `deepgram.speak.live()` - `deepgram.toWav()` makes the audio data readable 
- Updated examples (flutter and dart)
- Added mandatory default query params to every streaming method (encoding, sampleRate)

## 2.3.2
- Stop keepalive timer on close (thanks @PcolBP)
  
## 2.3.1
- Updated docs

## 2.3.0
- Added pause() and resume() methods for streaming
- Add missing streaming features (thanks @DamienDeepgram)
- Fixed: Memory leak + infinity future (thanks @PcolBP)
- DeepgramSttResult now has .type getter, .transcript is safer and nullable

## 2.2.2
- Fixed utf8 parsing issue

## 2.2.1
- Update web_socket_channel dependency

## 2.2.0
- Added `transcribeFromPath()` for convenience.
- Fixed package on web.
- Updated example to work on web.

## 2.1.0
- Support for TTS (text to speech) 

## 2.0.1
- Better documentation and debug hints

## 2.0.0
- STT methods now return a `DeepgramSttResult` instead of plain json string (breaking change)
- Updated example in README.md and /example, added a flutter demo
- Better documentation

## 1.0.5
- Better doc

## 1.0.4
- Added WEB support (for real this time)

## 1.0.3
- Tried to add WEB support

## 1.0.2
- Fixed incorrect documentation

## 1.0.1
- Formatted for pub.dev

## 1.0.0
- Initial version.
