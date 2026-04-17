import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/shamarly_pages_download_config.dart';

class StorageManagementPage extends StatefulWidget {
  const StorageManagementPage({super.key});

  @override
  State<StorageManagementPage> createState() => _StorageManagementPageState();
}

class _StorageManagementPageState extends State<StorageManagementPage> {
  bool _isLoading = true;
  String? _busyKey;
  List<_StorageEntry> _entries = const <_StorageEntry>[];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<Directory> _docsDir() => getApplicationDocumentsDirectory();

  Future<Directory> _dir(String name) async {
    final root = await _docsDir();
    return Directory('${root.path}${Platform.pathSeparator}$name');
  }

  Future<int> _directoryBytes(String name) async {
    final dir = await _dir(name);
    if (!await dir.exists()) {
      return 0;
    }
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<void> _deleteDirectory(String name) async {
    final dir = await _dir(name);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final entries = <_StorageEntry>[
      _StorageEntry(
        key: 'recitations',
        title: 'التلاوات المحملة',
        description: 'ملفات MP3 التي تم تنزيلها للاستماع بدون إنترنت.',
        bytes: await _directoryBytes('recitations'),
        onClear: () => _deleteDirectory('recitations'),
      ),
      _StorageEntry(
        key: 'shamarly',
        title: 'مصحف الشمرلي',
        description: 'صور الشمرلي التي تم تنزيلها للقراءة بدون إنترنت.',
        bytes: await _directoryBytes(
          ShamarlyPagesDownloadConfig.localFolderName,
        ),
        onClear: () =>
            _deleteDirectory(ShamarlyPagesDownloadConfig.localFolderName),
      ),
      _StorageEntry(
        key: 'medina',
        title: 'مصحف المدينة',
        description:
            'ملفات مصحف المدينة التي تم تنزيلها لعرض المصحف بدون إنترنت.',
        bytes: await _directoryBytes('quran_fonts_cache'),
        onClear: () => _deleteDirectory('quran_fonts_cache'),
      ),
      _StorageEntry(
        key: 'tafsir',
        title: 'التفاسير المحملة',
        description:
            'ملفات التفاسير التي تم تنزيلها للقراءة السريعة بدون إنترنت.',
        bytes: await _directoryBytes('tafsir_cache'),
        onClear: () => _deleteDirectory('tafsir_cache'),
      ),
      _StorageEntry(
        key: 'adhan',
        title: 'أصوات الأذان',
        description: 'ملفات الأذان التي تم تنزيلها للإشعارات والتنبيهات.',
        bytes: await _directoryBytes('adhan_audio'),
        onClear: () => _deleteDirectory('adhan_audio'),
      ),
      _StorageEntry(
        key: 'timings',
        title: 'مواقيت التلاوات',
        description: 'ملفات التوقيت الخاصة بتلاوات MP3Quran المحملة سابقًا.',
        bytes: await _directoryBytes('mp3quran_timings'),
        onClear: () => _deleteDirectory('mp3quran_timings'),
      ),
    ];

    if (!mounted) {
      return;
    }

    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _clearEntry(_StorageEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف ${entry.title}?'),
        content: Text(
          'سيتم حذف ${entry.title} من الهاتف، ويمكنك تنزيلها مرة أخرى لاحقًا عند الحاجة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _busyKey = entry.key;
    });

    try {
      await entry.onClear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف ${entry.title} من الهاتف')),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حذف ${entry.title} حاليًا')));
      setState(() {
        _busyKey = null;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 ب';
    }
    const units = ['ب', 'ك.ب', 'م.ب', 'ج.ب'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final fractionDigits = value >= 100 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final totalBytes = _entries.fold<int>(0, (sum, item) => sum + item.bytes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التخزين'),
        backgroundColor: const Color(0xFF143A2A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F0E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المساحة المستخدمة داخل التطبيق',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatBytes(totalBytes),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF143A2A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'يمكنك حذف أي ملفات محفوظة من هنا لتوفير مساحة، وسيظل بإمكانك تنزيلها مرة أخرى عند الحاجة.',
                            style: TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._entries.map((entry) {
                      final isBusy = _busyKey == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatBytes(entry.bytes),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF143A2A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  entry.description,
                                  style: const TextStyle(height: 1.5),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.tonalIcon(
                                    onPressed: isBusy || entry.bytes == 0
                                        ? null
                                        : () => _clearEntry(entry),
                                    icon: isBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                    label: Text(
                                      entry.bytes == 0
                                          ? 'فارغ'
                                          : 'حذف هذه الملفات',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StorageEntry {
  const _StorageEntry({
    required this.key,
    required this.title,
    required this.description,
    required this.bytes,
    required this.onClear,
  });

  final String key;
  final String title;
  final String description;
  final int bytes;
  final Future<void> Function() onClear;
}
