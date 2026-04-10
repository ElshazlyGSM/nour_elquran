import 'package:flutter/material.dart';

import '../../data/salawat_formulas.dart';
import '../../services/salawat_formulas_service.dart';

class SalawatFormulasPage extends StatefulWidget {
  const SalawatFormulasPage({super.key});

  @override
  State<SalawatFormulasPage> createState() => _SalawatFormulasPageState();
}

class _SalawatFormulasPageState extends State<SalawatFormulasPage> {
  late Future<List<SalawatFormula>> _future;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = SalawatFormulasService.instance.loadFormulas();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) {
      return;
    }
    setState(() => _isRefreshing = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('جارٍ التحقق من التحديث...')),
      );
    try {
      final result = await SalawatFormulasService.instance.refreshNow();
      if (!mounted) {
        return;
      }
      setState(() {
        _future = SalawatFormulasService.instance.loadFormulas();
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result == SalawatFormulasRefreshResult.updated
                  ? 'تم تحديث الصيغ'
                  : result == SalawatFormulasRefreshResult.noChange
                  ? 'لا يوجد تحديث جديد'
                  : 'تعذر تحديث الصيغ',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تعذر تحديث الصيغ')));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('صيغ الصلاة والسلام'),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_isRefreshing) {
                return;
              }
              _refresh();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isRefreshing
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          IconTheme.of(context).color ?? Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      key: ValueKey('refresh'),
                    ),
            ),
            label: const Text('تحديث'),
          ),
        ],
      ),
      body: FutureBuilder<List<SalawatFormula>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? fallbackSalawatFormulas;
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SalawatFormulaDetailPage(formula: item),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18242A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF26343B)
                          : const Color(0xFFE3D6B8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFF2ECDF)
                                : const Color(0xFF143A2A),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color(0xFF8C6A1F),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SalawatFormulaDetailPage extends StatelessWidget {
  const SalawatFormulaDetailPage({super.key, required this.formula});

  final SalawatFormula formula;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(formula.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF152127) : const Color(0xFFF9F6EE),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF26343B)
                    : const Color(0xFFE6D8B7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formula.text,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.8,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFF2ECDF)
                        : const Color(0xFF143A2A),
                  ),
                ),
                if (formula.note != null &&
                    formula.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    formula.note!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFBAC3BE)
                          : const Color(0xFF4F5A53),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
