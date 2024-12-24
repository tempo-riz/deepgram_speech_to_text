import 'dart:async';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

void main() {
  group('[SPEAK - TTS API]', () {
    final env = DotEnv()..load();

    final apiKey = env.getOrElse("DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
    final deepgram = Deepgram(apiKey);

    /// [simulating a live stream]
    /// read the file content once then create a stream with a loop of its content
    StreamController<String> getTextStreamController() {
      List<String> story = [
        "The sun had just begun to rise over the sleepy town of Millfield.",
        "Emily, a young woman in her mid-twenties, was already awake and bustling about.",
        "The streets were quiet, and the only sound was the gentle rustling of the leaves in the early morning breeze.",
        "She smiled as she stepped outside, ready to start her day with a cup of freshly brewed coffee.",
        "Little did she know, today would bring unexpected surprises that would change her life forever."
      ];

      int index = 0;

      StreamController<String> controller = StreamController<String>();

      // Instead of piping the dummyAudioStream into the controller,
      // directly add data to the controller
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (!controller.isClosed) {
          controller.add(story[index]);
          index = (index + 1) % story.length;
        } else {
          timer.cancel(); // Stop timer if the controller is closed
        }
      });

      return controller;
    }

    test('speakFromText', () async {
      final res = await deepgram.speak.text("hello, how are you today ?", queryParams: {
        'model': 'aura-asteria-en',
      });
      print(res.contentType);
      expect(res.data, isNotEmpty);
    });

    test('speakFromTextStream', () async {
      final textStream = getTextStreamController().stream;

      final res = deepgram.speak.liveSpeaker(textStream, queryParams: {
        'model': 'aura-asteria-en',
      });

      // TODO
    });
  });
}
