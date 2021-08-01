import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_candlesticks/model/chart_data.dart';
import 'package:flutter_candlesticks/painter/paint-info/paint-rect.dart';
import 'package:flutter_candlesticks/painter/volume-bar-painter.dart';

import 'painter/candlestick-painter.dart';

class OHLCVGraph extends StatelessWidget {
  OHLCVGraph({
    Key? key,
    this.currentPrice,
    this.currentPriceColor = Colors.blue,
    required this.data,
    this.lineWidth = 1.0,
    this.fallbackHeight = 100.0,
    this.fallbackWidth = 300.0,
    this.gridLineColor = Colors.grey,
    this.gridLineAmount = 5,
    this.gridLineWidth = 0.5,
    this.gridLineLabelColor = Colors.grey,
    this.labelPrefix = "\$",
    required this.enableGridLines,
    required this.volumeProp,
    this.candlestickWidth = 30,
    this.spaceBetweenItems = 30,
    this.increaseColor = Colors.green,
    this.decreaseColor = Colors.red,
    this.fillCandle = true,
    this.scrollable = true,
  }) : super(key: key);

  /// OHLCV data to graph  /// List of Maps containing open, high, low, close and volumeto
  /// Example: [["open" : 40.0, "high" : 75.0, "low" : 25.0, "close" : 50.0, "volumeto" : 5000.0}, {...}]
  final List<ChartData> data;

  /// All lines in chart are drawn with this width
  final double lineWidth;

  /// Enable or disable grid lines
  final bool enableGridLines;

  /// Color of grid lines and label text
  final Color gridLineColor;
  final Color gridLineLabelColor;

  /// Number of grid lines
  final int gridLineAmount;

  /// Width of grid lines
  final double gridLineWidth;

  /// Proportion of paint to be given to volume bar graph
  final double volumeProp;

  /// If graph is given unbounded space,
  /// it will default to given fallback height and width
  final double fallbackHeight;
  final double fallbackWidth;

  /// Symbol prefix for grid line labels
  final String labelPrefix;

  /// Increase color
  final Color increaseColor;

  /// Decrease color
  final Color decreaseColor;

  /// fixed width of Candlestick
  final double candlestickWidth;

  /// space between each items(candlestick / volume)
  final double spaceBetweenItems;

  /// fill / stroke option for candilestick
  final bool fillCandle;

  final bool scrollable;

  final double? currentPrice;

  final Color currentPriceColor;

  @override
  Widget build(BuildContext context) {
    final info = _calcMinMax();

    return LimitedBox(
        maxHeight: fallbackHeight,
        maxWidth: fallbackWidth,
        child: Stack(
          children: [
            LimitedBox(
              maxHeight: fallbackHeight,
              maxWidth: fallbackWidth,
              child: _buildOHLCGridPainter(info),
            ),
            scrollable
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: LimitedBox(
                        maxWidth: data.length *
                            (candlestickWidth +
                                spaceBetweenItems +
                                lineWidth * 2),
                        maxHeight: fallbackHeight,
                        child: _buildOHLCVPainter(info)),
                  )
                : _buildOHLCVPainter(info)
          ],
        ));
  }

  Widget _buildOHLCVPainter(_LayoutSupportInfo info) {
    return new CustomPaint(
      size: Size.infinite,
      painter: new _OHLCVPainter(data,
          lineWidth: lineWidth,
          enableGridLines: enableGridLines,
          volumeProp: volumeProp,
          increaseColor: increaseColor,
          decreaseColor: decreaseColor,
          candlestickWidth: candlestickWidth,
          spaceBetweenItems: spaceBetweenItems,
          fillCandle: fillCandle,
          info: info),
    );
  }

  Widget _buildOHLCGridPainter(_LayoutSupportInfo info) {
    return new CustomPaint(
      size: Size.infinite,
      painter: _OHLCGridPainter(
        currentPrice: currentPrice,
        currentPriceColor: currentPriceColor,
        volumeProp: volumeProp,
        info: info,
        gridLineAmount: gridLineAmount,
        gridLineColor: gridLineColor,
        gridLineWidth: gridLineWidth,
        gridLineLabelColor: gridLineLabelColor,
        labelPrefix: labelPrefix,
      ),
    );
  }

  _LayoutSupportInfo _calcMinMax() {
    double minValue = double.infinity;
    double maxValue = -double.infinity;
    double maxVolumeValue = -double.infinity;

    for (final item in data) {
      minValue = min(minValue, item.low);
      maxValue = max(maxValue, item.high);
      maxVolumeValue = max(maxVolumeValue, item.volumeto);
    }

    return _LayoutSupportInfo(
        minValue: minValue, maxValue: maxValue, maxVolumeValue: maxVolumeValue);
  }
}

