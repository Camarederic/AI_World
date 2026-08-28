class Detection {
  final String label;
  final int classId;
  final double score;

  // Нормализованные координаты:
  // top, left, bottom, right — от 0.0 до 1.0.
  final double top;
  final double left;
  final double bottom;
  final double right;

  const Detection({
    required this.label,
    required this.classId,
    required this.score,
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  });
}
