import 'package:flutter/gestures.dart';

/// 手势引擎
///
/// 职责：
/// - 管理手势识别
/// - 追踪速度
/// - 判断手势方向
class GestureEngine {
  /// 速度追踪器
  VelocityTracker _velocityTracker =
      VelocityTracker.withKind(PointerDeviceKind.touch);

  /// 手势起始位置（用于判断是否为垂直手势）
  PointerDownEvent? _pointerDownEvent;

  /// 是否已确认为垂直手势
  bool _isVerticalGesture = false;

  /// 拖拽累计位移（用于速度为零时判断用户方向意图）
  double _accumulatedDragDelta = 0.0;

  /// 重置手势状态
  void reset() {
    _pointerDownEvent = null;
    _isVerticalGesture = false;
    _accumulatedDragDelta = 0.0;
  }

  /// 开始追踪新手势
  void startGesture(PointerDownEvent event) {
    reset();
    _pointerDownEvent = event;
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
    _velocityTracker.addPosition(event.timeStamp, event.localPosition);
  }

  /// 更新手势位置
  /// 返回是否是有效的垂直手势移动
  bool updateGesture(PointerMoveEvent event) {
    if (_pointerDownEvent == null) return false;

    if (!_isVerticalGesture) {
      // 尚未确认手势方向时，用累积位移判断
      final dx = (event.position.dx - _pointerDownEvent!.position.dx).abs();
      final dy = (event.position.dy - _pointerDownEvent!.position.dy).abs();
      if (dy > dx) {
        _isVerticalGesture = true;
        _velocityTracker.addPosition(event.timeStamp, event.localPosition);
        return true;
      }
      return false;
    } else {
      // 已确认为垂直手势，直接追踪速度和位移
      _velocityTracker.addPosition(event.timeStamp, event.localPosition);
      return true;
    }
  }

  /// 结束手势
  void endGesture() {
    reset();
  }

  /// 添加垂直拖拽位置
  void addDragPosition(Duration timeStamp, Offset position) {
    _velocityTracker.addPosition(timeStamp, position);
  }

  /// 获取当前速度
  Velocity getVelocity() => _velocityTracker.getVelocity();

  /// 获取累计拖拽位移
  double get accumulatedDragDelta => _accumulatedDragDelta;

  /// 添加拖拽位移
  void addDragDelta(double dy) {
    _accumulatedDragDelta += dy;
  }

  /// 重置累计位移
  void resetAccumulatedDelta() {
    _accumulatedDragDelta = 0.0;
  }

  /// 是否是垂直手势
  bool get isVerticalGesture => _isVerticalGesture;
}