class _LayoutSupportInfo {
  final double minValue;
  final double maxValue;
  final double maxVolumeValue;

  _LayoutSupportInfo(
      {required this.minValue,
      required this.maxValue,
      required this.maxVolumeValue});
}

class _OHLCGridPainter extends CustomPainter {
  final double? currentPrice;
  final Color currentPriceColor;
  final double currentPriceLineWidth = 2;
  final Color gridLineColor;
  final int gridLineAmount;
  final double gridLineWidth;
  final Color gridLineLabelColor;
  final double volumeProp;
  final String labelPrefix;
  final _LayoutSupportInfo info;

  _OHLCGridPainter(
      {this.currentPrice,
      required this.currentPriceColor,
      required this.gridLineColor,
      required this.gridLineAmount,
      required this.gridLineWidth,
      required this.gridLineLabelColor,
      required this.volumeProp,
      required this.labelPrefix,
      required this.info});

  List<TextPainter> gridLineTextPainters = [];
  TextPainter? currentPricePainter;
  TextPainter? maxVolumePainter;

  int? _gridLineTextLength;

  @override
  void paint(Canvas canvas, Size size) {
    _update();
    _drawGridLines(canvas, size);
    _drawCurrentPriceLine(
      canvas,
      size,
    );
  }

  @override
  bool shouldRepaint(covariant _OHLCGridPainter old) {
    return gridLineColor != old.gridLineColor ||
        gridLineAmount != old.gridLineAmount ||
        gridLineWidth != old.gridLineWidth ||
        gridLineLabelColor != old.gridLineLabelColor;
  }

  void _drawGridLines(Canvas canvas, Size size) {
    double width = size.width - _gridLineTextLength! * 6;
    final double height = size.height * (1 - volumeProp);
    Paint gridPaint = new Paint()
      ..color = gridLineColor
      ..strokeWidth = gridLineWidth;

    double gridLineDist = height / (gridLineAmount - 1);
    double gridLineY = 0.0;

    // Draw grid lines
    for (int i = 0; i < gridLineAmount; i++) {
      gridLineY = (gridLineDist * i).round().toDouble();
      canvas.drawLine(
          new Offset(0.0, gridLineY), new Offset(width, gridLineY), gridPaint);

      // Label grid lines
      gridLineTextPainters[i].paint(canvas, new Offset(width + 2.0, gridLineY));
    }

    // Label volume line
    // TODO: make option
    maxVolumePainter?.paint(canvas, new Offset(0.0, gridLineY + 2.0));
  }

  void _drawCurrentPriceLine(Canvas canvas, Size size) {
    if (currentPricePainter != null) {
      final double width = size.width - _gridLineTextLength! * 6;
      final double height = size.height * (1 - volumeProp);
      final currentPriceY = height * currentPrice! / info.maxValue;

      final gridPaint = new Paint()
        ..color = currentPriceColor
        ..strokeWidth = currentPriceLineWidth;

      canvas.drawLine(new Offset(0.0, currentPriceY),
          new Offset(width, currentPriceY), gridPaint);

      // Label grid lines
      currentPricePainter!
          .paint(canvas, new Offset(width + 2.0, currentPriceY));
    }
  }

