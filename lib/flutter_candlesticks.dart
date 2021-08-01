import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_candlesticks/model/chart_data.dart';
import 'package:flutter_candlesticks/painter/paint-info/paint-rect.dart';
import 'package:flutter_candlesticks/painter/volume-bar-painter.dart';

import 'painter/candlestick-painter.dart';

class OHLCVGraph extends StatelessWidget {
  OHLCVGraph({
    Key? key,
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

  @override
  Widget build(BuildContext context) {
    return new LimitedBox(
        maxHeight: fallbackHeight,
        maxWidth: fallbackWidth,
        child: scrollable
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                    width: data.length *
                        (candlestickWidth + spaceBetweenItems + lineWidth * 2),
                    height: fallbackHeight,
                    child: _buildOHLCVPainter()),
              )
            : _buildOHLCVPainter());
  }

  Widget _buildOHLCVPainter() {
    return new CustomPaint(
      size: Size.infinite,
      painter: new _OHLCVPainter(data,
          lineWidth: lineWidth,
          gridLineColor: gridLineColor,
          gridLineAmount: gridLineAmount,
          gridLineWidth: gridLineWidth,
          gridLineLabelColor: gridLineLabelColor,
          enableGridLines: enableGridLines,
          volumeProp: volumeProp,
          labelPrefix: labelPrefix,
          increaseColor: increaseColor,
          decreaseColor: decreaseColor,
          candlestickWidth: candlestickWidth,
          spaceBetweenItems: spaceBetweenItems,
          fillCandle: fillCandle),
    );
  }
}

class _OHLCVPainter extends CustomPainter {
  _OHLCVPainter(this.data,
      {required this.lineWidth,
      required this.enableGridLines,
      required this.gridLineColor,
      required this.gridLineAmount,
      required this.gridLineWidth,
      required this.gridLineLabelColor,
      required this.volumeProp,
      required this.labelPrefix,
      required this.increaseColor,
      required this.decreaseColor,
      required this.candlestickWidth,
      required this.spaceBetweenItems,
      required this.fillCandle});

  final List<ChartData> data;
  final double lineWidth;
  final bool enableGridLines;
  final Color gridLineColor;
  final int gridLineAmount;
  final double gridLineWidth;
  final Color gridLineLabelColor;
  final String labelPrefix;
  final double volumeProp;
  final Color increaseColor;
  final Color decreaseColor;
  final double candlestickWidth;
  final double spaceBetweenItems;
  final bool fillCandle;

  double _min = -double.infinity;
  double _max = -double.infinity;
  double _maxVolume = -double.infinity;

  int? _gridLineTextLength;

  List<TextPainter> gridLineTextPainters = [];
  TextPainter? maxVolumePainter;

  numCommaParse(number) {
    return number.round().toString().replaceAllMapped(
        new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
  }

  update() {
    _calcMinMax();

    if (enableGridLines) {
      double gridLineValue;
      for (int i = 0; i < gridLineAmount; i++) {
        // Label grid lines
        gridLineValue = _max - (((_max - _min) / (gridLineAmount - 1)) * i);

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

      // Label volume line
      maxVolumePainter = new TextPainter(
          text: new TextSpan(
              text: labelPrefix + numCommaParse(_maxVolume),
              style: new TextStyle(
                  color: gridLineLabelColor,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)
        ..layout();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_min == -double.infinity ||
        _max == -double.infinity ||
        _maxVolume == -double.infinity) {
      update();
    }

    if (enableGridLines) {
      _drawGridLines(canvas, size);
    }

    _drawCandleAndVolumes(canvas, size);
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

  void _drawCandleAndVolumes(Canvas canvas, Size size) {
    final double height = size.height * (1 - volumeProp);
    final double volumeHeight = height * volumeProp;

    final double width = size.width;
    final double volumeNormalizer = volumeHeight / _maxVolume;

    // NOTE: to avoid layout bug when 0 dividing
    final double heightNormalizer =
        _max - _min == 0 ? 1 : height / (_max - _min);
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

      final low = height - (data[i].low - _min) * heightNormalizer;
      final high = height - (data[i].high - _min) * heightNormalizer;

      final rectTop =
          (height - (highValue - _min) * heightNormalizer) + lineWidth / 2;
      final rectBottom =
          (height - (lowValue - _min) * heightNormalizer) - lineWidth / 2;

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
        gridLineColor != old.gridLineColor ||
        gridLineAmount != old.gridLineAmount ||
        gridLineWidth != old.gridLineWidth ||
        volumeProp != old.volumeProp ||
        gridLineLabelColor != old.gridLineLabelColor;
  }

  void _calcMinMax() {
    _min = double.infinity;
    _max = -double.infinity;
    _maxVolume = -double.infinity;

    for (var i in data) {
      if (i.high > _max) {
        _max = i.high;
      }
      if (i.low < _min) {
        _min = i.low;
      }
      if (i.volumeto > _maxVolume) {
        _maxVolume = i.volumeto;
      }
    }
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
}
