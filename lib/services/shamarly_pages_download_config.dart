class ShamarlyPagesDownloadConfig {
  const ShamarlyPagesDownloadConfig._();

  static const bool enableOnDemandDownload = true;

  /// Ordered download sources. The app tries the first URL, then falls back
  /// to the next ones automatically if a source is unavailable.
  static const List<String> zipUrls = <String>[
    'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/shamarly_pages_100.zip',
    'https://github.com/ElshazlyGSM/mushaf-pages/releases/download/v2/shamarly_pages_100.zip',
  ];

  static const int totalPages = 522;
  static const String filePrefix = 'page-';
  static const String fileExtension = '.jpg';
  static const int filePadding = 3;
  static const String localFolderName = 'shamarly_pages';
  static const String zipFileName = 'shamarly_pages.zip';
}
