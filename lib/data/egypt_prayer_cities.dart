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
  PrayerCity(name: 'الجيزة', governorate: 'الجيزة', coordinates: Coordinates(30.0131, 31.2089)),
  PrayerCity(name: 'الإسكندرية', governorate: 'الإسكندرية', coordinates: Coordinates(31.2001, 29.9187)),
  PrayerCity(name: 'بورسعيد', governorate: 'بورسعيد', coordinates: Coordinates(31.2653, 32.3019)),
  PrayerCity(name: 'السويس', governorate: 'السويس', coordinates: Coordinates(29.9668, 32.5498)),
  PrayerCity(name: 'دمياط', governorate: 'دمياط', coordinates: Coordinates(31.4175, 31.8144)),
  PrayerCity(name: 'المنصورة', governorate: 'الدقهلية', coordinates: Coordinates(31.0409, 31.3785)),
  PrayerCity(name: 'الزقازيق', governorate: 'الشرقية', coordinates: Coordinates(30.5877, 31.5020)),
  PrayerCity(name: 'بنها', governorate: 'القليوبية', coordinates: Coordinates(30.4668, 31.1848)),
  PrayerCity(name: 'شبين الكوم', governorate: 'المنوفية', coordinates: Coordinates(30.5539, 31.0096)),
  PrayerCity(name: 'طنطا', governorate: 'الغربية', coordinates: Coordinates(30.7865, 31.0004)),
  PrayerCity(name: 'كفر الشيخ', governorate: 'كفر الشيخ', coordinates: Coordinates(31.1117, 30.9399)),
  PrayerCity(name: 'دمنهور', governorate: 'البحيرة', coordinates: Coordinates(31.0341, 30.4682)),
  PrayerCity(name: 'الإسماعيلية', governorate: 'الإسماعيلية', coordinates: Coordinates(30.5965, 32.2715)),
  PrayerCity(name: 'العريش', governorate: 'شمال سيناء', coordinates: Coordinates(31.1313, 33.7984)),
  PrayerCity(name: 'الطور', governorate: 'جنوب سيناء', coordinates: Coordinates(28.2417, 33.6222)),
  PrayerCity(name: 'بني سويف', governorate: 'بني سويف', coordinates: Coordinates(29.0661, 31.0994)),
  PrayerCity(name: 'الفيوم', governorate: 'الفيوم', coordinates: Coordinates(29.3084, 30.8428)),
  PrayerCity(name: 'المنيا', governorate: 'المنيا', coordinates: Coordinates(28.0871, 30.7618)),
  PrayerCity(name: 'أسيوط', governorate: 'أسيوط', coordinates: Coordinates(27.1809, 31.1837)),
  PrayerCity(name: 'سوهاج', governorate: 'سوهاج', coordinates: Coordinates(26.5569, 31.6948)),
  PrayerCity(name: 'قنا', governorate: 'قنا', coordinates: Coordinates(26.1551, 32.7160)),
  PrayerCity(name: 'الأقصر', governorate: 'الأقصر', coordinates: Coordinates(25.6872, 32.6396)),
  PrayerCity(name: 'أسوان', governorate: 'أسوان', coordinates: Coordinates(24.0889, 32.8998)),
  PrayerCity(name: 'مرسى مطروح', governorate: 'مطروح', coordinates: Coordinates(31.3543, 27.2373)),
  PrayerCity(name: 'الغردقة', governorate: 'البحر الأحمر', coordinates: Coordinates(27.2579, 33.8116)),
  PrayerCity(name: 'الخارجة', governorate: 'الوادي الجديد', coordinates: Coordinates(25.4380, 30.5464)),
];

