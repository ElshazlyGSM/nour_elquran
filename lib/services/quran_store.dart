import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/last_read_position.dart';
import '../models/reader_bookmark.dart';

class QuranStore extends ChangeNotifier {
  QuranStore._(this._prefs);

  static const _lastSurahKey = 'last_surah';
  static const _lastVerseKey = 'last_verse';
  static const _reciterIndexKey = 'reader_reciter_index';
  static const _reciterIdKey = 'reader_reciter_id';
  static const _tafsirIdKey = 'reader_tafsir_id';
  static const _repeatCountKey = 'reader_repeat_count';
  static const _fontSizeKey = 'reader_font_size';
  static const _readingSpeedKey = 'reader_speed';
  static const _appearanceKey = 'reader_appearance';
  static const _prayerCityKey = 'prayer_city_name';
  static const _prayerAutoDetectKey = 'prayer_auto_detect';
  static const _prayerHijriOffsetKey = 'prayer_hijri_offset';
  static const _prayerFajrOffsetKey = 'prayer_fajr_offset';
  static const _prayerSunriseOffsetKey = 'prayer_sunrise_offset';
  static const _prayerDhuhrOffsetKey = 'prayer_dhuhr_offset';
  static const _prayerAsrOffsetKey = 'prayer_asr_offset';
  static const _prayerMaghribOffsetKey = 'prayer_maghrib_offset';
  static const _prayerIshaOffsetKey = 'prayer_isha_offset';
  static const _prayerAdhanEnabledKey = 'prayer_adhan_enabled';
  static const _prayerReminderMinutesKey = 'prayer_reminder_minutes';
  static const _prayerFajrEnabledKey = 'prayer_fajr_enabled';
  static const _prayerSunriseEnabledKey = 'prayer_sunrise_enabled';
  static const _prayerDhuhrEnabledKey = 'prayer_dhuhr_enabled';
  static const _prayerAsrEnabledKey = 'prayer_asr_enabled';
  static const _prayerMaghribEnabledKey = 'prayer_maghrib_enabled';
  static const _prayerIshaEnabledKey = 'prayer_isha_enabled';
  static const _prayerFajrReminderKey = 'prayer_fajr_reminder';
  static const _prayerSunriseReminderKey = 'prayer_sunrise_reminder';
  static const _prayerDhuhrReminderKey = 'prayer_dhuhr_reminder';
  static const _prayerAsrReminderKey = 'prayer_asr_reminder';
  static const _prayerMaghribReminderKey = 'prayer_maghrib_reminder';
  static const _prayerIshaReminderKey = 'prayer_isha_reminder';
  static const _prayerAdhanProfileKey = 'prayer_adhan_profile';
  static const _tasbihPhraseKey = 'tasbih_phrase';
  static const _tasbihCustomPhrasesKey = 'tasbih_custom_phrases';
  static const _tasbihTargetKey = 'tasbih_target';
  static const _tasbihTapHapticsKey = 'tasbih_tap_haptics';
  static const _tasbihGoalHapticsKey = 'tasbih_goal_haptics';
  static const _salawatReminderEnabledKey = 'salawat_reminder_enabled';
  static const _salawatReminderIntervalKey = 'salawat_reminder_interval';
  static const _salawatPauseAtPrayerKey = 'salawat_pause_at_prayer';
  static const _salawatPrayerPauseMinutesKey = 'salawat_prayer_pause_minutes';
  static const _salawatWindowEnabledKey = 'salawat_window_enabled';
  static const _salawatWindowStartMinutesKey = 'salawat_window_start_minutes';
  static const _salawatWindowEndMinutesKey = 'salawat_window_end_minutes';
  static const _salawatVibrationEnabledKey = 'salawat_vibration_enabled';
  static const _salawatUnlockEnabledKey = 'salawat_unlock_enabled';
  static const _salawatUnlockLastKey = 'salawat_unlock_last';
  static const _salawatFormulaCountsKey = 'salawat_formula_counts_v1';
  static const _readerBookmarksKey = 'reader_bookmarks_v1';
  static const _readSirahEpisodesKey = 'read_sirah_episodes_v1';
  static const _lastSirahEpisodeIdKey = 'last_sirah_episode_id';
  static const _lastAppOpenDateKey = 'last_app_open_date';
  static const _darkModeEnabledKey = 'dark_mode_enabled';
  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;
  LastReadPosition? _lastRead;
  List<ReaderBookmark> _readerBookmarks = const [];

