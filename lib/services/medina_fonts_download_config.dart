class MedinaFontsDownloadConfig {
  const MedinaFontsDownloadConfig._();

  /// Enable on-demand downloading for Mushaf al-Madina pages.
  /// When disabled, the reader behaves as before and uses bundled assets.
  static const bool enableOnDemandDownload = true;

  /// ZIP URL that contains all Medina pages in a single archive.
  /// Example: https://storage.googleapis.com/your-bucket/medina_pages.zip
  static const String zipUrl =
      'https://github.com/ElshazlyGSM/mushaf-pages/releases/download/v1/medina_fonts.zip';

  /// Total number of pages in the Medina mushaf.
  static const int totalPages = 604;

  static const String zipFileName = 'medina_fonts.zip';
}
