/// Handedness options for thumb-reach ergonomics.
enum Handedness {
  right('Right'),
  left('Left');

  const Handedness(this.label);
  final String label;

  /// Returns the thumb side for this handedness.
  HandednessSide get thumbSide =>
      this == Handedness.right ? HandednessSide.right : HandednessSide.left;

  static Handedness fromString(String? val) {
    return Handedness.values.firstWhere(
      (e) => e.name == val,
      orElse: () => Handedness.right,
    );
  }
}

/// Represents the physical side of the screen (left or right edge).
enum HandednessSide {
  left,
  right;

  bool get isLeft => this == HandednessSide.left;
  bool get isRight => this == HandednessSide.right;

  static HandednessSide fromString(String? val) {
    return HandednessSide.values.firstWhere(
      (e) => e.name == val,
      orElse: () => HandednessSide.right,
    );
  }
}
