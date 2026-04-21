import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';

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
  PrayerCity(name: 'القاهرة', governorate: 'القاهرة', coordinates: Coordinates(30.0444, 31.2357)),
  PrayerCity(name: 'حلوان', governorate: 'القاهرة', coordinates: Coordinates(29.8414, 31.3009)),
  PrayerCity(name: 'مدينة نصر', governorate: 'القاهرة', coordinates: Coordinates(30.0561, 31.3306)),
  PrayerCity(name: 'المقطم', governorate: 'القاهرة', coordinates: Coordinates(30.0316, 31.3286)),
  PrayerCity(name: 'المعادي', governorate: 'القاهرة', coordinates: Coordinates(29.9596, 31.2585)),
  PrayerCity(name: 'التجمع الخامس', governorate: 'القاهرة', coordinates: Coordinates(30.0143, 31.4913)),
  PrayerCity(name: 'القاهرة الجديدة', governorate: 'القاهرة', coordinates: Coordinates(30.0300, 31.4700)),
  PrayerCity(name: 'العباسية', governorate: 'القاهرة', coordinates: Coordinates(30.0726, 31.2778)),
  PrayerCity(name: 'شبرا', governorate: 'القاهرة', coordinates: Coordinates(30.0789, 31.2422)),
  PrayerCity(name: 'عين شمس', governorate: 'القاهرة', coordinates: Coordinates(30.1283, 31.3191)),
  PrayerCity(name: 'المرج', governorate: 'القاهرة', coordinates: Coordinates(30.1630, 31.3380)),
  PrayerCity(name: 'المطرية', governorate: 'القاهرة', coordinates: Coordinates(30.1212, 31.3137)),
  PrayerCity(name: 'الزيتون', governorate: 'القاهرة', coordinates: Coordinates(30.1067, 31.3008)),
  PrayerCity(name: 'روض الفرج', governorate: 'القاهرة', coordinates: Coordinates(30.0803, 31.2452)),
  PrayerCity(name: 'السيدة زينب', governorate: 'القاهرة', coordinates: Coordinates(30.0292, 31.2400)),
  PrayerCity(name: 'الازهر', governorate: 'القاهرة', coordinates: Coordinates(30.0456, 31.2620)),
  PrayerCity(name: 'مصر الجديدة', governorate: 'القاهرة', coordinates: Coordinates(30.0913, 31.3366)),
  PrayerCity(name: 'النزهة', governorate: 'القاهرة', coordinates: Coordinates(30.1061, 31.3710)),
  PrayerCity(name: 'مدينتي', governorate: 'القاهرة', coordinates: Coordinates(30.0885, 31.6285)),
  PrayerCity(name: 'مدينة الشروق', governorate: 'القاهرة', coordinates: Coordinates(30.1358, 31.6312)),
  PrayerCity(name: 'بدر', governorate: 'القاهرة', coordinates: Coordinates(30.1436, 31.7178)),
  PrayerCity(name: 'الجيزة', governorate: 'الجيزة', coordinates: Coordinates(30.0131, 31.2089)),
  PrayerCity(name: '6 أكتوبر', governorate: 'الجيزة', coordinates: Coordinates(29.9720, 30.9445)),
  PrayerCity(name: 'الشيخ زايد', governorate: 'الجيزة', coordinates: Coordinates(30.0244, 30.9853)),
  PrayerCity(name: 'الصف', governorate: 'الجيزة', coordinates: Coordinates(29.5647, 31.2817)),
  PrayerCity(name: 'العياط', governorate: 'الجيزة', coordinates: Coordinates(29.6197, 31.2575)),
  PrayerCity(name: 'الإسكندرية', governorate: 'الإسكندرية', coordinates: Coordinates(31.2001, 29.9187)),
  PrayerCity(name: 'برج العرب', governorate: 'الإسكندرية', coordinates: Coordinates(30.8853, 29.5771)),
  PrayerCity(name: 'العلمين', governorate: 'مطروح', coordinates: Coordinates(30.8300, 28.9550)),
  PrayerCity(name: 'مرسى مطروح', governorate: 'مطروح', coordinates: Coordinates(31.3543, 27.2373)),
  PrayerCity(name: 'السلوم', governorate: 'مطروح', coordinates: Coordinates(31.5542, 25.1647)),
  PrayerCity(name: 'سيوة', governorate: 'مطروح', coordinates: Coordinates(29.2032, 25.5197)),
  PrayerCity(name: 'دمنهور', governorate: 'البحيرة', coordinates: Coordinates(31.0341, 30.4682)),
  PrayerCity(name: 'كفر الدوار', governorate: 'البحيرة', coordinates: Coordinates(31.1338, 30.1295)),
  PrayerCity(name: 'رشيد', governorate: 'البحيرة', coordinates: Coordinates(31.4044, 30.4164)),
  PrayerCity(name: 'إدكو', governorate: 'البحيرة', coordinates: Coordinates(31.3077, 30.3005)),
  PrayerCity(name: 'طنطا', governorate: 'الغربية', coordinates: Coordinates(30.7865, 31.0004)),
  PrayerCity(name: 'المحلة الكبرى', governorate: 'الغربية', coordinates: Coordinates(30.9697, 31.1669)),
  PrayerCity(name: 'زفتى', governorate: 'الغربية', coordinates: Coordinates(30.7145, 31.2442)),
  PrayerCity(name: 'شبين الكوم', governorate: 'المنوفية', coordinates: Coordinates(30.5539, 31.0096)),
  PrayerCity(name: 'مدينة السادات', governorate: 'المنوفية', coordinates: Coordinates(30.3604, 30.5332)),
  PrayerCity(name: 'منوف', governorate: 'المنوفية', coordinates: Coordinates(30.4658, 30.9305)),
  PrayerCity(name: 'بنها', governorate: 'القليوبية', coordinates: Coordinates(30.4668, 31.1848)),
  PrayerCity(name: 'شبرا الخيمة', governorate: 'القليوبية', coordinates: Coordinates(30.1241, 31.2609)),
  PrayerCity(name: 'القناطر الخيرية', governorate: 'القليوبية', coordinates: Coordinates(30.1933, 31.1335)),
  PrayerCity(name: 'العبور', governorate: 'القليوبية', coordinates: Coordinates(30.2282, 31.4597)),
  PrayerCity(name: 'الزقازيق', governorate: 'الشرقية', coordinates: Coordinates(30.5877, 31.5020)),
  PrayerCity(name: 'بلبيس', governorate: 'الشرقية', coordinates: Coordinates(30.4204, 31.5622)),
  PrayerCity(name: 'العاشر من رمضان', governorate: 'الشرقية', coordinates: Coordinates(30.2924, 31.7420)),
  PrayerCity(name: 'فاقوس', governorate: 'الشرقية', coordinates: Coordinates(30.7282, 31.7964)),
  PrayerCity(name: 'المنصورة', governorate: 'الدقهلية', coordinates: Coordinates(31.0409, 31.3785)),
  PrayerCity(name: 'ميت غمر', governorate: 'الدقهلية', coordinates: Coordinates(30.7167, 31.2589)),
  PrayerCity(name: 'المنزلة', governorate: 'الدقهلية', coordinates: Coordinates(31.1591, 31.9348)),
  PrayerCity(name: 'دمياط', governorate: 'دمياط', coordinates: Coordinates(31.4175, 31.8144)),
  PrayerCity(name: 'رأس البر', governorate: 'دمياط', coordinates: Coordinates(31.5091, 31.8425)),
  PrayerCity(name: 'فارسكور', governorate: 'دمياط', coordinates: Coordinates(31.3298, 31.7151)),
  PrayerCity(name: 'كفر الشيخ', governorate: 'كفر الشيخ', coordinates: Coordinates(31.1117, 30.9399)),
  PrayerCity(name: 'دسوق', governorate: 'كفر الشيخ', coordinates: Coordinates(31.1325, 30.6478)),
  PrayerCity(name: 'بلطيم', governorate: 'كفر الشيخ', coordinates: Coordinates(31.5634, 31.0901)),
  PrayerCity(name: 'بورسعيد', governorate: 'بورسعيد', coordinates: Coordinates(31.2653, 32.3019)),
  PrayerCity(name: 'بورفؤاد', governorate: 'بورسعيد', coordinates: Coordinates(31.2529, 32.3167)),
  PrayerCity(name: 'الإسماعيلية', governorate: 'الإسماعيلية', coordinates: Coordinates(30.5965, 32.2715)),
  PrayerCity(name: 'فايد', governorate: 'الإسماعيلية', coordinates: Coordinates(30.3262, 32.3084)),
  PrayerCity(name: 'القنطرة شرق', governorate: 'الإسماعيلية', coordinates: Coordinates(30.8500, 32.3167)),
  PrayerCity(name: 'السويس', governorate: 'السويس', coordinates: Coordinates(29.9668, 32.5498)),
  PrayerCity(name: 'العين السخنة', governorate: 'السويس', coordinates: Coordinates(29.6000, 32.3500)),
  PrayerCity(name: 'العريش', governorate: 'شمال سيناء', coordinates: Coordinates(31.1313, 33.7984)),
  PrayerCity(name: 'الشيخ زويد', governorate: 'شمال سيناء', coordinates: Coordinates(31.2156, 34.1108)),
  PrayerCity(name: 'رفح', governorate: 'شمال سيناء', coordinates: Coordinates(31.2800, 34.2400)),
  PrayerCity(name: 'الطور', governorate: 'جنوب سيناء', coordinates: Coordinates(28.2417, 33.6222)),
  PrayerCity(name: 'شرم الشيخ', governorate: 'جنوب سيناء', coordinates: Coordinates(27.9158, 34.3300)),
  PrayerCity(name: 'دهب', governorate: 'جنوب سيناء', coordinates: Coordinates(28.5091, 34.5136)),
  PrayerCity(name: 'نويبع', governorate: 'جنوب سيناء', coordinates: Coordinates(29.0444, 34.6634)),
  PrayerCity(name: 'طابا', governorate: 'جنوب سيناء', coordinates: Coordinates(29.4925, 34.8969)),
  PrayerCity(name: 'بني سويف', governorate: 'بني سويف', coordinates: Coordinates(29.0661, 31.0994)),
  PrayerCity(name: 'الواسطى', governorate: 'بني سويف', coordinates: Coordinates(29.3378, 31.2067)),
  PrayerCity(name: 'الفشن', governorate: 'بني سويف', coordinates: Coordinates(28.8243, 30.8990)),
  PrayerCity(name: 'الفيوم', governorate: 'الفيوم', coordinates: Coordinates(29.3084, 30.8428)),
  PrayerCity(name: 'سنورس', governorate: 'الفيوم', coordinates: Coordinates(29.4070, 30.8662)),
  PrayerCity(name: 'طامية', governorate: 'الفيوم', coordinates: Coordinates(29.4764, 30.9612)),
  PrayerCity(name: 'المنيا', governorate: 'المنيا', coordinates: Coordinates(28.0871, 30.7618)),
  PrayerCity(name: 'ملوي', governorate: 'المنيا', coordinates: Coordinates(27.7314, 30.8428)),
  PrayerCity(name: 'سمالوط', governorate: 'المنيا', coordinates: Coordinates(28.3121, 30.7104)),
  PrayerCity(name: 'أسيوط', governorate: 'أسيوط', coordinates: Coordinates(27.1809, 31.1837)),
  PrayerCity(name: 'ديروط', governorate: 'أسيوط', coordinates: Coordinates(27.5544, 30.8089)),
  PrayerCity(name: 'منفلوط', governorate: 'أسيوط', coordinates: Coordinates(27.3111, 30.9697)),
  PrayerCity(name: 'سوهاج', governorate: 'سوهاج', coordinates: Coordinates(26.5569, 31.6948)),
  PrayerCity(name: 'جرجا', governorate: 'سوهاج', coordinates: Coordinates(26.3383, 31.8931)),
  PrayerCity(name: 'طهطا', governorate: 'سوهاج', coordinates: Coordinates(26.7693, 31.4971)),
  PrayerCity(name: 'قنا', governorate: 'قنا', coordinates: Coordinates(26.1551, 32.7160)),
  PrayerCity(name: 'نجع حمادي', governorate: 'قنا', coordinates: Coordinates(26.0495, 32.2414)),
  PrayerCity(name: 'قفط', governorate: 'قنا', coordinates: Coordinates(25.9994, 32.8278)),
  PrayerCity(name: 'الأقصر', governorate: 'الأقصر', coordinates: Coordinates(25.6872, 32.6396)),
  PrayerCity(name: 'إسنا', governorate: 'الأقصر', coordinates: Coordinates(25.2934, 32.5540)),
  PrayerCity(name: 'أرمنت', governorate: 'الأقصر', coordinates: Coordinates(25.6196, 32.5390)),
  PrayerCity(name: 'أسوان', governorate: 'أسوان', coordinates: Coordinates(24.0889, 32.8998)),
  PrayerCity(name: 'كوم أمبو', governorate: 'أسوان', coordinates: Coordinates(24.4706, 32.9463)),
  PrayerCity(name: 'إدفو', governorate: 'أسوان', coordinates: Coordinates(24.9785, 32.8740)),
  PrayerCity(name: 'أبو سمبل', governorate: 'أسوان', coordinates: Coordinates(22.3372, 31.6258)),
  PrayerCity(name: 'الغردقة', governorate: 'البحر الأحمر', coordinates: Coordinates(27.2579, 33.8116)),
  PrayerCity(name: 'رأس غارب', governorate: 'البحر الأحمر', coordinates: Coordinates(28.3569, 33.0783)),
  PrayerCity(name: 'سفاجا', governorate: 'البحر الأحمر', coordinates: Coordinates(26.7442, 33.9389)),
  PrayerCity(name: 'القصير', governorate: 'البحر الأحمر', coordinates: Coordinates(26.1043, 34.2779)),
  PrayerCity(name: 'مرسى علم', governorate: 'البحر الأحمر', coordinates: Coordinates(25.0676, 34.8789)),
  PrayerCity(name: 'الخارجة', governorate: 'الوادي الجديد', coordinates: Coordinates(25.4380, 30.5464)),
  PrayerCity(name: 'الداخلة', governorate: 'الوادي الجديد', coordinates: Coordinates(25.4900, 28.9700)),
  PrayerCity(name: 'الفرافرة', governorate: 'الوادي الجديد', coordinates: Coordinates(27.0568, 27.9698)),
];

