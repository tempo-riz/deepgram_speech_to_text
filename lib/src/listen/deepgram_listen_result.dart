import 'dart:convert';

import 'package:deepgram_speech_to_text/src/utils.dart';

/// Defines the known result types.
enum ResultType {
  results,
  utteranceEnd,
  metadata,
  speechStarted,
  finalize,
  unknown,
}

/// Represents the result of a STT request.
class DeepgramListenResult {
  /// The JSON string returned by the Deepgram API.
  final String json;

  /// Cached parsed JSON map.
  Map<String, dynamic>? _map;

  DeepgramListenResult(this.json);

  /// Gets the JSON response as a parsed map.
  Map<String, dynamic> get map => _map ??= jsonDecode(json);

  /// Gets the first alternative from the map.
  Map<String, dynamic>? get _firstAlternative {
    if (map.containsKey('results')) {
      return map['results']?['channels']?[0]?['alternatives']?[0];
    }
    return map['channel']?['alternatives']?[0];
  }

  /// Gets the transcript from the map.
  String? get transcript {
    final trans = _firstAlternative?['transcript'] as String?;
    return trans != null ? toUtf8(trans) : null;
  }

  /// Gets the ID of the speaker who spoke the first word.
  int? get firstSpeaker {
    final words = _firstAlternative?['words'] as List<dynamic>?;
    if (words == null || words.isEmpty) return null;
    return words[0]['speaker'] as int?;
  }

  /// Gets the words in the transcription.
  List<DeepgramWord> get words {
    final wordsDynamic = _firstAlternative?['words'] as List<dynamic>?;
    if (wordsDynamic == null) return [];
    return wordsDynamic
        .map((e) => DeepgramWord(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets the duration of the result.
  double get duration => (map['duration'] as num?)?.toDouble() ?? 0.0;

  /// Gets the end time of the result.
  double get end => start + duration;

  /// Gets whether the result is a final interim result.
  bool get isFinal => map['is_final'] as bool? ?? false;

  /// Gets whether this instance contains results.
  bool get isResults => map['type']?.toLowerCase() == 'results';

  /// Gets whether the result is a final endpoint result.
  bool get speechFinal => map['speech_final'] as bool? ?? false;

  /// Gets the start time of the result.
  double get start => (map['start'] as num?)?.toDouble() ?? 0.0;

  /// Gets the type of the result. (streaming only, will be unknown for sync results)
  ResultType get type => switch ((map['type'] as String?)?.toLowerCase()) {
        'results' => ResultType.results,
        'utterance_end' => ResultType.utteranceEnd,
        'metadata' => ResultType.metadata,
        'speech_started' => ResultType.speechStarted,
        'finalize' => ResultType.finalize,
        _ => ResultType.unknown,
      };

  @override
  String toString() {
    return '$runtimeType -> transcript: "$transcript"';
  }
}

/// Represents a word in the transcription.
class DeepgramWord {
  /// Creates a new instance of the DeepgramWord class.
  ///
  /// [map] - The word map from the JSON response.
  DeepgramWord(this.map);

  /// Gets the word map from the JSON response.
  final Map<String, dynamic> map;

  /// Gets the word from the map.
  String get word => map['word'] as String? ?? '';

  /// Gets the start time of the word.
  double get start => map['start'] as double? ?? 0.0;

  /// Gets the end time of the word.
  double get end => map['end'] as double? ?? 0.0;

  /// Gets the confidence of the word.
  double get confidence => map['confidence'] as double? ?? 0.0;

  /// Gets the speaker tag of the word.
  int? get speaker => map['speaker'] as int?;

  /// Gets the confidence of the speaker.
  double? get speakerConfidence => map['speaker_confidence'] as double?;

  @override
  String toString() => '$runtimeType -> "$word" ($start-$end)';
}
