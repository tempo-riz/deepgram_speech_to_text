import 'dart:convert';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/src/utils.dart';

/// Represents the result of a STT request.
class DeepgramListenResult {
  DeepgramListenResult(this.json, {this.error}) : map = jsonDecode(json);

  /// The JSON string returned by the Deepgram API.
  final String json;

  /// The JSON string parsed into a map.
  final Map<String, dynamic> map;

  /// The transcription from the JSON string. (maybe empty, check for type)
  // sync : ['results']['channels'][0]['alternatives'][0]['transcript']
  // stream : ['channel']['alternatives'][0]['transcript']
  String? get transcript {
    try {
      return toUt8(map.containsKey('results')
          ? map['results']['channels'][0]['alternatives'][0]['transcript']
          : map['channel']['alternatives'][0]['transcript']);
    } catch (e) {
      return null;
    }
  }

  /// known types: 'Results', 'UtteranceEnd', 'Metadata', 'SpeechStarted', 'Finalize' ...
  String? get type {
    try {
      return map['type'];
    } catch (e) {
      return null;
    }
  }

  /// Error maybe returned by the Deepgram API.
  final dynamic error;

  @override
  String toString() {
    return 'DeepgramSttResult -> type: $type, transcript: "$transcript"${error != null ? ',\n error: $error' : ''} \n\n consider using .json .map or .transcript !';
  }
}

/// Represents the result of a TTS request.
class DeepgramSpeakResult {
  /// The audio data.
  final Uint8List? data;

  /// The headers or metadata if streaming
  final Map<String, dynamic>? metadata;

  /// The content type of the audio data. (e.g. 'audio/wav')
  String? get contentType => metadata?['content-type'];

  /// Error maybe returned by the Deepgram API.
  final dynamic error;

  DeepgramSpeakResult({
    this.data,
    this.metadata,
    this.error,
  });

  @override
  String toString() {
    return 'DeepgramTtsResult -> metadata: $metadata, data: ${data?.length ?? 0} bytes${error != null ? ',\n error: $error' : ''}';
  }
}
