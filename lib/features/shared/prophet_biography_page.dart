import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../data/prophet_biography_data.dart';
import '../../services/quran_store.dart';

class ProphetBiographyPage extends StatefulWidget {
  const ProphetBiographyPage({super.key, required this.store});

  final QuranStore store;

  @override
  State<ProphetBiographyPage> createState() => _ProphetBiographyPageState();
}

class _ProphetBiographyPageState extends State<ProphetBiographyPage> {
  late Set<String> _readEpisodes;
  late Future<List<ProphetBiographyEpisodeSummary>> _episodesFuture;
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool _didJumpToLastRead = false;

  @override
  void initState() {
    super.initState();
    _readEpisodes = widget.store.savedReadSirahEpisodeIds;
    _episodesFuture = loadProphetBiographyEpisodes();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('سيرة سيدنا النبي')),
      body: FutureBuilder<List<ProphetBiographyEpisodeSummary>>(
        future: _episodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final episodes =
              snapshot.data ?? const <ProphetBiographyEpisodeSummary>[];
          if (episodes.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد حلقات متاحة حاليًا',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_didJumpToLastRead) {
              return;
            }
            _jumpToLastRead(episodes);
          });

          final bottomPadding = MediaQuery.of(context).padding.bottom;
          return ScrollablePositionedList.separated(
            itemScrollController: _itemScrollController,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomPadding),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              final isRead = _readEpisodes.contains(episode.id);
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final completed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => _SirahEpisodeDetailsPage(
                        title: episode.title,
                        assetPath: episode.assetPath,
                      ),
                    ),
                  );
                  if (completed != true) {
                    return;
                  }
                  await widget.store.markSirahEpisodeRead(episode.id);
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _readEpisodes = widget.store.savedReadSirahEpisodeIds;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF152127)
                        : const Color(0xFFF8F3E7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isRead
                          ? const Color(0xFF7BA86F)
                          : (isDark
                                ? const Color(0xFF26343B)
                                : const Color(0xFFE3D6B8)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              episode.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFF2ECDF)
                                    : const Color(0xFF143A2A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              episode.preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.7,
                                color: isDark
                                    ? const Color(0xFFD5D0C6)
                                    : const Color(0xFF2F3A33),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isRead
                              ? const Color(0xFF7BA86F)
                              : (isDark
                                    ? const Color(0xFF18242A)
                                    : Colors.white),
                          border: Border.all(
                            color: isRead
                                ? const Color(0xFF7BA86F)
                                : const Color(0xFFCBBE9F),
                          ),
                        ),
                        child: isRead
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: episodes.length,
          );
        },
      ),
    );
  }

  void _jumpToLastRead(List<ProphetBiographyEpisodeSummary> episodes) {
    final lastId = widget.store.savedLastSirahEpisodeId;
    if (lastId == null || lastId.isEmpty || !_itemScrollController.isAttached) {
      _didJumpToLastRead = true;
      return;
    }

    final targetIndex = episodes.indexWhere((episode) => episode.id == lastId);
    if (targetIndex < 0) {
      _didJumpToLastRead = true;
      return;
    }

    _itemScrollController.jumpTo(index: targetIndex, alignment: 0.2);
    _didJumpToLastRead = true;
  }
}

class _SirahEpisodeDetailsPage extends StatefulWidget {
  const _SirahEpisodeDetailsPage({
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  State<_SirahEpisodeDetailsPage> createState() =>
      _SirahEpisodeDetailsPageState();
}

class _SirahEpisodeDetailsPageState extends State<_SirahEpisodeDetailsPage> {
  late final ScrollController _scrollController;
  late final Future<ProphetBiographyEpisodeDetails> _detailsFuture;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = loadProphetBiographyEpisodeDetails(widget.assetPath);
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          Navigator.of(context).pop(_completed);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_completed),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(widget.title),
        ),
        body: FutureBuilder<ProphetBiographyEpisodeDetails>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final details = snapshot.data;
            if (details == null) {
              return const Center(
                child: Text(
                  'تعذر فتح الحلقة حاليًا',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _handleScroll(),
            );

            return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF152127)
                        : const Color(0xFFF8F3E7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF26343B)
                          : const Color(0xFFE3D6B8),
                    ),
                  ),
                  child: Text(
                    details.body,
                    style: TextStyle(
                      fontSize: 18,
                      height: 2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE2DDD4)
                          : const Color(0xFF2F3A33),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleScroll() {
    if (_completed || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 24) {
      _completed = true;
    }
  }
}
