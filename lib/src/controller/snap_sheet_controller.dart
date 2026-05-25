import 'package:flutter/material.dart';

/// Snap points for the bottom sheet
class SnapPoints {
  static const double collapsed = 0.0;
  static const double peek = 0.3;
  static const double half = 0.6;
  static const double expanded = 1.0;

  // Default snap points: collapsed and expanded only
  static const List<double> defaultSnapPoints = [
    collapsed,
    expanded,
  ];

  // Common presets
  static const List<double> threePoints = [
    collapsed,
    0.5, // middle position
    expanded,
  ];

  static const List<double> fourPoints = [
    collapsed,
    peek,
    half,
    expanded,
  ];
}

/// Controller for managing SnapSheet state and animations
class SnapSheetController extends ChangeNotifier {
  SnapSheetController({
    double initialHeight = 0.0,
    this.snapPoints = SnapPoints.defaultSnapPoints,
  }) : _height = initialHeight;

  AnimationController? _animationController;
  final List<double> snapPoints;

  double _height;
  double _velocity = 0.0;
  bool _isDragging = false;

  /// Set the animation controller (called by SnapSheet)
  void setAnimationController(AnimationController controller) {
    _animationController?.removeListener(_onAnimationUpdate);
    _animationController = controller;
    _animationController!.addListener(_onAnimationUpdate);
    _animationController!.value = _height;
  }

  /// Current height of the sheet (0.0 to 1.0)
  double get height => _height;

  /// Current animation controller
  AnimationController? get animationController => _animationController;

  /// Whether the sheet is currently being dragged
  bool get isDragging => _isDragging;

  /// Current velocity of the drag
  double get velocity => _velocity;

  void _onAnimationUpdate() {
    if (!_isDragging && _animationController != null) {
      _height = _animationController!.value;
      notifyListeners();
    }
  }

  /// Update height during drag (without animation)
  void updateHeight(double newHeight) {
    _height = newHeight.clamp(0.0, 1.0);
    _animationController?.value = _height;
    notifyListeners();
  }

  /// Start drag
  void startDrag() {
    _isDragging = true;
    _animationController?.stop();
  }

  /// Update velocity during drag
  void updateVelocity(double velocity) {
    _velocity = velocity;
  }

  /// End drag and snap to nearest point
  void endDrag() {
    _isDragging = false;

    final targetHeight = _calculateSnapTarget();
    animateTo(targetHeight);
  }

  /// Calculate snap target based on current height and velocity
  double _calculateSnapTarget() {
    // If velocity is significant, consider it for snapping
    if (_velocity.abs() > 500.0) {
      if (_velocity > 0) {
        // Swiping up - find next higher snap point
        for (final point in snapPoints) {
          if (point > _height) {
            return point;
          }
        }
      } else {
        // Swiping down - find next lower snap point
        for (final point in snapPoints.reversed) {
          if (point < _height) {
            return point;
          }
        }
      }
    }

    // No significant velocity, snap to nearest
    double nearest = snapPoints.first;
    double minDistance = (_height - nearest).abs();

    for (final point in snapPoints) {
      final distance = (_height - point).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = point;
      }
    }

    return nearest;
  }

  /// Animate to a specific height
  Future<void> animateTo(double targetHeight, {Duration? duration}) async {
    if (_animationController == null) return;

    targetHeight = targetHeight.clamp(0.0, 1.0);

    await _animationController!.animateTo(
      targetHeight,
      duration: duration ?? const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Expand to full height
  Future<void> expand() async {
    await animateTo(SnapPoints.expanded);
  }

  /// Collapse to hidden
  Future<void> collapse() async {
    await animateTo(SnapPoints.collapsed);
  }

  /// Snap to peek position
  Future<void> peek() async {
    await animateTo(SnapPoints.peek);
  }

  /// Snap to half position
  Future<void> half() async {
    await animateTo(SnapPoints.half);
  }

  @override
  void dispose() {
    _animationController?.removeListener(_onAnimationUpdate);
    // Note: Don't dispose the animation controller here as it's owned by the widget
    super.dispose();
  }
}