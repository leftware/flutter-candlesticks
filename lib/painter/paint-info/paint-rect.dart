class PaintRect {
  final double left;
  final double right;
  final double bottom;
  final double top;

  PaintRect(
      {required this.left,
      required this.right,
      required this.bottom,
      required this.top});
}

class PaintRectInfo {
  final double lineWidth;
  final double spaceBetweenItems;
  final PaintRect rect;
  PaintRectInfo(
      {required this.lineWidth,
      required this.spaceBetweenItems,
      required this.rect});
}
