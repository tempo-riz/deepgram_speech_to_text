import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_file/universal_file.dart';

/// mimic a file other than in assets
Future<void> copyAssetToFile(String assetPath, String filename) async {
  ByteData data = await rootBundle.load(assetPath);
  List<int> bytes = data.buffer.asUint8List();
  final path = await getLocalFilePath(filename);
  await File(path).writeAsBytes(bytes);
  // print('$assetPath/$filename copied to $path');
}

Future<String> getLocalFilePath(String filename) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;
  return '$appDocPath/$filename';
}

Future<String> saveDataToFile(String filename, Uint8List data) async {
  final path = await getLocalFilePath(filename);
  await File(path).writeAsBytes(data);
  return path;
}

/// simulating a live text stream
StreamController<String> getTextStreamController({int duration = 6}) {
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

  Future.delayed(Duration(seconds: duration), () {
    controller.close();
  });

  return controller;
}
