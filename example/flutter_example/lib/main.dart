import 'dart:io';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/utils.dart';
import 'package:record/record.dart';
import 'package:universal_file/universal_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const fileName = 'jfk.wav';
const fileAssetPath = 'assets/$fileName';
const url = 'https://www2.cs.uic.edu/~i101/SoundFiles/taunt.wav';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await copyAssetToFile(fileAssetPath, fileName);
  runApp(MainApp());
}

// reference : https://developers.deepgram.com/reference/listen-file
Map<String, dynamic> params = {
  'model': 'nova-2-general',
  'language': 'fr',
  'filler_words': false,
  'punctuation': true,
};

// make sure to add your API key in the .env file (which is added in the .gitignore and pubspect.yaml's assets)
final apiKey = dotenv.get("DEEPGRAM_API_KEY");
Deepgram deepgram = Deepgram(apiKey, baseQueryParams: params);

void fromFile() async {
  final path = await getLocalFilePath('jfk.wav');
  final file = File(path);

  final json = await deepgram.transcribeFromFile(file);
  print(json);
}

void fromUrl() async {
  final json = await deepgram.transcribeFromUrl(url);
  print(json);
}

void fromBytes() async {
  final data = await rootBundle.load(fileAssetPath);
  final bytes = data.buffer.asUint8List();
  final json = await deepgram.transcribeFromBytes(bytes);
  print(json);
}

void fromStream() async {
  final audioStream = await AudioRecorder().startStream(RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  ));
  final jsonStream = deepgram.transcribeFromLiveAudioStream(audioStream);
  jsonStream.listen((json) {
    print(json);
  });
}

void fromTranscriber() async {
  final audioStream = await AudioRecorder().startStream(RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  ));
  final transcriber = deepgram.createLiveTranscriber(audioStream);

  transcriber.start();

  transcriber.jsonStream.listen((json) {
    print(json);
  });
  transcriber.close();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: fromFile, child: Text('TranscribeFromFile')),
              ElevatedButton(onPressed: fromUrl, child: Text('TranscribeFromUrl')),
              ElevatedButton(onPressed: fromBytes, child: Text('TranscribeFromBytes')),
              ElevatedButton(onPressed: fromStream, child: Text('TranscribeFromLiveAudioStream')),
              ElevatedButton(onPressed: fromTranscriber, child: Text('CreateLiveTranscriber')),
            ],
          ),
        ),
      ),
    );
  }
}
