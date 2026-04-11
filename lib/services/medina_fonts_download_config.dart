class MedinaFontsDownloadConfig {
  const MedinaFontsDownloadConfig._();

  /// Enable on-demand downloading for Mushaf al-Madina pages.
  /// When disabled, the reader behaves as before and uses bundled assets.
  static const bool enableOnDemandDownload = true;

  /// Ordered download sources. The app tries the first URL, then falls back
  /// to the next ones automatically if a source is unavailable.
  static const List<String> zipUrls = <String>[
    'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/medina_fonts.zip',
    'https://github.com/ElshazlyGSM/mushaf-pages/releases/download/v1/medina_fonts.zip',
  ];

  static const int totalPages = 604;

  static const String zipFileName = 'medina_fonts.zip';
}


