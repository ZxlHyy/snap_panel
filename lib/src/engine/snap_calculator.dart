import '../../snap_panel.dart';

/// 停靠点计算器
///
/// 职责：
/// - 计算停靠点列表
/// - 根据当前位置和速度计算目标停靠点
/// - 判断当前处于哪个停靠点状态
class SnapCalculator {
  /// 计算后的停靠点列表（包含 0.0 和 1.0）
  List<double> computedSnapPoints = [0.0, 1.0];

  /// 第一个非零停靠点值（用于收起态透明度计算）
  double firstSnapPoint = 1.0;

  /// 重新计算停靠点列表
  void compute(List<SnapPanelSnapPoint>? snapPoints) {
    final points = <double>{0.0, 1.0};
    if (snapPoints != null) {
      for (final sp in snapPoints) {
        points.add(sp.position);
      }
    }
    computedSnapPoints = points.toList()..sort();
    _updateFirstSnapPoint();
  }

  void _updateFirstSnapPoint() {
    final snapPoints = computedSnapPoints.where((p) => p > 0.0).toList();
    firstSnapPoint = snapPoints.isEmpty ? 1.0 : snapPoints.first;
  }

  /// 根据当前位置和方向找目标停靠点
  /// direction > 0: 展开方向, direction < 0: 收起方向
  double findTargetSnap(double currentPosition, int direction) {
    if (direction > 0) {
      // 找下一个更高的停靠点
      for (final p in computedSnapPoints) {
        if (p > currentPosition) return p;
      }
      return 1.0;
    } else if (direction < 0) {
      // 找下一个更低的停靠点
      for (final p in computedSnapPoints.reversed) {
        if (p < currentPosition) return p;
      }
      return 0.0;
    }
    return currentPosition;
  }

  /// 找最近的停靠点
  double findNearestSnap(double currentPosition) {
    double nearest = computedSnapPoints.first;
    double minDist = double.infinity;
    for (final p in computedSnapPoints) {
      final dist = (p - currentPosition).abs();
      if (dist < minDist) {
        minDist = dist;
        nearest = p;
      }
    }
    return nearest;
  }

  /// 根据位置判断当前状态
  SnapPanelState? getStateFromPosition(double position, {double tolerance = 0.02}) {
    if ((position - 0.0).abs() < tolerance) {
      return SnapPanelState.collapsed;
    } else if ((position - 1.0).abs() < tolerance) {
      return SnapPanelState.expanded;
    } else if (computedSnapPoints.any((p) => p > 0.0 && p < 1.0 && (position - p).abs() < tolerance)) {
      return SnapPanelState.half;
    }
    return null;
  }

  /// 状态转换为数值
  double stateToValue(SnapPanelState state) {
    switch (state) {
      case SnapPanelState.collapsed:
        return 0.0;
      case SnapPanelState.half:
        final midPoints = computedSnapPoints.where((p) => p > 0.0 && p < 1.0).toList();
        return midPoints.isEmpty ? 0.5 : midPoints.first;
      case SnapPanelState.expanded:
        return 1.0;
    }
  }
}