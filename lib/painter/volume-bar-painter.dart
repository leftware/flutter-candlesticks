import 'package:flutter_candlesticks/painter/base/base-painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_candlesticks/painter/paint-info/paint-rect.dart';

enum VolumeBarPaintStrategy { Fill, Stroke }

class VolumeBarPainter extends BasePainter {
  final PaintRectInfo paintInfo;
  final VolumeBarPaintStrategy strategy;

  VolumeBarPainter(
      {required Canvas canvas,
      required Paint paint,
      required this.paintInfo,
      required this.strategy})
      : super(canvas: canvas, paint: paint);

  @override
  void draw() {
    switch (this.strategy) {
      case VolumeBarPaintStrategy.Fill:
        _drawFill();
        break;
      case VolumeBarPaintStrategy.Stroke:
        _drawStroke();
        break;
    }
  }

  void _drawFill() {
    final rect = paintInfo.rect;
    Rect volumeRect = new Rect.fromLTRB(rect.left, rect.top,
        rect.right - paintInfo.spaceBetweenItems, rect.bottom);
    canvas.drawRect(volumeRect, paint);
  }

  void _drawStroke() {
    final rect = paintInfo.rect;

    canvas.drawLine(
        new Offset(rect.left, rect.bottom - paintInfo.lineWidth / 2),
        new Offset(rect.right - paintInfo.spaceBetweenItems,
            rect.bottom - paintInfo.lineWidth / 2),
        paint);

    canvas.drawLine(
        new Offset(rect.left, rect.top + paintInfo.lineWidth / 2),
        new Offset(rect.right - paintInfo.spaceBetweenItems,
            rect.top + paintInfo.lineWidth / 2),
        paint);

    canvas.drawLine(
        new Offset(rect.left + paintInfo.lineWidth / 2, rect.bottom),
        new Offset(rect.left + paintInfo.lineWidth / 2, rect.top),
        paint);

    canvas.drawLine(
        new Offset(
            rect.right - paintInfo.lineWidth / 2 - paintInfo.spaceBetweenItems,
            rect.bottom),
        new Offset(
            rect.right - paintInfo.lineWidth / 2 - paintInfo.spaceBetweenItems,
            rect.top),
        paint);
  }
}
