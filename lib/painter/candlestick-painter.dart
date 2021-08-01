import 'package:flutter/material.dart';
import 'package:flutter_candlesticks/painter/base/base-painter.dart';
import 'package:flutter_candlesticks/painter/paint-info/paint-rect.dart';

enum CandleStickStrategy { Fill, Stroke }

class CandleStickPainter extends BasePainter {
  final CandleStickStrategy strategy;
  final PaintRectInfo paintInfo;
  final double low;
  final double high;

  CandleStickPainter(
      {required Paint paint,
      required Canvas canvas,
      required this.strategy,
      required this.paintInfo,
      required this.high,
      required this.low})
      : super(paint: paint, canvas: canvas);

  @override
  void draw() {
    switch (strategy) {
      case CandleStickStrategy.Fill:
        _drawFill();
        break;
      case CandleStickStrategy.Stroke:
        _drawStroke();
        break;
    }

    _drawWicks();
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

  void _drawFill() {
    final rect = paintInfo.rect;
    canvas.drawRect(
        Rect.fromLTRB(rect.left, rect.top,
            rect.right - paintInfo.spaceBetweenItems, rect.bottom),
        paint);
  }

  void _drawWicks() {
    final rect = paintInfo.rect;
    final rectWidth = (rect.left - rect.right).abs();
    final dx = rect.left +
        rectWidth / 2 -
        paintInfo.lineWidth / 2 -
        paintInfo.spaceBetweenItems / 2;

    canvas.drawLine(new Offset(dx, rect.bottom), new Offset(dx, low), paint);
    canvas.drawLine(new Offset(dx, rect.top), new Offset(dx, high), paint);
  }
}
