import 'local_json_quran_source.dart';
import 'quran_text_source.dart';

const QuranTextSource currentQuranTextSource = LocalJsonQuranSource();

final int currentQuranTotalJuzCount = 30;
final int currentQuranTotalSurahCount = 114;
final int currentQuranTotalPagesCount = 604;

Future<void> ensureCurrentQuranTextSourceInitialized() async {
  if (currentQuranTextSource is LocalJsonQuranSource) {
    await LocalJsonQuranSource.ensureInitialized();
  }
}
