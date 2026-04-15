import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/location_permission_prompt.dart';

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

      var permission = await LocationPermissionPrompt.ensurePermission();

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
        title: const Text('Ø§ØªØ¬Ø§Ù‡ Ø§Ù„Ù‚Ø¨Ù„Ø©'),
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
                          Text('Ø¬Ø§Ø±Ù ØªØ­Ø¯ÙŠØ¯ Ø§ØªØ¬Ø§Ù‡ Ø§Ù„Ù‚Ø¨Ù„Ø©...'),
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
                            child: const Text('Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©'),
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
                                  'Ø§Ù„Ø¨ÙˆØµÙ„Ø© ØªØ­ØªØ§Ø¬ ØªØ´ØºÙŠÙ„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ù…Ù† Ø¬Ø¯ÙŠØ¯ ØªØ´ØºÙŠÙ„Ù‹Ø§ ÙƒØ§Ù…Ù„Ù‹Ø§ØŒ ÙˆÙ„ÙŠØ³ Hot Reload.',
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
                                      'Ù‡Ø°Ø§ Ø§Ù„Ø¬Ù‡Ø§Ø² Ù„Ø§ ÙŠÙˆÙÙ‘Ø± Ø­Ø³Ø§Ø³ Ø§ØªØ¬Ø§Ù‡ Ù…Ù†Ø§Ø³Ø¨Ù‹Ø§ Ø§Ù„Ø¢Ù†.\nØ§ØªØ¬Ø§Ù‡ Ø§Ù„Ù‚Ø¨Ù„Ø© Ø§Ù„ØªÙ‚Ø±ÙŠØ¨ÙŠ: ${(_qiblaBearing ?? 0).toStringAsFixed(0)}Â°',
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _loadQiblaBearing,
                                  child: const Text('Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©'),
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
                                          'Ø´Ù…Ø§Ù„',
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
                                          'Ø¬Ù†ÙˆØ¨',
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
                                          'ØºØ±Ø¨',
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
                                          'Ø´Ø±Ù‚',
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
                                'Ø§ØªØ¬Ø§Ù‡ Ø§Ù„Ù‚Ø¨Ù„Ø© ${(_qiblaBearing ?? 0).toStringAsFixed(0)}Â°',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Ù„Ù Ø§Ù„Ù‡Ø§ØªÙ Ø­ØªÙ‰ ÙŠØ³ØªÙ‚Ø± Ø§Ù„Ø³Ù‡Ù… Ø«Ù… Ø§Ø³ØªÙ‚Ø¨Ù„ Ø§Ù„Ù‚Ø¨Ù„Ø©.',
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


