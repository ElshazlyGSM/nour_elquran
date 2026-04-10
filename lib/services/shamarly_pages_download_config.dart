class ShamarlyPagesDownloadConfig {
  const ShamarlyPagesDownloadConfig._();

  static const bool enableOnDemandDownload = true;

  /// Direct URL to the ZIP file that contains all pages.
  /// Example: https://github.com/owner/repo/releases/download/v1/shamarly_pages_100.zip
  static const String zipUrl =
      'https://github.com/ElshazlyGSM/mushaf-pages/releases/download/v2/shamarly_pages_100.zip';

  static const int totalPages = 522;
  static const String filePrefix = 'page-';
  static const String fileExtension = '.jpg';
  static const int filePadding = 3;
  static const String localFolderName = 'shamarly_pages';
  static const String zipFileName = 'shamarly_pages.zip';
}
