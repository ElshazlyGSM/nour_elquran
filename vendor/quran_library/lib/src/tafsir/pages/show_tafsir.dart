part of '../tafsir.dart';
// Ù…Ù„Ø§Ø­Ø¸Ø© Ù‡Ø§Ù…Ø©: ÙŠØ¬Ø¨ ØªØ¶Ù…ÙŠÙ† Ù‡Ø°Ø§ Ø§Ù„ÙˆØ¯Ø¬Øª Ø¶Ù…Ù† Scaffold Ø¹Ù†Ø¯ Ø§Ù„Ø§Ø³ØªØ¯Ø¹Ø§Ø¡ Ø­ØªÙ‰ Ù„Ø§ ØªØ¸Ù‡Ø± Ù…Ø´ÙƒÙ„Ø© "No Scaffold widget found"
// Important: This widget must be shown inside a Scaffold to avoid "No Scaffold widget found" error.

// Ù…Ø«Ø§Ù„ Ù„Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„ØµØ­ÙŠØ­:
// Example for correct usage:
// showModalBottomSheet(
//   context: context,
//   builder: (_) => Scaffold(body: ShowTafseer(...)),
// );

class ShowTafseer extends StatelessWidget {
  late final int ayahUQNumber;
  final int pageIndex;
  final BuildContext context;
  final int ayahNumber;
  final bool isDark;
  final TafsirStyle? tafsirStyle;

  ShowTafseer({
    super.key,
    required this.ayahUQNumber,
    required this.ayahNumber,
    required this.pageIndex,
    required this.context,
    required this.isDark,
    this.tafsirStyle,
  });

  final tafsirCtrl = TafsirCtrl.instance;
  final quranCtrl = QuranCtrl.instance;
  final tajweedCtrl = TajweedAyaCtrl.instance;

  @override
  Widget build(BuildContext context) {
    // Ø­Ù„Ù‘ Ø§Ù„Ù†Ù…Ø·: Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ù…Ù…Ø±Ù‘Ø± Ø«Ù… Theme Ø«Ù… Ø§Ù„Ø§ÙØªØ±Ø§Ø¶ÙŠ
    final TafsirStyle s = tafsirStyle ??
        (TafsirTheme.of(context)?.style ??
            TafsirStyle.defaults(isDark: isDark, context: context));
    // Ø´Ø±Ø­: Ù†ØªØ£ÙƒØ¯ Ø£Ù† Ø¹Ù†Ø§ØµØ± tafsirStyle ØºÙŠØ± ÙØ§Ø±ØºØ© Ù„ØªØ¬Ù†Ø¨ Ø§Ù„Ø®Ø·Ø£
    // Explanation: Ensure tafsirStyle widgets are not null to avoid null check errors
    final tafsirNameWidget = s.tafsirNameWidget ?? const SizedBox();
    final double deviceHeight = MediaQuery.maybeOf(context)?.size.height ?? 600;
    final double deviceWidth = MediaQuery.maybeOf(context)?.size.width ?? 400;
    final double sheetHeight = s.heightOfBottomSheet ?? (deviceHeight * 0.9);
    final double sheetWidth = s.widthOfBottomSheet ?? deviceWidth;
    // ØªØ­Ø³ÙŠÙ† Ø§Ù„Ø´ÙƒÙ„: Ø¥Ø¶Ø§ÙØ© Ø´Ø±ÙŠØ· Ø¹Ù„ÙˆÙŠ Ø£Ù†ÙŠÙ‚ Ù…Ø¹ Ø²Ø± Ø¥ØºÙ„Ø§Ù‚ ÙˆØ§Ø³Ù… Ø§Ù„ØªÙØ³ÙŠØ±
    // UI Enhancement: Add a modern top bar with close button and tafsir name
    // final stored = GetStorage()
    //         .read<List<dynamic>>(quran._StorageConstants().loadedFontPages)
    //         ?.cast<int>() ??
    //     const <int>[];
    return GetBuilder<TafsirCtrl>(
      id: 'actualTafsirContent',
      builder: (tafsirCtrl) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTabController(
            length: 2,
            child: Container(
              height: sheetHeight,
              width: sheetWidth,
              padding: const EdgeInsets.only(bottom: 16.0),
              margin: EdgeInsets.symmetric(
                  horizontal: s.horizontalMargin ?? 0.0,
                  vertical: s.verticalMargin ?? 0.0),
              decoration: BoxDecoration(
                color: s.backgroundColor ??
                    (isDark ? const Color(0xff1E1E1E) : Colors.white),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  s.handleWidget ??
                      Container(
                        width: 60,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 8, top: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: s.tabBarLabelStyle ??
                        TextStyle(
                          fontFamily: 'cairo',
                          package: 'quran_library',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.getTextColor(isDark),
                        ),
                    unselectedLabelStyle: s.tabBarUnselectedLabelStyle ??
                        TextStyle(
                          fontFamily: 'cairo',
                          package: 'quran_library',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.getTextColor(isDark),
                        ),
                    tabs: const [
                      Tab(text: 'التفسير'),
                      Tab(text: 'أحكام التجويد'),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  tafsirNameWidget,
                                  ChangeTafsirDialog(
                                      tafsirStyle: s, isDark: isDark),
                                  Row(
                                    children: [
                                      Container(
                                          width: 1,
                                          height: 24,
                                          color: Colors.grey.shade300),
                                      const SizedBox(width: 8),
                                      s.fontSizeWidget ??
                                          fontSizeDropDown(
                                            height: 30.0,
                                            tafsirStyle: s,
                                            isDark: isDark,
                                          ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                  ),
                                ),
                                child: TafsirPagesBuild(
                                  pageIndex: pageIndex,
                                  ayahUQNumber: ayahUQNumber,
                                  tafsirStyle: s,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _TajweedAyaTab(
                          ayahUQNumber: ayahUQNumber,
                          ayahNumber: ayahNumber,
                          quranCtrl: quranCtrl,
                          tajweedCtrl: tajweedCtrl,
                          isDark: isDark,
                          tafsirStyle: s,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