  LastReadPosition? get lastRead => _lastRead;
  List<ReaderBookmark> get readerBookmarks =>
      List.unmodifiable(_readerBookmarks);
  String? get savedReciterId => _prefs.getString(_reciterIdKey);
  int? get savedReciterIndex => _prefs.getInt(_reciterIndexKey);
  int? get savedTafsirId => _prefs.getInt(_tafsirIdKey);
  int get savedRepeatCount => _prefs.getInt(_repeatCountKey) ?? 1;
  double? get savedFontSize => _prefs.getDouble(_fontSizeKey);
  double? get savedReadingSpeed => _prefs.getDouble(_readingSpeedKey);
  String? get savedAppearance => _prefs.getString(_appearanceKey);
  String? get savedPrayerCityName => _prefs.getString(_prayerCityKey);
  bool get savedPrayerAutoDetect =>
      _prefs.getBool(_prayerAutoDetectKey) ?? true;
  int get savedPrayerHijriOffset => _prefs.getInt(_prayerHijriOffsetKey) ?? 0;
  Map<String, int> get savedPrayerOffsets => {
    'fajr': (_prefs.getInt(_prayerFajrOffsetKey) ?? 0).clamp(-30, 30),
    'sunrise': (_prefs.getInt(_prayerSunriseOffsetKey) ?? 0).clamp(-30, 30),
    'dhuhr': (_prefs.getInt(_prayerDhuhrOffsetKey) ?? 0).clamp(-30, 30),
    'asr': (_prefs.getInt(_prayerAsrOffsetKey) ?? 0).clamp(-30, 30),
    'maghrib': (_prefs.getInt(_prayerMaghribOffsetKey) ?? 0).clamp(-30, 30),
    'isha': (_prefs.getInt(_prayerIshaOffsetKey) ?? 0).clamp(-30, 30),
  };
  bool get savedPrayerAdhanEnabled =>
      _prefs.getBool(_prayerAdhanEnabledKey) ?? false;
  int get savedPrayerReminderMinutes =>
      _prefs.getInt(_prayerReminderMinutesKey) ?? 0;
  Map<String, bool> get savedPrayerEnabledMap => {
    'fajr': _prefs.getBool(_prayerFajrEnabledKey) ?? true,
    'sunrise': _prefs.getBool(_prayerSunriseEnabledKey) ?? true,
    'dhuhr': _prefs.getBool(_prayerDhuhrEnabledKey) ?? true,
    'asr': _prefs.getBool(_prayerAsrEnabledKey) ?? true,
    'maghrib': _prefs.getBool(_prayerMaghribEnabledKey) ?? true,
    'isha': _prefs.getBool(_prayerIshaEnabledKey) ?? true,
  };
  Map<String, int> get savedPrayerReminderByPrayer => {
    'fajr': (_prefs.getInt(_prayerFajrReminderKey) ?? 0).clamp(0, 60),
    'sunrise': (_prefs.getInt(_prayerSunriseReminderKey) ?? 0).clamp(0, 60),
    'dhuhr': (_prefs.getInt(_prayerDhuhrReminderKey) ?? 0).clamp(0, 60),
    'asr': (_prefs.getInt(_prayerAsrReminderKey) ?? 0).clamp(0, 60),
    'maghrib': (_prefs.getInt(_prayerMaghribReminderKey) ?? 0).clamp(0, 60),
    'isha': (_prefs.getInt(_prayerIshaReminderKey) ?? 0).clamp(0, 60),
  };
  String get savedPrayerAdhanProfile =>
      _prefs.getString(_prayerAdhanProfileKey) ?? 'default';
  String? get savedTasbihPhrase => _prefs.getString(_tasbihPhraseKey);
  List<String> get savedTasbihCustomPhrases =>
      _prefs.getStringList(_tasbihCustomPhrasesKey) ?? const <String>[];
  int get savedTasbihTarget => _prefs.getInt(_tasbihTargetKey) ?? 100;
  bool get savedTasbihTapHaptics =>
      _prefs.getBool(_tasbihTapHapticsKey) ?? true;
  bool get savedTasbihGoalHaptics =>
      _prefs.getBool(_tasbihGoalHapticsKey) ?? true;
  bool get savedSalawatReminderEnabled =>
      _prefs.getBool(_salawatReminderEnabledKey) ?? false;
  int get savedSalawatReminderIntervalMinutes =>
      _prefs.getInt(_salawatReminderIntervalKey) ?? 30;
  bool get savedSalawatPauseAtPrayer =>
      _prefs.getBool(_salawatPauseAtPrayerKey) ?? false;
  int get savedSalawatPrayerPauseMinutes =>
      _prefs.getInt(_salawatPrayerPauseMinutesKey) ?? 15;
  bool get savedSalawatWindowEnabled =>
      _prefs.getBool(_salawatWindowEnabledKey) ?? false;
  int get savedSalawatWindowStartMinutes =>
      _prefs.getInt(_salawatWindowStartMinutesKey) ?? 480;
  int get savedSalawatWindowEndMinutes =>
      _prefs.getInt(_salawatWindowEndMinutesKey) ?? 1380;
  bool get savedSalawatVibrationEnabled =>
      _prefs.getBool(_salawatVibrationEnabledKey) ?? false;
  bool get savedSalawatUnlockEnabled =>
      _prefs.getBool(_salawatUnlockEnabledKey) ?? false;
  int get savedSalawatUnlockLastMillis =>
      _prefs.getInt(_salawatUnlockLastKey) ?? 0;
  Map<String, int> get savedSalawatFormulaCounts {
    final raw = _prefs.getString(_salawatFormulaCountsKey);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, int>{};
      }
      return Map<String, int>.fromEntries(
        decoded.entries.map(
          (entry) => MapEntry(entry.key, (entry.value as num?)?.toInt() ?? 0),
        ),
      );
    } catch (_) {
      return <String, int>{};
    }
  }
  Set<String> get savedReadSirahEpisodeIds =>
      _prefs.getStringList(_readSirahEpisodesKey)?.toSet() ?? <String>{};
  String? get savedLastSirahEpisodeId =>
      _prefs.getString(_lastSirahEpisodeIdKey);
  String? get savedLastAppOpenDate => _prefs.getString(_lastAppOpenDateKey);
  String get savedThemeMode {
    final saved = _prefs.getString(_themeModeKey);
    if (saved == 'light' || saved == 'dark' || saved == 'system') {
      return saved!;
    }
    return (_prefs.getBool(_darkModeEnabledKey) ?? false) ? 'dark' : 'light';
  }
  bool get savedDarkModeEnabled => savedThemeMode == 'dark';

  static Future<QuranStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = QuranStore._(prefs);
    store._loadSavedState();
    return store;
  }

  void _loadSavedState() {
    final surah = _prefs.getInt(_lastSurahKey);
    final verse = _prefs.getInt(_lastVerseKey);
    if (surah != null && verse != null) {
      _lastRead = LastReadPosition(surahNumber: surah, verseNumber: verse);
    }
    final rawBookmarks = _prefs.getStringList(_readerBookmarksKey) ?? const [];
    _readerBookmarks =
        rawBookmarks
            .map(
              (entry) => ReaderBookmark.fromJson(
                jsonDecode(entry) as Map<String, dynamic>,
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
  }

  Future<void> saveLastRead({
    required int surahNumber,
    required int verseNumber,
  }) async {
    _lastRead = LastReadPosition(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );
    await _prefs.setInt(_lastSurahKey, surahNumber);
    await _prefs.setInt(_lastVerseKey, verseNumber);
    notifyListeners();
  }

  Future<void> saveReaderPreferences({
    required int reciterIndex,
    required String reciterId,
    required int tafsirId,
    required int repeatCount,
    required double fontSize,
    required double readingSpeed,
    required String appearance,
  }) async {
    await _prefs.setInt(_reciterIndexKey, reciterIndex);
    await _prefs.setString(_reciterIdKey, reciterId);
    await _prefs.setInt(_tafsirIdKey, tafsirId);
    await _prefs.setInt(_repeatCountKey, repeatCount);
    await _prefs.setDouble(_fontSizeKey, fontSize);
    await _prefs.setDouble(_readingSpeedKey, readingSpeed);
    await _prefs.setString(_appearanceKey, appearance);
  }

  Future<void> savePrayerPreferences({
    required String cityName,
    required bool autoDetect,
    required int hijriOffset,
    required Map<String, int> prayerOffsets,
    required bool adhanEnabled,
    required int reminderMinutes,
    required Map<String, bool> prayerEnabledMap,
    required Map<String, int> prayerReminderByPrayer,
    required String adhanProfile,
  }) async {
    final normalizedPrayerOffsets = <String, int>{
      'fajr': (prayerOffsets['fajr'] ?? 0).clamp(-30, 30),
      'sunrise': (prayerOffsets['sunrise'] ?? 0).clamp(-30, 30),
      'dhuhr': (prayerOffsets['dhuhr'] ?? 0).clamp(-30, 30),
      'asr': (prayerOffsets['asr'] ?? 0).clamp(-30, 30),
      'maghrib': (prayerOffsets['maghrib'] ?? 0).clamp(-30, 30),
      'isha': (prayerOffsets['isha'] ?? 0).clamp(-30, 30),
    };
    final normalizedPrayerReminders = <String, int>{
      'fajr': (prayerReminderByPrayer['fajr'] ?? reminderMinutes).clamp(0, 60),
      'sunrise': (prayerReminderByPrayer['sunrise'] ?? reminderMinutes).clamp(
        0,
        60,
      ),
      'dhuhr': (prayerReminderByPrayer['dhuhr'] ?? reminderMinutes).clamp(
        0,
        60,
      ),
      'asr': (prayerReminderByPrayer['asr'] ?? reminderMinutes).clamp(0, 60),
      'maghrib': (prayerReminderByPrayer['maghrib'] ?? reminderMinutes).clamp(
        0,
        60,
      ),
      'isha': (prayerReminderByPrayer['isha'] ?? reminderMinutes).clamp(
        0,
        60,
      ),
    };
    await _prefs.setString(_prayerCityKey, cityName);
    await _prefs.setBool(_prayerAutoDetectKey, autoDetect);
    await _prefs.setInt(_prayerHijriOffsetKey, hijriOffset);
    await _prefs.setInt(_prayerFajrOffsetKey, normalizedPrayerOffsets['fajr']!);
    await _prefs.setInt(
      _prayerSunriseOffsetKey,
      normalizedPrayerOffsets['sunrise']!,
    );
    await _prefs.setInt(
      _prayerDhuhrOffsetKey,
      normalizedPrayerOffsets['dhuhr']!,
    );
    await _prefs.setInt(_prayerAsrOffsetKey, normalizedPrayerOffsets['asr']!);
    await _prefs.setInt(
      _prayerMaghribOffsetKey,
      normalizedPrayerOffsets['maghrib']!,
    );
    await _prefs.setInt(_prayerIshaOffsetKey, normalizedPrayerOffsets['isha']!);
    await _prefs.setBool(_prayerAdhanEnabledKey, adhanEnabled);
    await _prefs.setInt(_prayerReminderMinutesKey, reminderMinutes);
    await _prefs.setBool(
      _prayerFajrEnabledKey,
      prayerEnabledMap['fajr'] ?? true,
    );
    await _prefs.setBool(
      _prayerSunriseEnabledKey,
      prayerEnabledMap['sunrise'] ?? true,
    );
    await _prefs.setBool(
      _prayerDhuhrEnabledKey,
      prayerEnabledMap['dhuhr'] ?? true,
    );
    await _prefs.setBool(_prayerAsrEnabledKey, prayerEnabledMap['asr'] ?? true);
    await _prefs.setBool(
      _prayerMaghribEnabledKey,
      prayerEnabledMap['maghrib'] ?? true,
    );
    await _prefs.setBool(
      _prayerIshaEnabledKey,
      prayerEnabledMap['isha'] ?? true,
    );
    await _prefs.setInt(
      _prayerFajrReminderKey,
      normalizedPrayerReminders['fajr']!,
    );
    await _prefs.setInt(
      _prayerSunriseReminderKey,
      normalizedPrayerReminders['sunrise']!,
    );
    await _prefs.setInt(
      _prayerDhuhrReminderKey,
      normalizedPrayerReminders['dhuhr']!,
    );
    await _prefs.setInt(
      _prayerAsrReminderKey,
      normalizedPrayerReminders['asr']!,
    );
    await _prefs.setInt(
      _prayerMaghribReminderKey,
      normalizedPrayerReminders['maghrib']!,
    );
    await _prefs.setInt(
      _prayerIshaReminderKey,
      normalizedPrayerReminders['isha']!,
    );
    await _prefs.setString(_prayerAdhanProfileKey, adhanProfile);
    notifyListeners();
  }

  Future<void> saveTasbihPreferences({
    required String phrase,
    required int target,
    required bool tapHaptics,
    required bool goalHaptics,
  }) async {
    await _prefs.setString(_tasbihPhraseKey, phrase);
    await _prefs.setInt(_tasbihTargetKey, target);
    await _prefs.setBool(_tasbihTapHapticsKey, tapHaptics);
    await _prefs.setBool(_tasbihGoalHapticsKey, goalHaptics);
    notifyListeners();
  }

  Future<void> saveTasbihCustomPhrases(List<String> phrases) async {
    await _prefs.setStringList(_tasbihCustomPhrasesKey, phrases);
    notifyListeners();
  }

  Future<void> saveSalawatReminderPreferences({
    required bool enabled,
    required int intervalMinutes,
    required bool pauseAtPrayer,
    required int prayerPauseMinutes,
    required bool windowEnabled,
    required int windowStartMinutes,
    required int windowEndMinutes,
    required bool vibrationEnabled,
    required bool unlockEnabled,
  }) async {
    await _prefs.setBool(_salawatReminderEnabledKey, enabled);
    await _prefs.setInt(_salawatReminderIntervalKey, intervalMinutes);
    await _prefs.setBool(_salawatPauseAtPrayerKey, pauseAtPrayer);
    await _prefs.setInt(_salawatPrayerPauseMinutesKey, prayerPauseMinutes);
    await _prefs.setBool(_salawatWindowEnabledKey, windowEnabled);
    await _prefs.setInt(_salawatWindowStartMinutesKey, windowStartMinutes);
    await _prefs.setInt(_salawatWindowEndMinutesKey, windowEndMinutes);
    await _prefs.setBool(_salawatVibrationEnabledKey, vibrationEnabled);
    await _prefs.setBool(_salawatUnlockEnabledKey, unlockEnabled);
    notifyListeners();
  }

  Future<void> saveSalawatUnlockLastMillis(int value) async {
    await _prefs.setInt(_salawatUnlockLastKey, value);
  }

  Future<void> saveSalawatFormulaCount({
    required String formulaId,
    required int count,
  }) async {
    final updated = Map<String, int>.from(savedSalawatFormulaCounts);
    updated[formulaId] = count;
    await _prefs.setString(_salawatFormulaCountsKey, jsonEncode(updated));
    notifyListeners();
  }

  Future<void> markSirahEpisodeRead(String episodeId) async {
    final updated = savedReadSirahEpisodeIds..add(episodeId);
    await _prefs.setStringList(_readSirahEpisodesKey, updated.toList());
    await _prefs.setString(_lastSirahEpisodeIdKey, episodeId);
    notifyListeners();
  }

  Future<void> saveLastSirahEpisodeId(String episodeId) async {
    await _prefs.setString(_lastSirahEpisodeIdKey, episodeId);
    notifyListeners();
  }

  Future<void> saveLastAppOpenDate(String isoDate) async {
    await _prefs.setString(_lastAppOpenDateKey, isoDate);
  }

  Future<void> saveThemeMode(String mode) async {
    if (mode != 'light' && mode != 'dark' && mode != 'system') {
      return;
    }
    await _prefs.setString(_themeModeKey, mode);
    await _prefs.setBool(_darkModeEnabledKey, mode == 'dark');
    notifyListeners();
  }

  Future<void> saveDarkModeEnabled(bool enabled) async {
    await saveThemeMode(enabled ? 'dark' : 'light');
  }

  bool isVerseBookmarked({required int surahNumber, required int verseNumber}) {
    return _readerBookmarks.any(
      (bookmark) =>
          bookmark.surahNumber == surahNumber &&
          bookmark.verseNumber == verseNumber,
    );
  }

  Future<void> upsertReaderBookmark(ReaderBookmark bookmark) async {
    _readerBookmarks = [
      bookmark,
      ..._readerBookmarks.where(
        (entry) =>
            !(entry.surahNumber == bookmark.surahNumber &&
                entry.verseNumber == bookmark.verseNumber),
      ),
    ];
    await _persistReaderBookmarks();
    notifyListeners();
  }

  Future<void> removeReaderBookmark(String id) async {
    _readerBookmarks = _readerBookmarks
        .where((entry) => entry.id != id)
        .toList();
    await _persistReaderBookmarks();
    notifyListeners();
  }

  Future<void> removeReaderBookmarkByVerse({
    required int surahNumber,
    required int verseNumber,
  }) async {
    _readerBookmarks = _readerBookmarks.where((entry) {
      return !(entry.surahNumber == surahNumber &&
          entry.verseNumber == verseNumber);
    }).toList();
    await _persistReaderBookmarks();
    notifyListeners();
  }

  Future<void> _persistReaderBookmarks() async {
    await _prefs.setStringList(
      _readerBookmarksKey,
      _readerBookmarks.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}




