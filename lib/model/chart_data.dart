class ChartData {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volumeto;

  bool get isUp {
    return open < close;
  }

  bool get isDown {
    return open > close;
  }

  ChartData(
      {required this.open,
      required this.high,
      required this.low,
      required this.close,
      required this.volumeto});

  ChartData.fromJSON(dynamic json)
      : this.open = json['open'],
        this.high = json['high'],
        this.low = json['low'],
        this.close = json['close'],
        this.volumeto = json['volumeto'];
}
