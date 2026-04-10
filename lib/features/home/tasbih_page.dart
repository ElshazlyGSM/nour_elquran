import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../core/utils/arabic_numbers.dart';
import '../../services/quran_store.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key, this.store});

  final QuranStore? store;

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  static const _defaultPhrases = [
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
    'أستغفر الله',
    'سبحان الله وبحمده سبحان الله العظيم',
    'لا إله إلا أنت سبحانك إني كنت من الظالمين',
    'اللهم صل وسلم وبارك على سيدنا محمد',
  ];

  late String _selectedPhrase;
  late int _targetCount;
  late bool _tapHaptics;
  late bool _goalHaptics;
  late List<String> _customPhrases;
  int _count = 0;

  List<String> get _allPhrases => [
    ..._defaultPhrases,
    ..._customPhrases.where((phrase) => !_defaultPhrases.contains(phrase)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPhrase = widget.store?.savedTasbihPhrase ?? _defaultPhrases.first;
    _targetCount = (widget.store?.savedTasbihTarget ?? 100).clamp(1, 10000);
    _tapHaptics = widget.store?.savedTasbihTapHaptics ?? true;
    _goalHaptics = widget.store?.savedTasbihGoalHaptics ?? true;
    _customPhrases = List<String>.from(
      widget.store?.savedTasbihCustomPhrases ?? const <String>[],
    );
    if (!_allPhrases.contains(_selectedPhrase)) {
      _selectedPhrase = _defaultPhrases.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = (_targetCount - _count).clamp(0, _targetCount);
    final width = MediaQuery.of(context).size.width;
    final cardMaxWidth = width > 700 ? 380.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('السبحة الإلكترونية')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _showPhrasePicker,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'الأذكار المختارة',
                              prefixIcon: Icon(Icons.list_alt_rounded),
                              suffixIcon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              filled: true,
                              fillColor: null,
                            ),
                            child: Text(
                              _selectedPhrase,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ActionChip(
                            avatar: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text(
                              'ذكر مخصص واعدادت الإهتزاز',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: _showTasbihSettings,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF152127)
                                  : const Color(0xFFF8F3E7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF26343B)
                                    : const Color(0xFFE3D6B8),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _selectedPhrase,
                                  textAlign: TextAlign.center,
                                  maxLines: 5,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFF2ECDF)
                                        : const Color(0xFF143A2A),
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  toArabicNumber(_count),
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? const Color(0xFFF2ECDF)
                                        : const Color(0xFF143A2A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'الهدف ${toArabicNumber(_targetCount)}   •   المتبقي ${toArabicNumber(remaining)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFFD4CEC1)
                                          : const Color(0xFF5C655F),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: _TasbihPressButton(
                                    isDark: isDark,
                                    onTap: _incrementTasbih,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _TasbihBeadFlow(
                                  isDark: isDark,
                                  onIncrement: _incrementTasbih,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: 128,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    if (_count > 0) _count--;
                                  });
                                },
                                icon: const Icon(
                                  Icons.remove_rounded,
                                  size: 18,
                                ),
                                label: const Text('إنقاص'),
                              ),
                            ),
                            SizedBox(
                              width: 128,
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() => _count = 0),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text('تصفير'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _incrementTasbih() async {
    setState(() => _count++);
    final canVibrate = await Vibration.hasVibrator();
    if (canVibrate != true) {
      return;
    }
    if (_tapHaptics) {
      await Vibration.vibrate(duration: 50, amplitude: 70);
    }
    if (_goalHaptics && _count == _targetCount) {
      await Vibration.vibrate(duration: 550, amplitude: 255);
    }
  }

  Future<void> _showPhrasePicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedPhrase = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final phrases = _allPhrases;
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'اختر الذكر',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: phrases.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      if (index == phrases.length) {
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: isDark
                              ? const Color(0xFF18242A)
                              : const Color(0xFFF7F1E4),
                          leading: const Icon(Icons.edit_rounded),
                          title: const Text(
                            'إضافة أو تعديل ذكر مخصص',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showTasbihSettings();
                          },
                        );
                      }

                      final phrase = phrases[index];
                      final isSelected = phrase == _selectedPhrase;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF143A2A)
                                : const Color(0xFFE5DDC9),
                          ),
                        ),
                        tileColor: isSelected
                            ? const Color(0x14143A2A)
                            : (isDark ? const Color(0xFF152127) : Colors.white),
                        title: Text(
                          phrase,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF143A2A),
                              )
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(phrase),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        selectedPhrase == null ||
        selectedPhrase == _selectedPhrase) {
      return;
    }

    setState(() {
      _selectedPhrase = selectedPhrase;
      _count = 0;
    });
    await _persistTasbihPreferences();
  }

  Future<void> _showTasbihSettings() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phraseController = TextEditingController(text: _selectedPhrase);
    var sheetTargetCount = _targetCount;
    var sheetTapHaptics = _tapHaptics;
    var sheetGoalHaptics = _goalHaptics;

    Future<void> closeKeyboard() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> saveAndClose() async {
              await closeKeyboard();
              if (!mounted) {
                return;
              }

              final customPhrase = phraseController.text.trim();
              final updatedCustomPhrases = List<String>.from(_customPhrases);
              if (customPhrase.isNotEmpty &&
                  !_defaultPhrases.contains(customPhrase) &&
                  !updatedCustomPhrases.contains(customPhrase)) {
                updatedCustomPhrases.add(customPhrase);
              }

              setState(() {
                _customPhrases = updatedCustomPhrases;
                if (customPhrase.isNotEmpty) {
                  _selectedPhrase = customPhrase;
                }
                _targetCount = sheetTargetCount.clamp(1, 10000);
                _tapHaptics = sheetTapHaptics;
                _goalHaptics = sheetGoalHaptics;
                _count = 0;
              });

              await _persistTasbihPreferences();
              await widget.store?.saveTasbihCustomPhrases(_customPhrases);

              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  18 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'إعدادات السبحة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await closeKeyboard();
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phraseController,
                        textInputAction: TextInputAction.next,
                        onTapOutside: (_) =>
                            FocusScope.of(sheetContext).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'اكتب الذكر',
                          prefixIcon: const Icon(Icons.edit_note_rounded),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF18242A)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF152127)
                              : const Color(0xFFF8F3E7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF26343B)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'الهدف',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setSheetState(() {
                                  sheetTargetCount = (sheetTargetCount - 1)
                                      .clamp(1, 10000);
                                });
                              },
                              icon: const Icon(Icons.remove_rounded),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final next = await _showTargetInputDialog(
                                  sheetContext,
                                  sheetTargetCount,
                                );
                                if (next == null) {
                                  return;
                                }
                                setSheetState(() {
                                  sheetTargetCount = next;
                                });
                              },
                              child: Container(
                                width: 92,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.76),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  toArabicNumber(sheetTargetCount),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFFF2ECDF)
                                        : const Color(0xFF143A2A),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setSheetState(() {
                                  sheetTargetCount = (sheetTargetCount + 1)
                                      .clamp(1, 10000);
                                });
                              },
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        value: sheetTapHaptics,
                        onChanged: (value) {
                          setSheetState(() => sheetTapHaptics = value);
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('هزة خفيفة مع كل ضغطة'),
                      ),
                      SwitchListTile.adaptive(
                        value: sheetGoalHaptics,
                        onChanged: (value) {
                          setSheetState(() => sheetGoalHaptics = value);
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('هزة طويلة عند الوصول للهدف'),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: saveAndClose,
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _showTargetInputDialog(
    BuildContext context,
    int initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue.toString());
    final focusNode = FocusNode();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
        return AlertDialog(
          title: const Text('العدد المستهدف'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: 'اكتب العدد'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed != null) {
                  Navigator.of(dialogContext).pop(parsed.clamp(1, 10000));
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    focusNode.dispose();
    controller.dispose();
    return result;
  }

  Future<void> _persistTasbihPreferences() {
    final store = widget.store;
    if (store == null) {
      return Future.value();
    }
    return store.saveTasbihPreferences(
      phrase: _selectedPhrase,
      target: _targetCount,
      tapHaptics: _tapHaptics,
      goalHaptics: _goalHaptics,
    );
  }
}

class _TasbihPressButton extends StatelessWidget {
  const _TasbihPressButton({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glowColor =
        (isDark ? const Color(0xFF2F6A53) : const Color(0xFFBFA35B)).withValues(
          alpha: 0.35,
        );
    final textColor = isDark
        ? const Color(0xFFEFE8D7)
        : const Color(0xFF143A2A);
    return InkResponse(
      onTap: onTap,
      radius: 70,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isDark
                ? const [Color(0xFF1C2D34), Color(0xFF0F1C20)]
                : const [Color(0xFFF7E7B6), Color(0xFFDBC27B)],
          ),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: 26, spreadRadius: 2),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF35505C) : const Color(0xFFCCB070),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 30, color: textColor),
              const SizedBox(height: 6),
              Text(
                'تسبيح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasbihBeadFlow extends StatefulWidget {
  const _TasbihBeadFlow({required this.isDark, required this.onIncrement});

  final bool isDark;
  final VoidCallback onIncrement;

  @override
  State<_TasbihBeadFlow> createState() => _TasbihBeadFlowState();
}

class _TasbihBeadFlowState extends State<_TasbihBeadFlow>
    with SingleTickerProviderStateMixin {
  static const _barHeight = 62.0;
  static const _beadSize = 22.0;
  static const _beadSpacing = 10.0;

  late final AnimationController _controller;
  _FlowDirection? _direction;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addStatusListener(_handleAnimationStatus);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reset();
      setState(() => _direction = null);
      widget.onIncrement();
    }
  }

  void _triggerFlow(_FlowDirection direction) {
    if (_controller.isAnimating) {
      return;
    }
    setState(() => _direction = direction);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final woodBase = widget.isDark
        ? const Color(0xFF5A3B2E)
        : const Color(0xFFB07A45);
    final woodEdge = widget.isDark
        ? const Color(0xFF3D2A22)
        : const Color(0xFF8C5B2F);
    final woodHighlight = widget.isDark
        ? const Color(0xFFD0A26A)
        : const Color(0xFF7A4A22);

    return SizedBox(
      height: _barHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final gapWidth = (width * 0.18).clamp(28.0, 56.0);
          final sideWidth = (width - gapWidth).clamp(0.0, width) / 2;
          final effectiveSpacing = (sideWidth / 12).clamp(2.0, _beadSpacing);
          final beadCount =
              ((sideWidth + effectiveSpacing) / (_beadSize + effectiveSpacing))
                  .floor()
                  .clamp(1, 10);
          final usedWidth =
              beadCount * _beadSize + (beadCount - 1) * effectiveSpacing;
          final sidePadding = ((sideWidth - usedWidth) / 2).clamp(0.0, 20.0);

          final leftStart = sideWidth - _beadSize;
          final rightStart = sideWidth + gapWidth;
          final moveStart = _direction == _FlowDirection.leftToRight
              ? leftStart
              : rightStart;
          final moveEnd = _direction == _FlowDirection.leftToRight
              ? rightStart
              : leftStart;

          return Stack(
            alignment: Alignment.center,
            children: [
              ClipRect(
                child: SizedBox(
                  width: width,
                  child: Row(
                    children: [
                      Expanded(
                        child: _BeadStrip(
                          padding: sidePadding,
                          beadCount: beadCount,
                          beadSize: _beadSize,
                          beadSpacing: effectiveSpacing,
                          baseColor: woodBase,
                          edgeColor: woodEdge,
                          highlightColor: woodHighlight,
                          onTap: () => _triggerFlow(_FlowDirection.rightToLeft),
                          onDrag: () =>
                              _triggerFlow(_FlowDirection.rightToLeft),
                        ),
                      ),
                      SizedBox(width: gapWidth),
                      Expanded(
                        child: _BeadStrip(
                          padding: sidePadding,
                          beadCount: beadCount,
                          beadSize: _beadSize,
                          beadSpacing: effectiveSpacing,
                          baseColor: woodBase,
                          edgeColor: woodEdge,
                          highlightColor: woodHighlight,
                          onTap: () => _triggerFlow(_FlowDirection.leftToRight),
                          onDrag: () =>
                              _triggerFlow(_FlowDirection.leftToRight),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_direction != null)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(_controller.value);
                    final x = (moveStart + (moveEnd - moveStart) * t).clamp(
                      0.0,
                      width - _beadSize,
                    );
                    return Positioned(
                      left: x,
                      top: (_barHeight - _beadSize) / 2,
                      child: child!,
                    );
                  },
                  child: _Bead(
                    size: _beadSize,
                    baseColor: woodHighlight,
                    edgeColor: woodEdge,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _FlowDirection { leftToRight, rightToLeft }

class _BeadStrip extends StatelessWidget {
  const _BeadStrip({
    required this.padding,
    required this.beadCount,
    required this.beadSize,
    required this.beadSpacing,
    required this.baseColor,
    required this.edgeColor,
    required this.highlightColor,
    required this.onTap,
    required this.onDrag,
  });

  final double padding;
  final int beadCount;
  final double beadSize;
  final double beadSpacing;
  final Color baseColor;
  final Color edgeColor;
  final Color highlightColor;
  final VoidCallback onTap;
  final VoidCallback onDrag;

  @override
  Widget build(BuildContext context) {
    final beadWidgets = <Widget>[];
    for (var i = 0; i < beadCount; i++) {
      if (i > 0) {
        beadWidgets.add(SizedBox(width: beadSpacing));
      }
      final isAccent = i == beadCount ~/ 2;
      beadWidgets.add(
        _Bead(
          size: beadSize,
          baseColor: isAccent ? highlightColor : baseColor,
          edgeColor: edgeColor,
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onHorizontalDragEnd: (_) => onDrag(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: beadWidgets,
        ),
      ),
    );
  }
}

class _Bead extends StatelessWidget {
  const _Bead({
    required this.size,
    required this.baseColor,
    required this.edgeColor,
  });

  final double size;
  final Color baseColor;
  final Color edgeColor;

  @override
  Widget build(BuildContext context) {
    final bead = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            baseColor.withValues(alpha: 0.96),
            edgeColor.withValues(alpha: 0.96),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: edgeColor.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
    return bead;
  }
}
