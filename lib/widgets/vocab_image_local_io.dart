import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildLocalVocabImage({
  required String path,
  required double? width,
  required double? height,
  required BoxFit fit,
  required Widget fallback,
}) {
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}
