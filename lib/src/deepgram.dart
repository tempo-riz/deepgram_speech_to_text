import 'dart:async';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/src/deepgram_listen.dart';
import 'package:deepgram_speech_to_text/src/deepgram_speak.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:wav/wav.dart';

export 'types.dart';

/// The Deepgram API client.
class Deepgram {
  Deepgram(
    this.apiKey, {
    this.baseQueryParams,
  }) {
    _listen = DeepgramListen(this);
    _speak = DeepgramSpeak(this);
  }

  /// your Deepgram API key
  final String apiKey;

  /// Deepgram parameters
  ///
  /// List of params here : https://developers.deepgram.com/reference/listen-file
  ///
  /// (if same params are present in both baseQueryParams and queryParams, the value from queryParams is used)
  final Map<String, dynamic>? baseQueryParams;

  late final DeepgramListen _listen;
  late final DeepgramSpeak _speak;

  /// Get the Text to Speech API
  DeepgramSpeak get speak => _speak;

  /// Get the Speech to Text API
  DeepgramListen get listen => _listen;

  /// Check if the API key is valid and if you still have credits
  ///
  /// (try to transcribe a 1 sec sample audio file)
  Future<bool> isApiKeyValid() async {
    http.Response res = await http.post(
      buildUrl(
          'https://api.deepgram.com/v1/listen',
          {
            'language': 'fr',
          },
          null),
      headers: {
        Headers.authorization: 'Token $apiKey',
        Headers.contentType: 'audio/*',
      },
      body: getSampleAudioData(),
    );

    return res.statusCode == 200;
  }

  /// convert to WAV format (add the WAV header)
  static Uint8List toWav(List<int> audioData, {int sampleRate = 16000}) {
    // Convert the byte data to normalized audio samples (-1.0 to 1.0 range)
    final samples = Float64List(audioData.length ~/ 2); // 16-bit PCM => 2 bytes per sample
    for (var i = 0; i < audioData.length; i += 2) {
      final sample = (audioData[i] | (audioData[i + 1] << 8)).toSigned(16);
      samples[i ~/ 2] = sample / 32768.0; // Normalize to [-1.0, 1.0]
    }

    // Create the WAV object
    final wav = Wav(
      [samples], // Single channel (mono) audio
      sampleRate,
      WavFormat.pcm16bit,
    );

    return wav.write(); // Write the WAV header
  }
}
