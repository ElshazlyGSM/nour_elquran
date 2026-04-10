import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  double? _qiblaBearing;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQiblaBearing();
  }

  Future<void> _loadQiblaBearing() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('خدمة الموقع متوقفة');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('لم يتم منح إذن الموقع');
      }

      final position = await Geolocator.getCurrentPosition();
      final bearing = _calculateQiblaBearing(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _qiblaBearing = bearing;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  double _calculateQiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    const kaabaLatitude = 21.4225;
    const kaabaLongitude = 39.8262;

    final lat1 = latitude * math.pi / 180;
    final lat2 = kaabaLatitude * math.pi / 180;
    final deltaLon = (kaabaLongitude - longitude) * math.pi / 180;

    final y = math.sin(deltaLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه القبلة'),
        backgroundColor: const Color(0xFF143A2A),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final compassSize = shortestSide.clamp(180.0, 240.0);
          final innerCircleSize = compassSize * 0.79;
          final arrowSize = compassSize * 0.49;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: _isLoading
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 14),
                          Text('جارٍ تحديد اتجاه القبلة...'),
                        ],
                      )
                    : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_off_rounded,
                            size: 64,
                            color: Color(0xFF9B6A2E),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadQiblaBearing,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      )
                    : StreamBuilder<CompassEvent>(
                        stream: FlutterCompass.events?.handleError((_) {}),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const _CompassMessage(
                              icon: Icons.sync_problem_rounded,
                              text:
                                  'البوصلة تحتاج تشغيل التطبيق من جديد تشغيلًا كاملًا، وليس Hot Reload.',
                            );
                          }

                          final heading = snapshot.data?.heading;
                          if (heading == null) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CompassMessage(
                                  icon: Icons.explore_off_rounded,
                                  text:
                                      'هذا الجهاز لا يوفّر حساس اتجاه مناسبًا الآن.\nاتجاه القبلة التقريبي: ${(_qiblaBearing ?? 0).toStringAsFixed(0)}°',
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _loadQiblaBearing,
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            );
                          }

                          final arrowAngle =
                              (((_qiblaBearing ?? 0) - heading) *
                              math.pi /
                              180);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: compassSize,
                                height: compassSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF8F3E7),
                                  border: Border.all(
                                    color: const Color(0xFF143A2A),
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: innerCircleSize,
                                      height: innerCircleSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0x22143A2A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    const Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 18),
                                        child: Text(
                                          'شمال',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF143A2A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 18),
                                        child: Text(
                                          'جنوب',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF143A2A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 18),
                                        child: Text(
                                          'غرب',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF143A2A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 18),
                                        child: Text(
                                          'شرق',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF143A2A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle: arrowAngle,
                                      child: Icon(
                                        Icons.navigation_rounded,
                                        size: arrowSize,
                                        color: const Color(0xFF143A2A),
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle: arrowAngle,
                                      child: const _KaabaMark(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'اتجاه القبلة ${(_qiblaBearing ?? 0).toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'لف الهاتف حتى يستقر السهم ثم استقبل القبلة.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompassMessage extends StatelessWidget {
  const _CompassMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: const Color(0xFF9B6A2E)),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _KaabaMark extends StatelessWidget {
  const _KaabaMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF3E2A16),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            top: 8,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE1B85A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF5A3E1E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