const worldPrayerCities = <PrayerCity>[
  PrayerCity(name: 'مكة', governorate: 'السعودية', coordinates: Coordinates(21.3891, 39.8579), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'المدينة المنورة', governorate: 'السعودية', coordinates: Coordinates(24.5247, 39.5692), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'الرياض', governorate: 'السعودية', coordinates: Coordinates(24.7136, 46.6753), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'جدة', governorate: 'السعودية', coordinates: Coordinates(21.5433, 39.1728), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'القدس', governorate: 'فلسطين', coordinates: Coordinates(31.7683, 35.2137)),
  PrayerCity(name: 'عمان', governorate: 'الأردن', coordinates: Coordinates(31.9539, 35.9106)),
  PrayerCity(name: 'دمشق', governorate: 'سوريا', coordinates: Coordinates(33.5138, 36.2765)),
  PrayerCity(name: 'بيروت', governorate: 'لبنان', coordinates: Coordinates(33.8938, 35.5018)),
  PrayerCity(name: 'بغداد', governorate: 'العراق', coordinates: Coordinates(33.3152, 44.3661)),
  PrayerCity(name: 'الدوحة', governorate: 'قطر', coordinates: Coordinates(25.2854, 51.5310), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'دبي', governorate: 'الإمارات', coordinates: Coordinates(25.2048, 55.2708), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'أبوظبي', governorate: 'الإمارات', coordinates: Coordinates(24.4539, 54.3773), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'الكويت', governorate: 'الكويت', coordinates: Coordinates(29.3759, 47.9774), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'المنامة', governorate: 'البحرين', coordinates: Coordinates(26.2235, 50.5876), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'مسقط', governorate: 'عمان', coordinates: Coordinates(23.5880, 58.3829), method: PrayerCityMethod.ummAlQura),
  PrayerCity(name: 'إسطنبول', governorate: 'تركيا', coordinates: Coordinates(41.0082, 28.9784)),
  PrayerCity(name: 'أنقرة', governorate: 'تركيا', coordinates: Coordinates(39.9334, 32.8597)),
  PrayerCity(name: 'طرابلس', governorate: 'ليبيا', coordinates: Coordinates(32.8872, 13.1913)),
  PrayerCity(name: 'تونس', governorate: 'تونس', coordinates: Coordinates(36.8065, 10.1815)),
  PrayerCity(name: 'الجزائر', governorate: 'الجزائر', coordinates: Coordinates(36.7538, 3.0588)),
  PrayerCity(name: 'الرباط', governorate: 'المغرب', coordinates: Coordinates(34.0209, -6.8416)),
  PrayerCity(name: 'الدار البيضاء', governorate: 'المغرب', coordinates: Coordinates(33.5731, -7.5898)),
  PrayerCity(name: 'الخرطوم', governorate: 'السودان', coordinates: Coordinates(15.5007, 32.5599)),
  PrayerCity(name: 'نواكشوط', governorate: 'موريتانيا', coordinates: Coordinates(18.0735, -15.9582)),
  PrayerCity(name: 'جاكرتا', governorate: 'إندونيسيا', coordinates: Coordinates(-6.2088, 106.8456)),
  PrayerCity(name: 'كوالالمبور', governorate: 'ماليزيا', coordinates: Coordinates(3.1390, 101.6869)),
  PrayerCity(name: 'إسلام آباد', governorate: 'باكستان', coordinates: Coordinates(33.6844, 73.0479)),
  PrayerCity(name: 'كراتشي', governorate: 'باكستان', coordinates: Coordinates(24.8607, 67.0011)),
  PrayerCity(name: 'دكا', governorate: 'بنغلاديش', coordinates: Coordinates(23.8103, 90.4125)),
  PrayerCity(name: 'نيودلهي', governorate: 'الهند', coordinates: Coordinates(28.6139, 77.2090)),
  PrayerCity(name: 'مومباي', governorate: 'الهند', coordinates: Coordinates(19.0760, 72.8777)),
  PrayerCity(name: 'لندن', governorate: 'المملكة المتحدة', coordinates: Coordinates(51.5072, -0.1276)),
  PrayerCity(name: 'باريس', governorate: 'فرنسا', coordinates: Coordinates(48.8566, 2.3522)),
  PrayerCity(name: 'برلين', governorate: 'ألمانيا', coordinates: Coordinates(52.5200, 13.4050)),
  PrayerCity(name: 'روما', governorate: 'إيطاليا', coordinates: Coordinates(41.9028, 12.4964)),
  PrayerCity(name: 'مدريد', governorate: 'إسبانيا', coordinates: Coordinates(40.4168, -3.7038)),
  PrayerCity(name: 'نيويورك', governorate: 'الولايات المتحدة', coordinates: Coordinates(40.7128, -74.0060)),
  PrayerCity(name: 'واشنطن', governorate: 'الولايات المتحدة', coordinates: Coordinates(38.9072, -77.0369)),
  PrayerCity(name: 'تورونتو', governorate: 'كندا', coordinates: Coordinates(43.6532, -79.3832)),
  PrayerCity(name: 'ساو باولو', governorate: 'البرازيل', coordinates: Coordinates(-23.5558, -46.6396)),
  PrayerCity(name: 'مكسيكو سيتي', governorate: 'المكسيك', coordinates: Coordinates(19.4326, -99.1332)),
  PrayerCity(name: 'كيب تاون', governorate: 'جنوب أفريقيا', coordinates: Coordinates(-33.9249, 18.4241)),
  PrayerCity(name: 'سيدني', governorate: 'أستراليا', coordinates: Coordinates(-33.8688, 151.2093)),
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
  var result = prayerCities.first;
  var minDistance = double.infinity;
  for (final city in prayerCities) {
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
