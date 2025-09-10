import 'dart:async';
import 'dart:typed_data';

import 'package:deepgram_speech_to_text/src/listen/deepgram_listen.dart';
import 'package:deepgram_speech_to_text/src/speak/deepgram_speak.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:wav/wav.dart';

export 'src/listen/deepgram_listen.dart';
export 'src/speak/deepgram_speak.dart';
export 'src/listen/deepgram_live_listener.dart';
export 'src/speak/deepgram_live_speaker.dart';

/// The Deepgram API client.
class Deepgram {
  Deepgram(
    this.apiKey, {
    this.baseUrl = 'https://api.deepgram.com/v1',
    this.isJwt = false,
  }) {
    _listen = DeepgramListen(this);
    _speak = DeepgramSpeak(this);
  }

  /// your Deepgram API key
  final String apiKey;

  late final DeepgramListen _listen;
  late final DeepgramSpeak _speak;

  /// The base URL for the Deepgram API.
  ///
  /// You can change it to use a proxy or self-hosted instance for example.
  final String baseUrl;

  /// Whether or not the apiKey is a short-lived JWT
  ///
  /// https://developers.deepgram.com/reference/token-based-auth-api/grant-token
  final bool isJwt;

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
        '$baseUrl/listen',
        {
          'language': 'fr',
        },
      ),
      headers: {
        Headers.authorization: authHeader,
        Headers.contentType: 'audio/*',
      },
      body: getSampleAudioData(),
    );
    // give additional info if not valid
    if (res.statusCode != 200) print('${res.statusCode} ${res.body}');
    return res.statusCode == 200;
  }

  /// convert to WAV format (add the WAV header)
  static Uint8List toWav(List<int> audioData, {int sampleRate = 16000}) {
    // Convert the byte data to normalized audio samples (-1.0 to 1.0 range)
    final samples =
        Float64List(audioData.length ~/ 2); // 16-bit PCM => 2 bytes per sample
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
