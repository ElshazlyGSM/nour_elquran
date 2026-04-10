import 'dart:convert';
import 'dart:io';

const _defaultEdition = 'quran-uthmani';
const _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

Future<void> main(List<String> args) async {
  final surahNumbers = args.isEmpty
      ? <int>[1, 2]
      : args.map(int.parse).toList(growable: false);

  final file = File('assets/quran/data.json');
  final root = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final surahs = (root['surahs'] as List<dynamic>).cast<Map<String, dynamic>>();

  final client = HttpClient();
  try {
    for (final surahNumber in surahNumbers) {
      final response = await _fetchSurah(client, surahNumber);
      final target = surahs.firstWhere(
        (surah) => surah['id'] == surahNumber,
        orElse: () => throw StateError('Surah $surahNumber not found in data.json'),
      );
      _applySurahData(target, response);
      stdout.writeln('Filled surah $surahNumber');
    }
  } finally {
    client.close(force: true);
  }

  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(root)}\n');
  stdout.writeln('Updated ${file.path}');
}

Future<Map<String, dynamic>> _fetchSurah(HttpClient client, int surahNumber) async {
  final request = await client.getUrl(
    Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/$_defaultEdition'),
  );
  final response = await request.close();
  if (response.statusCode != 200) {
    throw HttpException(
      'Failed to fetch surah $surahNumber: HTTP ${response.statusCode}',
    );
  }

  final body = await response.transform(utf8.decoder).join();
  final payload = jsonDecode(body) as Map<String, dynamic>;
  final data = payload['data'];
  if (data is! Map<String, dynamic>) {
    throw StateError('Unexpected response for surah $surahNumber');
  }
  return data;
}

void _applySurahData(
  Map<String, dynamic> targetSurah,
  Map<String, dynamic> sourceSurah,
) {
  targetSurah['nameArabic'] = sourceSurah['name'];
  targetSurah['nameEnglish'] = sourceSurah['englishName'];
  targetSurah['revelationPlaceEnglish'] = sourceSurah['revelationType'];
  targetSurah['revelationPlaceArabic'] =
      sourceSurah['revelationType'] == 'Medinan' ? 'مدنية' : 'مكية';
  targetSurah['ayahCount'] = sourceSurah['numberOfAyahs'];

  final sourceAyahs = (sourceSurah['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();
  final targetAyahs = (targetSurah['verses'] as List<dynamic>).cast<Map<String, dynamic>>();

  if (sourceAyahs.length != targetAyahs.length) {
    throw StateError(
      'Ayah count mismatch for surah ${targetSurah['id']}: source=${sourceAyahs.length}, target=${targetAyahs.length}',
    );
  }

  final pages = <int>{};
  for (var i = 0; i < sourceAyahs.length; i++) {
    final sourceAyah = sourceAyahs[i];
    final targetAyah = targetAyahs[i];
    final surahNumber = targetSurah['id'] as int;
    final ayahNumber = targetAyah['ayah'] as int;

    var text = _normalizeText(sourceAyah['text'] as String);
    if (surahNumber != 1 && surahNumber != 9 && ayahNumber == 1) {
      text = _removeLeadingBasmala(text);
    }

    targetAyah['text'] = text;
    targetAyah['page'] = sourceAyah['page'];
    targetAyah['juz'] = sourceAyah['juz'];
    targetAyah['hizbQuarter'] = sourceAyah['hizbQuarter'];
    targetAyah['sajda'] = sourceAyah['sajda'] is bool
        ? sourceAyah['sajda']
        : (sourceAyah['sajda'] != false && sourceAyah['sajda'] != null);

    pages.add(sourceAyah['page'] as int);
  }

  final sortedPages = pages.toList()..sort();
  targetSurah['pages'] = sortedPages;
}

String _normalizeText(String text) {
  return text
      .replaceAll('\uFEFF', '')
      .replaceAll('\u00A0', ' ')
      .replaceAll('\n', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _removeLeadingBasmala(String text) {
  if (text.startsWith(_basmala)) {
    return text.substring(_basmala.length).trim();
  }
  return text;
}
