import 'dart:async';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/deepgram.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:convert';
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
      expect(url.toString(), 'https://api.deepgram.com/v1/listen?model=nova-2-meeting&version=latest&filler_words=false&punctuation=true');
    });
  });

  group('[API]', () {
    final env = DotEnv()..load();

    final apiKey = env.getOrElse("DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
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

    test('transcribeFromBytes', () async {
      final file = File('assets/jfk.wav');

      expect(file.existsSync(), isTrue);

      final Uint8List bytes = file.readAsBytesSync();

      expect(bytes.length, greaterThan(0));

      final json = await deepgram.transcribeFromBytes(bytes);

      // Parse the JSON response
      Map<String, dynamic> map = jsonDecode(json);

      // Extract the transcript
      String transcript = map['results']['channels'][0]['alternatives'][0]['transcript'];
      expect(transcript, isNotEmpty);
    });

    test('transcribeFromFile', () async {
      final file = File('assets/jfk.wav');

      expect(file.existsSync(), isTrue);

      final json = await deepgram.transcribeFromFile(file);

      // Parse the JSON response
      Map<String, dynamic> map = jsonDecode(json);

      String transcript = map['results']['channels'][0]['alternatives'][0]['transcript'];
      expect(transcript, isNotEmpty);
    });

    test('transcribeFromUrl', () async {
      final url =
          'https://storage.googleapis.com/kagglesdsdata/datasets/829978/1417968/harvard.wav?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=databundle-worker-v2%40kaggle-161607.iam.gserviceaccount.com%2F20240312%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20240312T102452Z&X-Goog-Expires=345600&X-Goog-SignedHeaders=host&X-Goog-Signature=b027184c7afa530111fc595278fb3374d8bb4e3a116f26696729d1a0752e5c676db5839702a98af2e4b08c33ee0fca7ce4cecccf8f84d31a210de87d8982ecc90e57f20427adbcecf9b3c6253489b6146f17a094335b413e0e8c4f65e5dbc53441f35013c937722bff062ba8ddc72fc12d613b99f62fd81f2c69d1f3ab7fe070d90da113d653f12b6692a0211ca7ff174bb69eac864674d2fe36082f0cf06b2fb59a1ae26ad9177dc46e5f6cfd3c726d6f0f7332f1f64d094eceadd04a8ebf3bf1d78eeaa2f88e067a1288d29f9816897b1544d0f9cdaabd6bd81e0cab428f3546821fa7e9630b81f9d36e9e57f6ec7032ae33fd3d9ac3cc86c6917d8b65e479';

      final json = await deepgram.transcribeFromUrl(url);

      // Parse the JSON response
      Map<String, dynamic> map = jsonDecode(json);

      String transcript = map['results']['channels'][0]['alternatives'][0]['transcript'];
      expect(transcript, isNotEmpty);
    });

    test('createLiveTranscriber', () async {
      final controller = getAudioStreamController();
      print("creating transcriber");
      final DeepgramLiveTranscriber transcriber = deepgram.createLiveTranscriber(controller.stream);

      String transcript = '';

      transcriber.jsonStream.listen((json) {
        try {
          Map<String, dynamic> map = jsonDecode(json);
          String currentTranscript = map['channel']['alternatives'][0]['transcript'];
          print('Transcript: $currentTranscript');
          transcript += "$currentTranscript ";
        } catch (e) {
          print(e);
        }
      });

      print("starting");
      await transcriber.start();

      //close the stream after 8 seconds
      await Future.delayed(Duration(seconds: 6), () {
        print("stopping");
        // controller.close();
        transcriber.close();
      });

      print(transcript);
      expect(transcript, isNotEmpty);
    });

    test('transcribeFromLiveAudioStream', () async {
      final controller = getAudioStreamController();
      print("creating transcriber");

      final Stream<String> jsonStream = deepgram.transcribeFromLiveAudioStream(controller.stream);

      String transcript = '';

      jsonStream.listen((json) {
        try {
          Map<String, dynamic> map = jsonDecode(json);
          String currentTranscript = map['channel']['alternatives'][0]['transcript'];
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
