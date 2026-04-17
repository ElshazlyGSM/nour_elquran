import 'package:flutter/material.dart';

class ProphetLineageNamesPage extends StatelessWidget {
  const ProphetLineageNamesPage({super.key});

  static const List<String> _names = <String>[
    'مُحَمَّدٌ ﷺ',
    'أَحْمَدُ ﷺ',
    'حَامِدٌ ﷺ',
    'مَحْمُودٌ ﷺ',
    'أَحِيدٌ ﷺ',
    'وَحِيدٌ ﷺ',
    'مَاحٍ ﷺ',
    'حَاشِرٌ ﷺ',
    'عَاقِبٌ ﷺ',
    'طٰهٰ ﷺ',
    'يٰسٓ ﷺ',
    'طَاهِرٌ ﷺ',
    'مُطَهَّرٌ ﷺ',
    'طَيِّبٌ ﷺ',
    'سَيِّدٌ ﷺ',
    'رَسُولٌ ﷺ',
    'نَبِيٌّ ﷺ',
    'رَسُولُ الرَّحْمَةِ ﷺ',
    'قَيِّمٌ ﷺ',
    'جَامِعٌ ﷺ',
    'مُقْتَفٍ ﷺ',
    'مُقَفًّى ﷺ',
    'رَسُولُ الْمَلَاحِمِ ﷺ',
    'رَسُولُ الرَّاحَةِ ﷺ',
    'كَامِلٌ ﷺ',
    'إِكْلِيلٌ ﷺ',
    'مُدَّثِّرٌ ﷺ',
    'مُزَّمِّلٌ ﷺ',
    'عَبْدُ اللَّهِ ﷺ',
    'حَبِيبُ اللَّهِ ﷺ',
    'صَفِيُّ اللَّهِ ﷺ',
    'نَجِيُّ اللَّهِ ﷺ',
    'كَلِيمُ اللَّهِ ﷺ',
    'خَاتَمُ الْأَنْبِيَاءِ ﷺ',
    'خَاتَمُ الرُّسُلِ ﷺ',
    'مُحْيٍ ﷺ',
    'مُنَجٍّ ﷺ',
    'مُذَكِّرٌ ﷺ',
    'نَاصِرٌ ﷺ',
    'مَنْصُورٌ ﷺ',
    'نَبِيُّ الرَّحْمَةِ ﷺ',
    'نَبِيُّ التَّوْبَةِ ﷺ',
    'حَرِيصٌ عَلَيْكُمْ ﷺ',
    'مَعْلُومٌ ﷺ',
    'شَهِيرٌ ﷺ',
    'شَاهِدٌ ﷺ',
    'شَهِيدٌ ﷺ',
    'مَشْهُودٌ ﷺ',
    'بَشِيرٌ ﷺ',
    'مُبَشِّرٌ ﷺ',
    'نَذِيرٌ ﷺ',
    'مُنْذِرٌ ﷺ',
    'نُورٌ ﷺ',
    'سِرَاجٌ ﷺ',
    'مِصْبَاحٌ ﷺ',
    'هُدًى ﷺ',
    'مَهْدِيٌّ ﷺ',
    'مُنِيرٌ ﷺ',
    'دَاعٍ ﷺ',
    'مَدْعُوٌّ ﷺ',
    'مُجِيبٌ ﷺ',
    'مُجَابٌ ﷺ',
    'حَفِيٌّ ﷺ',
    'عَفُوٌّ ﷺ',
    'وَلِيٌّ ﷺ',
    'حَقٌّ ﷺ',
    'قَوِيٌّ ﷺ',
    'أَمِينٌ ﷺ',
    'مَأْمُونٌ ﷺ',
    'كَرِيمٌ ﷺ',
    'مُكَرَّمٌ ﷺ',
    'مَكِينٌ ﷺ',
    'مَتِينٌ ﷺ',
    'مُبِينٌ ﷺ',
    'مُؤَمِّلٌ ﷺ',
    'وَصُولٌ ﷺ',
    'ذُو قُوَّةٍ ﷺ',
    'ذُو حُرْمَةٍ ﷺ',
    'ذُو مَكَانَةٍ ﷺ',
    'ذُو عِزٍّ ﷺ',
    'ذُو فَضْلٍ ﷺ',
    'مُطَاعٌ ﷺ',
    'مُطِيعٌ ﷺ',
    'قَدَمُ صِدْقٍ ﷺ',
    'رَحْمَةٌ ﷺ',
    'بُشْرَى ﷺ',
    'غَوْثٌ ﷺ',
    'غَيْثٌ ﷺ',
    'غِيَاثٌ ﷺ',
    'نِعْمَةُ اللَّهِ ﷺ',
    'هَدِيَّةُ اللَّهِ ﷺ',
    'عُرْوَةٌ وُثْقَى ﷺ',
    'صِرَاطُ اللَّهِ ﷺ',
    'صِرَاطٌ مُسْتَقِيمٌ ﷺ',
    'ذِكْرُ اللَّهِ ﷺ',
    'سَيْفُ اللَّهِ ﷺ',
    'حِزْبُ اللَّهِ ﷺ',
    'النَّجْمُ الثَّاقِبُ ﷺ',
    'مُصْطَفًى ﷺ',
    'مُجْتَبًى ﷺ',
    'مُنْتَقًى ﷺ',
    'أُمِّيٌّ ﷺ',
    'مُخْتَارٌ ﷺ',
    'أَجِيرٌ ﷺ',
    'جَبَّارٌ ﷺ',
    'أَبُو الْقَاسِمِ ﷺ',
    'أَبُو الطَّاهِرِ ﷺ',
    'أَبُو الطَّيِّبِ ﷺ',
    'أَبُو إِبْرَاهِيمَ ﷺ',
    'مُشَفَّعٌ ﷺ',
    'شَفِيعٌ ﷺ',
    'صَالِحٌ ﷺ',
    'مُصْلِحٌ ﷺ',
    'مُهَيْمِنٌ ﷺ',
    'صَادِقٌ ﷺ',
    'مُصَدَّقٌ ﷺ',
    'صِدْقٌ ﷺ',
    'سَيِّدُ الْمُرْسَلِينَ ﷺ',
    'إِمَامُ الْمُتَّقِينَ ﷺ',
    'قَائِدُ الْغُرِّ الْمُحَجَّلِينَ ﷺ',
    'خَلِيلُ الرَّحْمَنِ ﷺ',
    'بَرٌّ ﷺ',
    'مَبَرٌّ ﷺ',
    'وَجِيهٌ ﷺ',
    'نَصِيحٌ ﷺ',
    'نَاصِحٌ ﷺ',
    'وَكِيلٌ ﷺ',
    'مُتَوَكِّلٌ ﷺ',
    'كَفِيلٌ ﷺ',
    'شَفِيقٌ ﷺ',
    'مُقِيمُ السُّنَّةِ ﷺ',
    'مُقَدَّسٌ ﷺ',
    'رُوحُ الْقُدُسِ ﷺ',
    'رُوحُ الْحَقِّ ﷺ',
    'رُوحُ الْقِسْطِ ﷺ',
    'كَافٍ ﷺ',
    'مُكْتَفٍ ﷺ',
    'بَالِغٌ ﷺ',
    'مُبَلِّغٌ ﷺ',
    'شَافٍ ﷺ',
    'وَاصِلٌ ﷺ',
    'مَوْصُولٌ ﷺ',
    'سَابِقٌ ﷺ',
    'سَائِقٌ ﷺ',
    'هَادٍ ﷺ',
    'مُهْدٍ ﷺ',
    'مُقَدَّمٌ ﷺ',
    'عَزِيزٌ ﷺ',
    'فَاضِلٌ ﷺ',
    'مُفَضَّلٌ ﷺ',
    'فَاتِحٌ ﷺ',
    'مِفْتَاحُ الرَّحْمَةِ ﷺ',
    'مِفْتَاحُ الْجَنَّةِ ﷺ',
    'عَلَمُ الْإِيمَانِ ﷺ',
    'عَلَمُ الْيَقِينِ ﷺ',
    'دَلِيلُ الْخَيْرَاتِ ﷺ',
    'مُصَحِّحُ الْحَسَنَاتِ ﷺ',
    'مُقِيلُ الْعَثَرَاتِ ﷺ',
    'صَفُوحٌ عَنِ الزَّلَّاتِ ﷺ',
    'صَاحِبُ الشَّفَاعَةِ ﷺ',
    'صَاحِبُ الْمَقَامِ ﷺ',
    'صَاحِبُ الْقَدَمِ ﷺ',
    'مَخْصُوصٌ بِالْعِزِّ ﷺ',
    'مَخْصُوصٌ بِالْمَجْدِ ﷺ',
    'مَخْصُوصٌ بِالشَّرَفِ ﷺ',
    'صَاحِبُ الْوَسِيلَةِ ﷺ',
    'صَاحِبُ السَّيْفِ ﷺ',
    'صَاحِبُ الْفَضِيلَةِ ﷺ',
    'صَاحِبُ الْإِزَارِ ﷺ',
    'صَاحِبُ الْحُجَّةِ ﷺ',
    'صَاحِبُ السُّلْطَانِ ﷺ',
    'صَاحِبُ الرِّدَاءِ ﷺ',
    'صَاحِبُ الدَّرَجَةِ الرَّفِيعَةِ ﷺ',
    'صَاحِبُ التَّاجِ ﷺ',
    'صَاحِبُ الْمِغْفَرِ ﷺ',
    'صَاحِبُ اللِّوَاءِ ﷺ',
    'صَاحِبُ الْمِعْرَاجِ ﷺ',
    'صَاحِبُ الْقَضِيبِ ﷺ',
    'صَاحِبُ الْبُرَاقِ ﷺ',
    'صَاحِبُ الْخَاتَمِ ﷺ',
    'صَاحِبُ الْعَلَامَةِ ﷺ',
    'صَاحِبُ الْبُرْهَانِ ﷺ',
    'صَاحِبُ الْبَيَانِ ﷺ',
    'فَصِيحُ اللِّسَانِ ﷺ',
    'مُطَهَّرُ الْجَنَانِ ﷺ',
    'رَؤُوفٌ ﷺ',
    'رَحِيمٌ ﷺ',
    'أُذُنُ خَيْرٍ ﷺ',
    'صَحِيحُ الْإِسْلَامِ ﷺ',
    'سَيِّدُ الْكَوْنَيْنِ ﷺ',
    'عَيْنُ النَّعِيمِ ﷺ',
    'عَيْنُ الْغُرِّ ﷺ',
    'سَعْدُ اللَّهِ ﷺ',
    'سَعْدُ الْخَلْقِ ﷺ',
    'خَطِيبُ الْأُمَمِ ﷺ',
    'عَلَمُ الْهُدَى ﷺ',
    'كَاشِفُ الْكُرَبِ ﷺ',
    'رَافِعُ الرُّتَبِ ﷺ',
    'عِزُّ الْعَرَبِ ﷺ',
    'صَاحِبُ الْفَرَجِ ﷺ',
  ];

