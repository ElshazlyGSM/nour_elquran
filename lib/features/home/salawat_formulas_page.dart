import 'package:flutter/material.dart';

import '../../data/salawat_formulas.dart';
import '../../services/quran_store.dart';
import '../../services/salawat_formulas_service.dart';

class SalawatFormulasPage extends StatefulWidget {
  const SalawatFormulasPage({super.key, required this.store});

  final QuranStore store;

  @override
  State<SalawatFormulasPage> createState() => _SalawatFormulasPageState();
}

class _SalawatFormulasPageState extends State<SalawatFormulasPage> {
  late Future<List<SalawatFormula>> _future;

  @override
  void initState() {
    super.initState();
    _future = SalawatFormulasService.instance.loadFormulas();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u0635\u064a\u063a \u0627\u0644\u0635\u0644\u0627\u0629 \u0648\u0627\u0644\u0633\u0644\u0627\u0645'),
      ),
      body: FutureBuilder<List<SalawatFormula>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? fallbackSalawatFormulas;
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView.separated(
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
                          builder: (_) => SalawatFormulaDetailPage(
                            store: widget.store,
                            formula: item,
                          ),
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
                                fontSize: 20,
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
              ),
            ),
          );
        },
      ),
    );
  }
}

class SalawatFormulaDetailPage extends StatefulWidget {
  const SalawatFormulaDetailPage({
    super.key,
    required this.store,
    required this.formula,
  });

  final QuranStore store;
  final SalawatFormula formula;

  @override
  State<SalawatFormulaDetailPage> createState() =>
      _SalawatFormulaDetailPageState();
}

class _SalawatFormulaDetailPageState extends State<SalawatFormulaDetailPage> {
  late int _count;

  String get _formulaId {
    final title = widget.formula.title.trim();
    final text = widget.formula.text.trim();
    final preview = text.length <= 80 ? text : text.substring(0, 80);
    return '$title|$preview';
  }

  @override
  void initState() {
    super.initState();
    _count = widget.store.savedSalawatFormulaCounts[_formulaId] ?? 0;
  }

  Future<void> _incrementCount() async {
    final next = _count + 1;
    setState(() => _count = next);
    await widget.store.saveSalawatFormulaCount(
      formulaId: _formulaId,
      count: next,
    );
  }

  Future<void> _resetCount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تصفير العداد'),
          content: const Text('هل تريد تصفير عدد تكرار الذكر؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تصفير'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _count = 0);
    await widget.store.saveSalawatFormulaCount(formulaId: _formulaId, count: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(widget.formula.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _incrementCount,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF152127)
                        : const Color(0xFFF9F6EE),
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
                        widget.formula.text,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.8,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFF2ECDF)
                              : const Color(0xFF143A2A),
                        ),
                      ),
                      if (widget.formula.note != null &&
                          widget.formula.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.formula.note!,
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
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18242A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF26343B)
                          : const Color(0xFFE6D8B7),
                    ),
                  ),
                  child: Text(
                    'عدد تكرار الذكر: $_count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFF2ECDF)
                          : const Color(0xFF143A2A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _count == 0 ? null : _resetCount,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('تصفير العداد'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'اضغط على مربع الصيغة لزيادة العداد.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFBAC3BE)
                      : const Color(0xFF4F5A53),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