const worldPrayerCities = <PrayerCity>[
  PrayerCity(name: 'مكة', governorate: 'السعودية', coordinates: Coordinates(21.3891, 39.8579), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'المدينة المنورة', governorate: 'السعودية', coordinates: Coordinates(24.5247, 39.5692), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'الرياض', governorate: 'السعودية', coordinates: Coordinates(24.7136, 46.6753), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'جدة', governorate: 'السعودية', coordinates: Coordinates(21.5433, 39.1728), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'الدمام', governorate: 'السعودية', coordinates: Coordinates(26.4207, 50.0888), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'القدس', governorate: 'فلسطين', coordinates: Coordinates(31.7683, 35.2137)),
  PrayerCity(name: 'غزة', governorate: 'فلسطين', coordinates: Coordinates(31.5017, 34.4668)),
  PrayerCity(name: 'عمان', governorate: 'الأردن', coordinates: Coordinates(31.9539, 35.9106)),
  PrayerCity(name: 'إربد', governorate: 'الأردن', coordinates: Coordinates(32.5568, 35.8479)),
  PrayerCity(name: 'دمشق', governorate: 'سوريا', coordinates: Coordinates(33.5138, 36.2765)),
  PrayerCity(name: 'حلب', governorate: 'سوريا', coordinates: Coordinates(36.2021, 37.1343)),
  PrayerCity(name: 'بيروت', governorate: 'لبنان', coordinates: Coordinates(33.8938, 35.5018)),
  PrayerCity(name: 'طرابلس', governorate: 'لبنان', coordinates: Coordinates(34.4335, 35.8442)),
  PrayerCity(name: 'بغداد', governorate: 'العراق', coordinates: Coordinates(33.3152, 44.3661)),
  PrayerCity(name: 'أربيل', governorate: 'العراق', coordinates: Coordinates(36.1911, 44.0092)),
  PrayerCity(name: 'الدوحة', governorate: 'قطر', coordinates: Coordinates(25.2854, 51.5310), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'دبي', governorate: 'الإمارات', coordinates: Coordinates(25.2048, 55.2708), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'أبوظبي', governorate: 'الإمارات', coordinates: Coordinates(24.4539, 54.3773), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'الشارقة', governorate: 'الإمارات', coordinates: Coordinates(25.3463, 55.4209), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'الكويت', governorate: 'الكويت', coordinates: Coordinates(29.3759, 47.9774), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'المنامة', governorate: 'البحرين', coordinates: Coordinates(26.2235, 50.5876), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'مسقط', governorate: 'عمان', coordinates: Coordinates(23.5880, 58.3829), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'صنعاء', governorate: 'اليمن', coordinates: Coordinates(15.3694, 44.1910), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'عدن', governorate: 'اليمن', coordinates: Coordinates(12.7855, 45.0187), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'إسطنبول', governorate: 'تركيا', coordinates: Coordinates(41.0082, 28.9784)),
  PrayerCity(name: 'أنقرة', governorate: 'تركيا', coordinates: Coordinates(39.9334, 32.8597)),
  PrayerCity(name: 'طرابلس', governorate: 'ليبيا', coordinates: Coordinates(32.8872, 13.1913)),
  PrayerCity(name: 'بنغازي', governorate: 'ليبيا', coordinates: Coordinates(32.1167, 20.0667)),
  PrayerCity(name: 'تونس', governorate: 'تونس', coordinates: Coordinates(36.8065, 10.1815)),
  PrayerCity(name: 'صفاقس', governorate: 'تونس', coordinates: Coordinates(34.7406, 10.7603)),
  PrayerCity(name: 'الجزائر', governorate: 'الجزائر', coordinates: Coordinates(36.7538, 3.0588)),
  PrayerCity(name: 'وهران', governorate: 'الجزائر', coordinates: Coordinates(35.6981, -0.6348)),
  PrayerCity(name: 'الرباط', governorate: 'المغرب', coordinates: Coordinates(34.0209, -6.8416)),
  PrayerCity(name: 'الدار البيضاء', governorate: 'المغرب', coordinates: Coordinates(33.5731, -7.5898)),
  PrayerCity(name: 'مراكش', governorate: 'المغرب', coordinates: Coordinates(31.6295, -7.9811)),
  PrayerCity(name: 'الخرطوم', governorate: 'السودان', coordinates: Coordinates(15.5007, 32.5599)),
  PrayerCity(name: 'أم درمان', governorate: 'السودان', coordinates: Coordinates(15.6445, 32.4777)),
  PrayerCity(name: 'نواكشوط', governorate: 'موريتانيا', coordinates: Coordinates(18.0735, -15.9582)),
  PrayerCity(name: 'جاكرتا', governorate: 'إندونيسيا', coordinates: Coordinates(-6.2088, 106.8456)),
  PrayerCity(name: 'كوالالمبور', governorate: 'ماليزيا', coordinates: Coordinates(3.1390, 101.6869)),
  PrayerCity(name: 'إسلام آباد', governorate: 'باكستان', coordinates: Coordinates(33.6844, 73.0479)),
  PrayerCity(name: 'كراتشي', governorate: 'باكستان', coordinates: Coordinates(24.8607, 67.0011)),
  PrayerCity(name: 'لاهور', governorate: 'باكستان', coordinates: Coordinates(31.5204, 74.3587)),
  PrayerCity(name: 'دكا', governorate: 'بنغلاديش', coordinates: Coordinates(23.8103, 90.4125)),
  PrayerCity(name: 'نيودلهي', governorate: 'الهند', coordinates: Coordinates(28.6139, 77.2090)),
  PrayerCity(name: 'مومباي', governorate: 'الهند', coordinates: Coordinates(19.0760, 72.8777)),
  PrayerCity(name: 'لندن', governorate: 'المملكة المتحدة', coordinates: Coordinates(51.5072, -0.1276)),
  PrayerCity(name: 'برمنغهام', governorate: 'المملكة المتحدة', coordinates: Coordinates(52.4862, -1.8904)),
  PrayerCity(name: 'باريس', governorate: 'فرنسا', coordinates: Coordinates(48.8566, 2.3522)),
  PrayerCity(name: 'برلين', governorate: 'ألمانيا', coordinates: Coordinates(52.5200, 13.4050)),
  PrayerCity(name: 'روما', governorate: 'إيطاليا', coordinates: Coordinates(41.9028, 12.4964)),
  PrayerCity(name: 'مدريد', governorate: 'إسبانيا', coordinates: Coordinates(40.4168, -3.7038)),
  PrayerCity(name: 'نيويورك', governorate: 'الولايات المتحدة', coordinates: Coordinates(40.7128, -74.0060)),
  PrayerCity(name: 'واشنطن', governorate: 'الولايات المتحدة', coordinates: Coordinates(38.9072, -77.0369)),
  PrayerCity(name: 'شيكاغو', governorate: 'الولايات المتحدة', coordinates: Coordinates(41.8781, -87.6298)),
  PrayerCity(name: 'تورونتو', governorate: 'كندا', coordinates: Coordinates(43.6532, -79.3832)),
  PrayerCity(name: 'مونتريال', governorate: 'كندا', coordinates: Coordinates(45.5019, -73.5674)),
  PrayerCity(name: 'ساو باولو', governorate: 'البرازيل', coordinates: Coordinates(-23.5558, -46.6396)),
  PrayerCity(name: 'مكسيكو سيتي', governorate: 'المكسيك', coordinates: Coordinates(19.4326, -99.1332)),
  PrayerCity(name: 'كيب تاون', governorate: 'جنوب أفريقيا', coordinates: Coordinates(-33.9249, 18.4241)),
  PrayerCity(name: 'جوهانسبرغ', governorate: 'جنوب أفريقيا', coordinates: Coordinates(-26.2041, 28.0473)),
  PrayerCity(name: 'سيدني', governorate: 'أستراليا', coordinates: Coordinates(-33.8688, 151.2093)),
  PrayerCity(name: 'ملبورن', governorate: 'أستراليا', coordinates: Coordinates(-37.8136, 144.9631)),
];

