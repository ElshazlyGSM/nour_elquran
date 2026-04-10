class SalawatFormula {
  const SalawatFormula({
    required this.title,
    required this.text,
    this.note,
  });

  final String title;
  final String text;
  final String? note;

  factory SalawatFormula.fromJson(Map<String, dynamic> json) {
    return SalawatFormula(
      title: (json['title'] ?? '').toString().trim(),
      text: (json['text'] ?? '').toString().trim(),
      note: json['note']?.toString().trim(),
    );
  }
}

const fallbackSalawatFormulas = <SalawatFormula>[
  SalawatFormula(
    title: 'الصيغة الأولى',
    text:
        'اكتب هنا صيغة الصلاة والسلام الأولى.\nيمكنك إضافة أكثر من سطر حسب الحاجة.',
  ),
  SalawatFormula(
    title: 'الصيغة الثانية',
    text:
        'اكتب هنا صيغة الصلاة والسلام الثانية.\nيمكنك نسخها ولصقها كما تريد.',
  ),
];
