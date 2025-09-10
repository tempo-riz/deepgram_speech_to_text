import 'dart:typed_data';

/// Represents the result of a TTS request.
class DeepgramSpeakResult {
  /// The audio data.
  final Uint8List? data;

  /// The headers or metadata if streaming
  final Map<String, dynamic>? metadata;

  /// The content type of the audio data. (e.g. 'audio/wav')
  String? get contentType => metadata?['content-type'];

  DeepgramSpeakResult({
    this.data,
    this.metadata,
  });

  @override
  String toString() =>
      '$runtimeType -> metadata: $metadata, data length: ${data?.length}';
}