  static const List<String> _lineage = <String>[
    'هُوَ سيدنا مُحَمَّدُ بْنُ عَبْدِ ٱللّٰهِ بْنِ عَبْدِ ٱلْمُطَّلِبِ بْنِ هَاشِمِ بْنِ عَبْدِ مَنَافِ بْنِ قُصَيِّ بْنِ كِلَابِ بْنِ مُرَّةَ بْنِ كَعْبِ بْنِ لُؤَيِّ بْنِ غَالِبِ بْنِ فِهْرِ بْنِ مَالِكِ بْنِ ٱلنَّضْرِ بْنِ كِنَانَةَ بْنِ خُزَيْمَةَ بْنِ مُدْرِكَةَ بْنِ إِلْيَاسَ بْنِ مُضَرَ بْنِ نِزَارِ بْنِ مَعَدِّ بْنِ عَدْنَانَ مِنْ ذُرِّيَّةِ إِسْمَاعِيلَ بْنِ إِبْرَاهِيمَ.',
    'وأمه آمنة بنت وهب بن عبد مناف بن زهرة بن كلاب.',
    'ويجتمع نسبه الشريف من جهة الأب والأم في كلاب بن مُرّة.',
    'وَنَسْلُه ﷺ مُمْتَدٌّ من ذُرِّيَّةِ:السيدة فَاطِمَةَ بِنْتِ مُحَمَّدٍ، والسيد عَلِيِّ بْنِ أَبِي طَالِبٍ.',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF152127) : const Color(0xFFF8F3E7);
    final borderColor = isDark ? const Color(0xFF26343B) : const Color(0xFFE3D6B8);
    final titleColor = isDark ? const Color(0xFFF2ECDF) : const Color(0xFF143A2A);
    final bodyColor = isDark ? const Color(0xFFD0D8D3) : const Color(0xFF33443E);

    return Scaffold(
      appBar: AppBar(title: const Text('نسب سيدنا النبي وأسماؤه ﷺ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              _SectionCard(
                title: 'النسب الشريف',
                titleColor: titleColor,
                cardColor: cardColor,
                borderColor: borderColor,
                children: [
                  for (final line in _lineage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: bodyColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'أسماء سيدنا ومولانا محمد ﷺ',
                titleColor: titleColor,
                cardColor: cardColor,
                borderColor: borderColor,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final name in _names)
                        _NameCard(
                          name: name,
                          isDark: isDark,
                          titleColor: titleColor,
                          borderColor: borderColor,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({
    required this.name,
    required this.isDark,
    required this.titleColor,
    required this.borderColor,
  });

  final String name;
  final bool isDark;
  final Color titleColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2830) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0x1A143A2A),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: titleColor,
          height: 1.35,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    required this.titleColor,
    required this.cardColor,
    required this.borderColor,
  });

  final String title;
  final List<Widget> children;
  final Color titleColor;
  final Color cardColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}