import 'dart:io';

import 'package:flutter/material.dart';

Widget buildShamarlyPageImage({
  required BuildContext context,
  required String filePath,
  required Widget errorWidget,
  BoxFit fit = BoxFit.contain,
}) {
  return Image.file(
    File(filePath),
    fit: fit,
    gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) => errorWidget,
  );
}
