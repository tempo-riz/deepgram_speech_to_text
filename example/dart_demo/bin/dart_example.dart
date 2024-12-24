import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load();

  final apiKey = env.getOrElse("DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
  final deepgram = Deepgram(apiKey);

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

  final liveSpeaker = deepgram.speak.live(controller.stream);

  Future.delayed(Duration(seconds: 4), () {
    controller.close();
  });

  final audioData = BytesBuilder(); // Collect raw audio data

  liveSpeaker.listen(
    (res) {
      print(res);
      if (res.data != null) {
        // todo without this
        audioData.add(res.data!);
      }
    },
    onDone: () {
      saveWavFile(audioData.toBytes());
    },
  );
}

// Save WAV file with header
Future<void> saveWavFile(List<int> audioData) async {
  final wavData = Deepgram.toWav(audioData);
  final file = File('./output_audio.wav');
  await file.writeAsBytes(wavData);
}
