import 'package:flutter/material.dart';

abstract class BasePainter {
  final Paint paint;
  final Canvas canvas;

  BasePainter({required this.paint, required this.canvas});

  void draw();
}
