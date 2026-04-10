class TafsirOption {
  const TafsirOption({
    required this.id,
    required this.name,
    required this.author,
  });

  final int id;
  final String name;
  final String author;

  static const muyassar = TafsirOption(
    id: 16,
    name: 'التفسير الميسر',
    author: 'الميسر',
  );

  static const ibnKathir = TafsirOption(
    id: 14,
    name: 'تفسير ابن كثير',
    author: 'ابن كثير',
  );

  static const saadi = TafsirOption(
    id: 91,
    name: 'تفسير السعدي',
    author: 'السعدي',
  );

  static const values = [muyassar, ibnKathir, saadi];
}
