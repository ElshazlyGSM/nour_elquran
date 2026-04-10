class ReaderBookmark {
  const ReaderBookmark({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.juzNumber,
    required this.surahName,
    required this.previewText,
    required this.createdAtMillis,
    this.note,
    this.colorValue,
  });

  final String id;
  final int surahNumber;
  final int verseNumber;
  final int pageNumber;
  final int juzNumber;
  final String surahName;
  final String previewText;
  final int createdAtMillis;
  final String? note;
  final int? colorValue;

  factory ReaderBookmark.fromJson(Map<String, dynamic> json) {
    return ReaderBookmark(
      id: json['id'] as String,
      surahNumber: json['surahNumber'] as int,
      verseNumber: json['verseNumber'] as int,
      pageNumber: json['pageNumber'] as int,
      juzNumber: json['juzNumber'] as int,
      surahName: json['surahName'] as String,
      previewText: json['previewText'] as String,
      createdAtMillis: json['createdAtMillis'] as int,
      note: json['note'] as String?,
      colorValue: json['colorValue'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'verseNumber': verseNumber,
    'pageNumber': pageNumber,
    'juzNumber': juzNumber,
    'surahName': surahName,
    'previewText': previewText,
    'createdAtMillis': createdAtMillis,
    'note': note,
    'colorValue': colorValue,
  };
}
