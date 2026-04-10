import 'dart:convert';

import 'package:flutter/services.dart';

class ProphetBiographyEpisodeSummary {
  const ProphetBiographyEpisodeSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String preview;
  final String assetPath;

  factory ProphetBiographyEpisodeSummary.fromJson(Map<String, dynamic> json) {
    return ProphetBiographyEpisodeSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      preview: (json['preview'] ?? '').toString(),
      assetPath: (json['assetPath'] ?? '').toString(),
    );
  }
}

class ProphetBiographyEpisodeDetails {
  const ProphetBiographyEpisodeDetails({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;

  factory ProphetBiographyEpisodeDetails.fromJson(Map<String, dynamic> json) {
    return ProphetBiographyEpisodeDetails(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['content'] ?? '').toString(),
    );
  }
}

Future<List<ProphetBiographyEpisodeSummary>> loadProphetBiographyEpisodes() async {
  final raw = await rootBundle.loadString('assets/episodes/index.json');
  final items = jsonDecode(raw) as List<dynamic>;
  return items
      .map(
        (item) => ProphetBiographyEpisodeSummary.fromJson(
          item as Map<String, dynamic>,
        ),
      )
      .toList();
}

Future<ProphetBiographyEpisodeDetails> loadProphetBiographyEpisodeDetails(
  String assetPath,
) async {
  final raw = await rootBundle.loadString(assetPath);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return ProphetBiographyEpisodeDetails.fromJson(json);
}
