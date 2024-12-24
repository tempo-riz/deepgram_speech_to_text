import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:deepgram_speech_to_text/src/utils.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';

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

  group('[API CLIENT]', () {
    final env = DotEnv()..load();

    final apiKey = env.getOrElse("DEEPGRAM_API_KEY", () => throw Exception("No API Key found"));
    final deepgram = Deepgram(apiKey);

    test('isApiKeyValid', () async {
      final isValid = await deepgram.isApiKeyValid();
      print('API key is valid: $isValid');
      expect(isValid, isTrue);
    });
  });
}
