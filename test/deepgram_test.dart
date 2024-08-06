import 'dart:async';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

void main() {
  group('[Utils]', () {
    test('mergeMaps', () {
      final map1 = {'key1': 'value1', 'key2': 'value2'};
      final map2 = {'key2': 'value3', 'key3': 'value4'};

      final mergedMap = mergeMaps(map1, map2);

      expect(mergedMap, {'key1': 'value1', 'key2': 'value3', 'key3': 'value4'});
    });
    test('buildUrl', () {
      final url = buildUrl('https://api.deepgram.com/v1/listen', {
        'model': 'nova-2-general',
        'version': 'latest'
      }, {
        'model': 'nova-2-meeting', //override the model
        'filler_words': false,
        'punctuation': true,
      });
      expect(url.toString(),
          'https://api.deepgram.com/v1/listen?model=nova-2-meeting&version=latest&filler_words=false&punctuation=true');
    });
  });

  group('[API]', () {
    final env = DotEnv()..load();

    final apiKey = env.getOrElse(
        "DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
    final deepgram = Deepgram(apiKey);

    /// [simulating a live stream]
    /// read the file content once then create a stream with a loop of its content
    StreamController<List<int>> getAudioStreamController() {
      final file = File('assets/jfk.wav');
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

    test('isApiKeyValid', () async {
      final isValid = await deepgram.isApiKeyValid();
      print('API key is valid: $isValid');
      expect(isValid, isTrue);
    });

    test('transcribeFromBytes', () async {
      final file = File('assets/jfk.wav');

      expect(file.existsSync(), isTrue);

      final Uint8List bytes = file.readAsBytesSync();

      expect(bytes.length, greaterThan(0));

      final res = await deepgram.transcribeFromBytes(bytes);

      print(res.transcript);

      expect(res.transcript, isNotEmpty);
    });

    test('transcribeFromFile', () async {
      final file = File('assets/jfk.wav');

      expect(file.existsSync(), isTrue);

      final res = await deepgram.transcribeFromFile(file);

      print(res.transcript);

      expect(res.transcript, isNotEmpty);
    });

    test('transcribeFromUrl', () async {
      final url = 'https://www2.cs.uic.edu/~i101/SoundFiles/taunt.wav';

      final res = await deepgram.transcribeFromUrl(url);

      print(res.transcript);

      expect(res.transcript, isNotEmpty);
    });

    test('createLiveTranscriber', () async {
      final controller = getAudioStreamController();
      print("creating transcriber");
      final DeepgramLiveTranscriber transcriber =
          deepgram.createLiveTranscriber(controller.stream);

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

      final Stream<DeepgramSttResult> stream =
          deepgram.transcribeFromLiveAudioStream(controller.stream);

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

    test('speakFromText', () async {
      final res = await deepgram
          .speakFromText("hello, how are you today ?", queryParams: {
        'model': 'aura-asteria-en',
      });
      print(res.contentType);
      expect(res.data, isNotEmpty);
    });
  });
}
