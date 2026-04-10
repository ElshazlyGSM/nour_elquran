String toArabicNumber(int number) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();

  for (final char in number.toString().split('')) {
    final index = western.indexOf(char);
    buffer.write(index == -1 ? char : eastern[index]);
  }

  return buffer.toString();
}
