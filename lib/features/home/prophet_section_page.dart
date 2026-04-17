import 'package:flutter/material.dart';

import '../notifications/salawat/salawat_notification_settings_page.dart';
import '../../services/quran_store.dart';
import '../shared/prophet_biography_page.dart';
import '../shared/prophet_lineage_names_page.dart';
import 'salawat_formulas_page.dart';

class ProphetSectionPage extends StatelessWidget {
  const ProphetSectionPage({super.key, required this.store});

  final QuranStore store;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF152127)
        : const Color(0xFFF8F3E7);
    final borderColor = isDark
        ? const Color(0xFF26343B)
        : const Color(0xFFE3D6B8);
    final titleColor = isDark
        ? const Color(0xFFF2ECDF)
        : const Color(0xFF143A2A);
    final bodyColor = isDark
        ? const Color(0xFFC0C9C4)
        : const Color(0xFF4F5A53);
    return Scaffold(
      appBar: AppBar(title: const Text('سيدنا النبي ﷺ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قسم خاص بسيرة سيدنا النبي ﷺ والصلاة والسلام على حضرته',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'من هنا تقدر تقرأ السيرة، تضبط تذكير الصلاة والسلام، وتطالع صيغ الصلاة والسلام المختلفة.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final spacing = 10.0;
                  final columns = width >= 980 ? 3 : (width >= 620 ? 2 : 1);
                  final cardWidth = (width - (columns - 1) * spacing) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _ProphetFeatureCard(
                          title: 'نسب سيدنا النبي وأسماؤه',
                          subtitle:
                              'عرض مبسط لنسب سيدنا محمد ﷺ وأشهر أسمائه وصفاته',
                          icon: Icons.account_tree_rounded,
                          accent: const Color(0xFF3A6585),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProphetLineageNamesPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _ProphetFeatureCard(
                          title: 'سيرة سيدنا النبي',
                          subtitle:
                              'حلقات مرتبة مع حفظ الرجوع لآخر موضع وصلت له',
                          icon: Icons.menu_book_rounded,
                          accent: const Color(0xFF8C6A1F),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ProphetBiographyPage(store: store),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _ProphetFeatureCard(
                          title: 'صيغ الصلاة والسلام',
                          subtitle:
                              'قائمة بصيغ متنوعة يمكنك قراءتها واحدة واحدة',
                          icon: Icons.auto_stories_rounded,
                          accent: const Color(0xFF6B4E9A),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    SalawatFormulasPage(store: store),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _ProphetFeatureCard(
                          title: 'إعدادات الصلاة والسلام',
                          subtitle:
                              'تفعيل التذكير وضبط التكرار والجدولة والإيقاف وقت الصلاة',
                          icon: Icons.notifications_active_rounded,
                          accent: const Color(0xFF2D5C4E),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    SalawatReminderPage(store: store),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProphetFeatureCard extends StatelessWidget {
  const _ProphetFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final leading = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 20),
        );

        final titleRow = Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFF2ECDF)
                      : const Color(0xFF143A2A),
                ),
              ),
            ),
          ],
        );

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18242A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF26343B)
                    : const Color(0xFFE3D6B8),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleRow,
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: isDark
                        ? const Color(0xFFBAC3BE)
                        : const Color(0xFF4F5A53),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
