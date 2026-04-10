import 'package:adhan_dart/adhan_dart.dart';

enum PrayerCityMethod { egyptian, ummAlQura }

class PrayerCity {
  const PrayerCity({
    required this.name,
    required this.governorate,
    required this.coordinates,
    this.method = PrayerCityMethod.egyptian,
  });

  final String name;
  final String governorate;
  final Coordinates coordinates;
  final PrayerCityMethod method;
}

const egyptPrayerCities = <PrayerCity>[
  PrayerCity(
    name: 'القاهرة',
    governorate: 'القاهرة',
    coordinates: Coordinates(30.0444, 31.2357),
  ),
  PrayerCity(
    name: 'الجيزة',
    governorate: 'الجيزة',
    coordinates: Coordinates(30.0131, 31.2089),
  ),
  PrayerCity(
    name: 'الإسكندرية',
    governorate: 'الإسكندرية',
    coordinates: Coordinates(31.2001, 29.9187),
  ),
  PrayerCity(
    name: 'بورسعيد',
    governorate: 'بورسعيد',
    coordinates: Coordinates(31.2653, 32.3019),
  ),
  PrayerCity(
    name: 'السويس',
    governorate: 'السويس',
    coordinates: Coordinates(29.9668, 32.5498),
  ),
  PrayerCity(
    name: 'دمياط',
    governorate: 'دمياط',
    coordinates: Coordinates(31.4175, 31.8144),
  ),
  PrayerCity(
    name: 'المنصورة',
    governorate: 'الدقهلية',
    coordinates: Coordinates(31.0409, 31.3785),
  ),
  PrayerCity(
    name: 'الزقازيق',
    governorate: 'الشرقية',
    coordinates: Coordinates(30.5877, 31.5020),
  ),
  PrayerCity(
    name: 'بنها',
    governorate: 'القليوبية',
    coordinates: Coordinates(30.4668, 31.1848),
  ),
  PrayerCity(
    name: 'شبين الكوم',
    governorate: 'المنوفية',
    coordinates: Coordinates(30.5539, 31.0096),
  ),
  PrayerCity(
    name: 'طنطا',
    governorate: 'الغربية',
    coordinates: Coordinates(30.7865, 31.0004),
  ),
  PrayerCity(
    name: 'كفر الشيخ',
    governorate: 'كفر الشيخ',
    coordinates: Coordinates(31.1117, 30.9399),
  ),
  PrayerCity(
    name: 'دمنهور',
    governorate: 'البحيرة',
    coordinates: Coordinates(31.0341, 30.4682),
  ),
  PrayerCity(
    name: 'الإسماعيلية',
    governorate: 'الإسماعيلية',
    coordinates: Coordinates(30.5965, 32.2715),
  ),
  PrayerCity(
    name: 'العريش',
    governorate: 'شمال سيناء',
    coordinates: Coordinates(31.1313, 33.7984),
  ),
  PrayerCity(
    name: 'الطور',
    governorate: 'جنوب سيناء',
    coordinates: Coordinates(28.2417, 33.6222),
  ),
  PrayerCity(
    name: 'بني سويف',
    governorate: 'بني سويف',
    coordinates: Coordinates(29.0661, 31.0994),
  ),
  PrayerCity(
    name: 'الفيوم',
    governorate: 'الفيوم',
    coordinates: Coordinates(29.3084, 30.8428),
  ),
  PrayerCity(
    name: 'المنيا',
    governorate: 'المنيا',
    coordinates: Coordinates(28.0871, 30.7618),
  ),
  PrayerCity(
    name: 'أسيوط',
    governorate: 'أسيوط',
    coordinates: Coordinates(27.1809, 31.1837),
  ),
  PrayerCity(
    name: 'سوهاج',
    governorate: 'سوهاج',
    coordinates: Coordinates(26.5569, 31.6948),
  ),
  PrayerCity(
    name: 'قنا',
    governorate: 'قنا',
    coordinates: Coordinates(26.1551, 32.7160),
  ),
  PrayerCity(
    name: 'الأقصر',
    governorate: 'الأقصر',
    coordinates: Coordinates(25.6872, 32.6396),
  ),
  PrayerCity(
    name: 'أسوان',
    governorate: 'أسوان',
    coordinates: Coordinates(24.0889, 32.8998),
  ),
  PrayerCity(
    name: 'مرسى مطروح',
    governorate: 'مطروح',
    coordinates: Coordinates(31.3543, 27.2373),
  ),
  PrayerCity(
    name: 'الغردقة',
    governorate: 'البحر الأحمر',
    coordinates: Coordinates(27.2579, 33.8116),
  ),
  PrayerCity(
    name: 'الخارجة',
    governorate: 'الوادي الجديد',
    coordinates: Coordinates(25.4380, 30.5464),
  ),
];

extension PrayerCityMethodX on PrayerCityMethod {
  CalculationParameters get parameters => switch (this) {
    PrayerCityMethod.egyptian => CalculationMethodParameters.egyptian(),
    PrayerCityMethod.ummAlQura => CalculationMethodParameters.ummAlQura(),
  };
}
