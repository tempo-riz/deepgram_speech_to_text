import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/utils.dart';
import 'package:record/record.dart';
import 'package:universal_file/universal_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const fileName = 'fr.mp3';
const fileAssetPath = 'assets/$fileName';
const url = 'https://www2.cs.uic.edu/~i101/SoundFiles/taunt.wav';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await copyAssetToFile(fileAssetPath, fileName);
  runApp(MainApp());
}

// reference : https://developers.deepgram.com/reference/listen-file
Map<String, dynamic> baseParams = {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuation': true,
};

// make sure to add your API key in the .env file (which is added in the .gitignore and pubspect.yaml's assets)
final apiKey = dotenv.get("DEEPGRAM_API_KEY");
Deepgram deepgram = Deepgram(apiKey, baseQueryParams: baseParams);

void checkApiKey() async {
  print('Checking API key...');
  final isValid = await deepgram.isApiKeyValid();

  print('API key is valid: $isValid');
}

void fromFile() async {
  print('Transcribing from file...');
  final path = await getLocalFilePath('jfk.wav');
  final file = File(path);

  final res = await deepgram.transcribeFromFile(file);
  print(res.transcript);
}

void fromUrl() async {
  print('Transcribing from url...');
  final res = await deepgram.transcribeFromUrl(url);
  print(res.transcript);
}

void fromBytes() async {
  print('Transcribing from bytes...');
  final data = await rootBundle.load(fileAssetPath);
  final bytes = data.buffer.asUint8List();
  final res = await deepgram.transcribeFromBytes(bytes);
  print(res.transcript);
}

final mic = AudioRecorder();
void startStream() async {
  await mic.hasPermission();

  final audioStream = await mic.startStream(RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  ));

  print('Recording started...');

  final liveParams = {
    'detect_language': false, // not supported by streaming API
    'language': 'en',
    // must specify encoding and sample_rate according to the audio stream
    'encoding': 'linear16',
    'sample_rate': 16000,
  };

  final stream = deepgram.transcribeFromLiveAudioStream(audioStream,
      queryParams: liveParams);

  stream.listen((res) {
    print(res.transcript);
  });

  // alternativly you can use the DeepgramLiveTranscriber class :
  /*
  final transcriber = deepgram.createLiveTranscriber(audioStream, queryParams: params);

  transcriber.start();

  transcriber.stream.listen((res) {
    print(res.transcript);
  });
  transcriber.close();
  */
}

void stopStream() async {
  print('Recording stopped');
  await mic.stop();
}

void speakFromText() async {
  Deepgram deepgramTTS = Deepgram(apiKey, baseQueryParams: {
    'model': 'aura-asteria-en',
    'encoding': "linear16",
    'container': "wav",
  });
  final res = await deepgramTTS.speakFromText(
    "hello, how are you today ?",
  );
  int random = DateTime.now().millisecondsSinceEpoch;
  final path = await saveDataToFile("$random.wav", res.data);
  final player = AudioPlayer();
  await player.play(DeviceFileSource(path));
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Deepgram Example',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: checkApiKey, child: Text('Check Api Key')),
                Divider(),
                ElevatedButton(onPressed: fromFile, child: Text('From File')),
                ElevatedButton(onPressed: fromUrl, child: Text('From Url')),
                ElevatedButton(onPressed: fromBytes, child: Text('From Bytes')),
                Divider(),
                ElevatedButton(
                    onPressed: startStream, child: Text('Start Stream')),
                ElevatedButton(
                    onPressed: stopStream, child: Text('Stop Stream')),
                Divider(),
                ElevatedButton(
                    onPressed: speakFromText, child: Text('Speak From Text')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
