import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const double size = 1024;
  const bgColor = Color(0xFFF5ECFF);
  const iconColor = Color(0xFF6A3BA6);
  const IconData iconData = Icons.menu_book;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final backgroundPaint = Paint()..color = bgColor;
  canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), backgroundPaint);

  final iconPainter = TextPainter(textDirection: TextDirection.ltr);
  final textSpan = TextSpan(
    text: String.fromCharCode(iconData.codePoint),
    style: const TextStyle(
      fontSize: 760,
      fontFamily: 'MaterialIcons',
      color: iconColor,
    ),
  );
  iconPainter.text = textSpan;
  iconPainter.layout();

  final double dx = (size - iconPainter.width) / 2;
  final double dy = (size - iconPainter.height) / 2;
  iconPainter.paint(canvas, Offset(dx, dy));

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('assets/icons/app_icon.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  print('Updated ${file.path}');
}
