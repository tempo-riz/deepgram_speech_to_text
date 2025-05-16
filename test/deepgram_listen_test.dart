import 'dart:async';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';
import 'package:universal_file/universal_file.dart';

void main() {
  group('[LISTEN - STT API]', () {
    final env = DotEnv()..load();

    const file1 = 'assets/jfk.wav';
    // const file2 = 'assets/chinese.wav';

    const String audioFilePath = file1;

    final apiKey = env.getOrElse(
        "DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
    final deepgram = Deepgram(apiKey);

    /// [simulating a live stream]
    /// read the file content once then create a stream with a loop of its content
    StreamController<List<int>> getAudioStreamController() {
      final file = File(audioFilePath);
      assert(file.existsSync(), 'File does not exist');

      Uint8List bytes = file.readAsBytesSync();

      StreamController<List<int>> controller = StreamController<List<int>>();

      // Instead of piping the dummyAudioStream into the controller,
      // directly add data to the controller
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (!controller.isClosed) {
          controller.add(bytes);
        } else {
          timer.cancel(); // Stop timer if the controller is closed
        }
      });

      return controller;
    }

    test('transcribeFromBytes', () async {
      final file = File(audioFilePath);

      expect(file.existsSync(), isTrue);

      final Uint8List bytes = file.readAsBytesSync();

      expect(bytes.length, greaterThan(0));
      // final res = await deepgram.transcribeFromBytes(bytes);
      final res = await deepgram.listen.bytes(bytes);
      print(res.transcript);

      expect(res.transcript, isNotEmpty);
    });

    test('transcribeFromFile', () async {
      final file = File(audioFilePath);

      expect(file.existsSync(), isTrue);

      // final res = await deepgram.transcribeFromFile(file);
      final res = await deepgram.listen.file(file);

      print(res.transcript);

      expect(res.transcript, isNotEmpty);
    });

    test('transcribeFromUrl', () async {
      final url = 'https://www2.cs.uic.edu/~i101/SoundFiles/taunt.wav';

      // final res = await deepgram.transcribeFromUrl(url);
      final res = await deepgram.listen.url(url);

      print(res.transcript);

      expect(res.transcript, isNotEmpty);
    });

    test('createLiveTranscriber', () async {
      final controller = getAudioStreamController();
      print("creating transcriber");
      final DeepgramLiveListener transcriber =
          deepgram.listen.liveListener(controller.stream);

      String transcript = '';

      transcriber.stream.listen((res) {
        try {
          print(res.type);
          String currentTranscript = res.transcript ?? "";
          print('Transcript: $currentTranscript');
          transcript += "$currentTranscript ";
        } catch (e) {
          print(e);
        }
      });

      print("starting");
      await transcriber.start();

      await Future.delayed(Duration(seconds: 1));
      print("pausing (waiting 14 seconds)");
      transcriber.pause();

      await Future.delayed(
          Duration(seconds: 14)); // would normally close after 10 seconds
      print("resuming");
      transcriber.resume();

      await Future.delayed(Duration(seconds: 5));
      print("stopping");
      transcriber.close();

      print(transcript);
      expect(transcript, isNotEmpty);
    });

    test('transcribeFromLiveAudioStream', () async {
      final controller = getAudioStreamController();
      print("creating transcriber");

      final Stream<DeepgramListenResult> stream =
          deepgram.listen.live(controller.stream);

      String transcript = '';

      stream.listen((res) {
        try {
          String currentTranscript = res.transcript ?? "";
          print('Transcript: $currentTranscript');
          transcript += "$currentTranscript ";
        } catch (e) {
          print(e);
        }
      });

      //close the stream after 8 seconds
      await Future.delayed(Duration(seconds: 6), () {
        print("stopping");
        // controller.close();
        controller.close();
      });
      print(transcript);

      expect(transcript, isNotEmpty);
    });
  });
}