const prayerCities = <PrayerCity>[
  ...egyptPrayerCities,
  ...worldPrayerCities,
];

PrayerCity resolvePrayerCityByName(String? cityName) {
  if (cityName == null || cityName.trim().isEmpty) {
    return prayerCities.first;
  }
  final normalized = _normalizePrayerCityName(cityName);
  for (final city in prayerCities) {
    if (_normalizePrayerCityName(city.name) == normalized) {
      return city;
    }
  }
  return prayerCities.first;
}

PrayerCity nearestPrayerCity(double latitude, double longitude) {
  final scopedCities = _isLikelyInsideEgyptBounds(latitude, longitude)
      ? egyptPrayerCities
      : prayerCities;
  var result = scopedCities.first;
  var minDistance = double.infinity;
  for (final city in scopedCities) {
    final distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      city.coordinates.latitude,
      city.coordinates.longitude,
    );
    if (distance < minDistance) {
      minDistance = distance;
      result = city;
    }
  }
  return result;
}

bool _isLikelyInsideEgyptBounds(double latitude, double longitude) {
  const minLat = 21.4;
  const maxLat = 31.8;
  const minLon = 24.5;
  const maxLon = 37.2;
  return latitude >= minLat &&
      latitude <= maxLat &&
      longitude >= minLon &&
      longitude <= maxLon;
}

String _normalizePrayerCityName(String value) {
  return value
      .trim()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .toLowerCase();
}

extension PrayerCityMethodX on PrayerCityMethod {
  CalculationParameters get parameters => switch (this) {
    PrayerCityMethod.egyptian => CalculationMethodParameters.egyptian(),
    PrayerCityMethod.ummAlQura => CalculationMethodParameters.ummAlQura(),
  };
}