  void _update() {
    double gridLineValue;
    for (int i = 0; i < gridLineAmount; i++) {
      // Label grid lines
      gridLineValue = info.maxValue -
          (((info.maxValue - info.minValue) / (gridLineAmount - 1)) * i);

      String gridLineText = _formatGridLineText(gridLineValue);

      if (_gridLineTextLength == null || _gridLineTextLength == 0) {
        _gridLineTextLength = (labelPrefix + gridLineText).length;
      }

      gridLineTextPainters.add(new TextPainter(
          text: new TextSpan(
              text: labelPrefix + gridLineText,
              style: new TextStyle(
                  color: gridLineLabelColor,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr));
      gridLineTextPainters[i].layout();
    }

    if (currentPrice != null) {
      currentPricePainter = TextPainter(
          text: new TextSpan(
              text: labelPrefix + _formatGridLineText(currentPrice!),
              style: new TextStyle(
                  color: currentPriceColor,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr);
      currentPricePainter!.layout();
    }

    // Label volume line
    maxVolumePainter = new TextPainter(
        text: new TextSpan(
            text: labelPrefix + numCommaParse(info.maxVolumeValue),
            style: new TextStyle(
                color: gridLineLabelColor,
                fontSize: 10.0,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
  }

  String _formatGridLineText(double gridLineValue) {
    if (gridLineValue < 1) {
      return gridLineValue.toStringAsPrecision(4);
    } else if (gridLineValue < 999) {
      return gridLineValue.toStringAsFixed(2);
    } else {
      return gridLineValue.round().toString().replaceAllMapped(
          new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
    }
  }

  numCommaParse(number) {
    return number.round().toString().replaceAllMapped(
        new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
  }
}

class _OHLCVPainter extends CustomPainter {
  _OHLCVPainter(this.data,
      {required this.lineWidth,
      required this.enableGridLines,
      required this.volumeProp,
      required this.increaseColor,
      required this.decreaseColor,
      required this.candlestickWidth,
      required this.spaceBetweenItems,
      required this.fillCandle,
      required this.info});

  final List<ChartData> data;
  final double lineWidth;
  final bool enableGridLines;
  final double volumeProp;
  final Color increaseColor;
  final Color decreaseColor;
  final double candlestickWidth;
  final double spaceBetweenItems;
  final bool fillCandle;
  final _LayoutSupportInfo info;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCandleAndVolumes(canvas, size);
  }

  void _drawCandleAndVolumes(Canvas canvas, Size size) {
    final double height = size.height * (1 - volumeProp);
    final double volumeHeight = height * volumeProp;

    final double width = size.width;
    final double volumeNormalizer = volumeHeight / info.maxVolumeValue;

    // NOTE: to avoid layout bug when 0 dividing
    final double heightNormalizer = info.maxValue - info.minValue == 0
        ? 1
        : height / (info.maxValue - info.minValue);
    final double rectWidth = candlestickWidth == -double.infinity
        ? width / data.length
        : candlestickWidth + spaceBetweenItems;

    // Loop through all data
    for (int i = 0; i < data.length; i++) {
      final rectLeft = (i * rectWidth) + lineWidth / 2;
      final rectRight = ((i + 1) * rectWidth) - lineWidth / 2;

      final volumeBarTop = (height + volumeHeight) -
          (data[i].volumeto * volumeNormalizer - lineWidth / 2);
      final volumeBarBottom = height + volumeHeight + lineWidth / 2;

      final highValue = data[i].isDown ? data[i].open : data[i].close;
      final lowValue = data[i].isDown ? data[i].close : data[i].open;

      final low = height - (data[i].low - info.minValue) * heightNormalizer;
      final high = height - (data[i].high - info.minValue) * heightNormalizer;

      final rectTop =
          (height - (highValue - info.minValue) * heightNormalizer) +
              lineWidth / 2;
      final rectBottom =
          (height - (lowValue - info.minValue) * heightNormalizer) -
              lineWidth / 2;

      final rectPaint = new Paint()
        ..color = data[i].isDown ? decreaseColor : increaseColor
        ..strokeWidth = lineWidth;

      final candleStickerPainter = CandleStickPainter(
          strategy: fillCandle
              ? CandleStickStrategy.Fill
              : CandleStickStrategy.Stroke,
          canvas: canvas,
          paint: rectPaint,
          high: high,
          low: low,
          paintInfo: PaintRectInfo(
              lineWidth: lineWidth,
              spaceBetweenItems: spaceBetweenItems,
              rect: PaintRect(
                  left: rectLeft,
                  right: rectRight,
                  top: rectTop,
                  bottom: rectBottom)));
      candleStickerPainter.draw();

      final volumeBarPainter = VolumeBarPainter(
          strategy: fillCandle
              ? VolumeBarPaintStrategy.Fill
              : VolumeBarPaintStrategy.Stroke,
          canvas: canvas,
          paint: rectPaint,
          paintInfo: PaintRectInfo(
              lineWidth: lineWidth,
              spaceBetweenItems: spaceBetweenItems,
              rect: PaintRect(
                  left: rectLeft,
                  top: volumeBarTop,
                  right: rectRight,
                  bottom: volumeBarBottom)));
      volumeBarPainter.draw();
    }
  }

  @override
  bool shouldRepaint(_OHLCVPainter old) {
    return data != old.data ||
        data.length != old.data.length ||
        lineWidth != old.lineWidth ||
        enableGridLines != old.enableGridLines ||
        volumeProp != old.volumeProp;
  }
}
