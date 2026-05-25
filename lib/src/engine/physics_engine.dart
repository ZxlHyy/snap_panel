import 'package:flutter/physics.dart';
import '../widget/snap_panel.dart';

/// 物理引擎
///
/// 职责：
/// - 管理弹簧模拟
/// - 计算 fling 动画参数
class PhysicsEngine {
  /// 弹簧参数
  SnapPanelSpring spring;

  PhysicsEngine({required this.spring});

  /// 创建弹簧模拟
  SpringSimulation createSpringSimulation({
    required double currentValue,
    required double targetValue,
    required double visualVelocity,
  }) {
    final speed = visualVelocity.abs();
    final speedFactor = (speed / 2.0).clamp(0.5, 3.0);

    final springDesc = SpringDescription.withDampingRatio(
      mass: spring.mass,
      stiffness: spring.stiffness * speedFactor,
      ratio: spring.dampingRatio, // 使用配置的阻尼比
    );

    return SpringSimulation(
      springDesc,
      currentValue,
      targetValue,
      visualVelocity,
    );
  }

  /// 根据手势数据计算视觉速度和方向
  /// 返回 (direction, speed)
  /// direction: 1 = 展开方向, -1 = 收起方向, 0 = 不移动
  ({int direction, double speed}) calculateDirection({
    required double velocityPixelsPerSecond,
    required double panelRange,
    required double accumulatedDragDelta,
    required SnapPanelSlideDirection slideDirection,
    double velocityThreshold = 0.01,
    double dragThreshold = 10.0,
    double defaultSpeed = 0.5,
  }) {
    // 将物理速度转换为面板位置速度（0.0~1.0 范围）
    double visualVelocity;
    if (slideDirection == SnapPanelSlideDirection.up) {
      visualVelocity = -velocityPixelsPerSecond / panelRange;
    } else {
      visualVelocity = velocityPixelsPerSecond / panelRange;
    }

    // 优先用速度判断方向
    if (visualVelocity.abs() > velocityThreshold) {
      return (
        direction: visualVelocity > 0 ? 1 : -1,
        speed: visualVelocity,
      );
    }

    // 速度太小时用累计位移兜底
    if (accumulatedDragDelta.abs() > dragThreshold) {
      int direction;
      if (slideDirection == SnapPanelSlideDirection.up) {
        direction = accumulatedDragDelta < 0 ? 1 : -1;
      } else {
        direction = accumulatedDragDelta > 0 ? 1 : -1;
      }
      return (direction: direction, speed: defaultSpeed);
    }

    // 几乎没有拖动，不移动
    return (direction: 0, speed: 0.0);
  }
}

/// 扩展 SpringDescription 以提供便捷的 simulation 方法
extension SpringDescriptionExtension on SpringDescription {
  SpringSimulation simulation(double start, double end, double velocity) {
    return SpringSimulation(this, start, end, velocity);
  }
}