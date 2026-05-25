// 高度可定制的滑动面板组件

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// ==================== 枚举 ====================

/// 面板滑动方向
enum SnapPanelSlideDirection {
  /// 从底部向上滑出
  up,
  /// 从顶部向下滑出
  down,
}

/// 面板状态
enum SnapPanelState {
  /// 收起状态（minHeight）
  collapsed,
  /// 半开状态（snapPoint 或中间位置）
  half,
  /// 完全打开状态（maxHeight）
  expanded,
}

// ==================== 停靠点配置 ====================

/// 面板停靠点
class SnapPanelSnapPoint {
  /// 停靠位置，取值范围 0.0 ~ 1.0
  /// 0.0 对应 minHeight，1.0 对应 maxHeight
  final double position;

  /// 到达此停靠点时是否触发回调
  final bool Function(SnapPanelState state)? onReached;

  const SnapPanelSnapPoint({
    required this.position,
    this.onReached,
  }) : assert(position > 0.0 && position < 1.0);
}

// ==================== 弹簧配置 ====================

/// 弹簧物理参数，用于控制面板动画手感
class SnapPanelSpring {
  /// 质量，影响惯性
  final double mass;

  /// 刚度，影响回弹速度
  final double stiffness;

  /// 阻尼比，1.0 为临界阻尼，<1.0 会有回弹效果
  final double dampingRatio;

  const SnapPanelSpring({
    this.mass = 1.0,
    this.stiffness = 500.0,
    this.dampingRatio = 1.0,
  });

  SpringDescription get description => SpringDescription.withDampingRatio(
    mass: mass,
    stiffness: stiffness,
    ratio: dampingRatio,
  );
}

// ==================== 回调类型定义 ====================

/// 面板位置变化回调，value 范围 0.0 ~ 1.0
typedef SnapPanelPositionCallback = void Function(double position);

/// 面板状态变化回调
typedef SnapPanelStateCallback = void Function(SnapPanelState state);

/// 面板滚动联动回调，用于自定义滚动与面板拖拽的联动逻辑
typedef SnapPanelScrollLinkCallback = bool Function(
    ScrollController controller,
    double dragDelta,
    );

// ==================== 面板控制器 ====================

class SnapPanelController {
  _SnapPanelState? _state;

  void _attach(_SnapPanelState state) => _state = state;
  void _detach() => _state = null;

  bool get _isAttached => _state != null;

  /// 是否已绑定到面板实例
  bool get isAttached => _isAttached;

  /// 当前面板位置，取值范围 0.0 ~ 1.0
  double get panelPosition {
    _assertAttached();
    return _state!._panelPosition;
  }

  /// 当前面板状态
  SnapPanelState get panelState {
    _assertAttached();
    return _state!._currentPanelState;
  }

  /// 是否正在动画中
  bool get isAnimating {
    _assertAttached();
    return _state!._isAnimating;
  }

  /// 是否完全收起
  bool get isCollapsed {
    _assertAttached();
    return _state!._currentPanelState == SnapPanelState.collapsed;
  }

  /// 是否完全展开
  bool get isExpanded {
    _assertAttached();
    return _state!._currentPanelState == SnapPanelState.expanded;
  }

  /// 显示面板（收起状态）
  Future<void> show() {
    _assertAttached();
    return _state!._show();
  }

  /// 隐藏面板（完全移出屏幕）
  Future<void> hide() {
    _assertAttached();
    return _state!._hide();
  }

  /// 收起面板到 minHeight
  Future<void> collapse() {
    _assertAttached();
    return _state!._animateTo(0.0);
  }

  /// 展开面板到 maxHeight
  Future<void> expand() {
    _assertAttached();
    return _state!._animateTo(1.0);
  }

  /// 动画到指定位置（0.0 ~ 1.0）
  Future<void> animateTo(
      double position, {
        Duration? duration,
        Curve curve = Curves.easeOutCubic,
      }) {
    _assertAttached();
    return _state!._animateTo(
      position,
      duration: duration,
      curve: curve,
    );
  }

  /// 动画到最近的停靠点
  Future<void> animateToSnapPoint() {
    _assertAttached();
    return _state!._animateToSnapPoint();
  }

  /// 设置面板位置（无动画）
  set panelPosition(double value) {
    _assertAttached();
    assert(value >= 0.0 && value <= 1.0);
    _state!._panelPosition = value;
  }

  void _assertAttached() {
    assert(isAttached, 'SnapPanelController 必须已绑定到 SnapPanel 实例');
  }
}

// ==================== 主组件 ====================

class SnapPanel extends StatefulWidget {
  // ---------- 内容 ----------

  /// 面板展开时显示的内容
  final Widget? panel;

  /// 支持滚动联动的面板构建器
  /// 接收 ScrollController，可用于绑定内部滚动视图
  final Widget Function(ScrollController scrollController)? panelBuilder;

  /// 面板收起时显示的折叠内容
  final Widget? collapsed;

  /// 面板背后的主体内容
  final Widget? body;

  /// 面板顶部悬浮组件（不随面板内容滚动）
  final Widget? header;

  /// 面板底部悬浮组件（不随面板内容滚动）
  final Widget? dragHandle;

  // ---------- 尺寸 ----------

  /// 收起时高度
  final double minHeight;

  /// 展开时高度
  final double maxHeight;

  /// 停靠点列表，面板会吸附到最近的位置
  /// 如果不设置，默认只有 0.0（收起）和 1.0（展开）两个停靠点
  final List<SnapPanelSnapPoint>? snapPoints;

  // ---------- 外观 ----------

  /// 面板背景色
  final Color color;

  /// 面板圆角
  final BorderRadiusGeometry? borderRadius;

  /// 面板边框
  final Border? border;

  /// 面板阴影
  final List<BoxShadow>? boxShadow;

  /// 面板内边距
  final EdgeInsetsGeometry? padding;

  /// 面板外边距
  final EdgeInsetsGeometry? margin;

  /// 是否渲染面板底板
  final bool renderPanelSheet;

  /// Material elevation（会自动生成阴影，优先级低于 boxShadow）
  final double? elevation;

  // ---------- 行为 ----------

  /// 面板控制器
  final SnapPanelController? controller;

  /// 默认状态
  final SnapPanelState defaultState;

  /// 是否允许拖拽
  final bool isDraggable;

  /// 滑动方向
  final SnapPanelSlideDirection slideDirection;

  /// 快速滑动速度阈值（像素/秒），超过此值视为 fling
  final double flingVelocity;

  // ---------- 动画 ----------

  /// 动画时长（默认停靠点之间动画的时间）
  final Duration animationDuration;

  /// 默认动画曲线
  final Curve animationCurve;

  /// 弹簧参数
  final SnapPanelSpring spring;

  // ---------- 背景遮罩 ----------

  /// 是否启用背景遮罩
  final bool backdropEnabled;

  /// 遮罩颜色
  final Color backdropColor;

  /// 遮罩最大透明度（0.0 ~ 1.0）
  final double backdropOpacity;

  /// 点击遮罩是否收起面板
  final bool backdropTapClosesPanel;

  // ---------- 视差 ----------

  /// 主体内容是否跟随面板滑动产生视差效果
  final bool parallaxEnabled;

  /// 视差偏移比例（0.0 ~ 1.0）
  final double parallaxOffset;

  // ---------- 回调 ----------

  /// 面板位置变化回调
  final SnapPanelPositionCallback? onPanelSlide;

  /// 面板状态变化回调（统一回调，替代分散的 onPanelCollapsed/onPanelExpanded/onPanelHalf）
  final SnapPanelStateCallback? onPanelStateChanged;

  /// 状态变化时的回调（通过 PanelStateCallbackCompat 保持兼容）
  final VoidCallback? onPanelCollapsed;

  final VoidCallback? onPanelExpanded;
  final VoidCallback? onPanelHalf;

  // ---------- 自定义滚动联动 ----------

  /// 自定义滚动与拖拽联动逻辑
  final SnapPanelScrollLinkCallback? onScrollLink;

  const SnapPanel({
    super.key,
    this.panel,
    this.panelBuilder,
    this.collapsed,
    this.body,
    this.header,
    this.dragHandle,
    this.minHeight = 100.0,
    this.maxHeight = 500.0,
    this.snapPoints,
    this.color = Colors.white,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.padding,
    this.margin,
    this.renderPanelSheet = true,
    this.elevation,
    this.controller,
    this.defaultState = SnapPanelState.collapsed,
    this.isDraggable = true,
    this.slideDirection = SnapPanelSlideDirection.up,
    this.flingVelocity = 5.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
    this.spring = const SnapPanelSpring(),
    this.backdropEnabled = false,
    this.backdropColor = Colors.black,
    this.backdropOpacity = 0.5,
    this.backdropTapClosesPanel = true,
    this.parallaxEnabled = false,
    this.parallaxOffset = 0.1,
    this.onPanelSlide,
    this.onPanelStateChanged,
    this.onPanelCollapsed,
    this.onPanelExpanded,
    this.onPanelHalf,
    this.onScrollLink,
  })  : assert(panel != null || panelBuilder != null,
  'panel 和 panelBuilder 不能同时为 null'),
        assert(minHeight >= 0, 'minHeight 不能为负数'),
        assert(maxHeight > minHeight, 'maxHeight 必须大于 minHeight'),
        assert(backdropOpacity >= 0.0 && backdropOpacity <= 1.0,
        'backdropOpacity 必须在 0.0 ~ 1.0 之间'),
        assert(parallaxOffset >= 0.0 && parallaxOffset <= 1.0,
        'parallaxOffset 必须在 0.0 ~ 1.0 之间');

  @override
  State<SnapPanel> createState() => _SnapPanelState();
}

class _SnapPanelState extends State<SnapPanel> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late ScrollController _sc;

  /// 面板是否可见（用于 hide/show）
  bool _isPanelVisible = true;

  /// 面板当前状态
  SnapPanelState _currentPanelState = SnapPanelState.collapsed;

  /// 内部滚动是否启用
  bool _scrollingEnabled = false;

  /// 速度追踪器（每次手势开始时重建，避免残留数据影响速度计算）
  VelocityTracker _velocityTracker =
  VelocityTracker.withKind(PointerDeviceKind.touch);

  /// 手势起始位置（用于判断是否为垂直手势）
  PointerDownEvent? _pointerDownEvent;

  /// 是否已确认为垂直手势
  bool _isVerticalGesture = false;

  /// 拖拽累计位移（用于速度为零时判断用户方向意图）
  double _accumulatedDragDelta = 0.0;

  /// 计算后的停靠点列表（包含 0.0 和 1.0）
  late List<double> _computedSnapPoints;

  // ==================== 缓存的装饰对象 ====================

  /// 缓存的面板装饰（仅在装饰参数变化时重建）
  BoxDecoration? _cachedDecoration;
  List<BoxShadow>? _cachedBoxShadow;
  Border? _cachedBorder;
  BorderRadiusGeometry? _cachedBorderRadius;
  Color? _cachedColor;

  /// 缓存的默认阴影
  List<BoxShadow>? _defaultShadowValue;
  double? _cachedElevation;

  /// 缓存的第一个停靠点值（用于收起态透明度计算）
  double _cachedFirstSnapPoint = 1.0;

  @override
  void initState() {
    super.initState();

    _computeSnapPoints();
    _currentPanelState = widget.defaultState;

    _ac = AnimationController.unbounded(
      vsync: this,
      value: _stateToValue(widget.defaultState),
    )..addListener(_onAnimationTick);

    _sc = ScrollController();
    _sc.addListener(_onScrollChange);

    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant SnapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 停靠点变化时重新计算
    if (oldWidget.snapPoints != widget.snapPoints) {
      _computeSnapPoints();
    }

    // 默认状态变化时更新
    if (oldWidget.defaultState != widget.defaultState && mounted) {
      final targetValue = _stateToValue(widget.defaultState);
      _ac.animateTo(targetValue, duration: widget.animationDuration, curve: widget.animationCurve);
    }

    // 控制器变化时重新绑定
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _ac.dispose();
    _sc.dispose();
    super.dispose();
  }

  // ==================== 停靠点计算 ====================

  void _computeSnapPoints() {
    final points = <double>{0.0, 1.0};
    if (widget.snapPoints != null) {
      for (final sp in widget.snapPoints!) {
        points.add(sp.position);
      }
    }
    _computedSnapPoints = points.toList()..sort();
    // 更新缓存的第一个停靠点
    _updateCachedFirstSnapPoint();
  }

  /// 更新缓存的第一个停靠点值
  void _updateCachedFirstSnapPoint() {
    final snapPoints = _computedSnapPoints.where((p) => p > 0.0).toList();
    _cachedFirstSnapPoint = snapPoints.isEmpty ? 1.0 : snapPoints.first;
  }

  /// 获取面板装饰（带缓存）
  BoxDecoration _getPanelDecoration() {
    // 检查是否需要重新创建装饰
    if (_cachedDecoration == null ||
        _cachedBorder != widget.border ||
        _cachedBorderRadius != widget.borderRadius ||
        _cachedBoxShadow != widget.boxShadow ||
        _cachedColor != widget.color ||
        _cachedElevation != widget.elevation) {
      _cachedBorder = widget.border;
      _cachedBorderRadius = widget.borderRadius;
      _cachedBoxShadow = widget.boxShadow;
      _cachedColor = widget.color;
      _cachedElevation = widget.elevation;

      _cachedDecoration = BoxDecoration(
        border: widget.border,
        borderRadius: widget.borderRadius,
        boxShadow: widget.boxShadow ?? _getDefaultShadow(),
        color: widget.color,
      );
    }
    return _cachedDecoration!;
  }

  /// 获取默认阴影（带缓存）
  List<BoxShadow> _getDefaultShadow() {
    if (_defaultShadowValue == null || _cachedElevation != widget.elevation) {
      _cachedElevation = widget.elevation;
      if (widget.elevation != null) {
        _defaultShadowValue = [
          BoxShadow(
            blurRadius: widget.elevation! * 2,
            offset: Offset(0, -widget.elevation!),
            color: Colors.black.withValues(alpha: 0.2),
          ),
        ];
      } else {
        _defaultShadowValue = const [
          BoxShadow(
            blurRadius: 8.0,
            color: Color.fromRGBO(0, 0, 0, 0.25),
          ),
        ];
      }
    }
    return _defaultShadowValue!;
  }

  double _stateToValue(SnapPanelState state) {
    switch (state) {
      case SnapPanelState.collapsed:
        return 0.0;
      case SnapPanelState.half:
      // 如果有中间停靠点就用，否则取中间值
        final midPoints = _computedSnapPoints
            .where((p) => p > 0.0 && p < 1.0)
            .toList();
        return midPoints.isEmpty ? 0.5 : midPoints.first;
      case SnapPanelState.expanded:
        return 1.0;
    }
  }

  // ==================== 动画监听 ====================

  void _onAnimationTick() {
    final position = _ac.value;
    widget.onPanelSlide?.call(position);

    // 检测是否到达某个停靠点
    _checkSnapPointReached(position);
  }

  void _checkSnapPointReached(double position) {
    const tolerance = 0.02;
    SnapPanelState? newState;

    if ((position - 0.0).abs() < tolerance) {
      newState = SnapPanelState.collapsed;
    }else if ((position - 1.0).abs() < tolerance) {
      newState = SnapPanelState.expanded;
    }else if (_computedSnapPoints.any((p) => p > 0.0 && p < 1.0 && (position - p).abs() < tolerance)) {
      newState = SnapPanelState.half;
    }

    if (newState != null && newState != _currentPanelState) {
      _currentPanelState = newState;

      // 统一回调
      widget.onPanelStateChanged?.call(newState);

      // 兼容分散回调
      switch (newState) {
        case SnapPanelState.collapsed:
          widget.onPanelCollapsed?.call();
          break;
        case SnapPanelState.expanded:
          widget.onPanelExpanded?.call();
          break;
        case SnapPanelState.half:
          widget.onPanelHalf?.call();
          break;
      }
    }

  }

  // ==================== 滚动监听 ====================

  void _onScrollChange() {
    // 当面板展开且内部滚动禁用时，阻止内部滚动
    if (widget.isDraggable && !_scrollingEnabled && _sc.hasClients) {
      if (_sc.offset > 0) {
        _sc.jumpTo(0);
      }
    }
  }

  // ==================== 手势处理 ====================

  void _onGestureSlide(double dy) {
    // 累计拖拽位移（用于速度为零时判断用户方向意图）
    _accumulatedDragDelta += dy;

    if (!_scrollingEnabled) {
      final delta = dy / (widget.maxHeight - widget.minHeight);
      if (widget.slideDirection == SnapPanelSlideDirection.up) {
        _ac.value = (_ac.value - delta).clamp(0.0, 1.0);
      } else {
        _ac.value = (_ac.value + delta).clamp(0.0, 1.0);
      }
    }

    // 滚动联动判断
    if (_isExpanded && _sc.hasClients && _sc.offset <= 0) {
      if (widget.onScrollLink != null) {
        final shouldScroll = widget.onScrollLink!(_sc, dy);
        if (shouldScroll != _scrollingEnabled) {
          setState(() => _scrollingEnabled = shouldScroll);
        }
      } else {
        // 默认逻辑：上滑启用内部滚动，下滑禁用
        final shouldScroll = dy < 0;
        if (shouldScroll != _scrollingEnabled) {
          setState(() => _scrollingEnabled = shouldScroll);
        }
      }
    }
  }

  void _onGestureEnd(Velocity velocity) {
    if (_ac.isAnimating) return;
    if (_isExpanded && _scrollingEnabled) return;

    final dy = velocity.pixelsPerSecond.dy;
    final panelRange = widget.maxHeight - widget.minHeight;
    final currentValue = _ac.value;

    // 将物理速度转换为面板位置速度（0.0~1.0 范围）
    double visualVelocity;
    if (widget.slideDirection == SnapPanelSlideDirection.up) {
      visualVelocity = -dy / panelRange;
    } else {
      visualVelocity = dy / panelRange;
    }

    // 判断手势方向：优先用速度，速度太小时用累计位移兜底
    // 这解决了在中间位置向上抛时 _velocityTracker 返回零的问题
    int direction; // 1 = 展开方向, -1 = 收起方向, 0 = 不移动
    double speed;

    if (visualVelocity.abs() > 0.01) {
      // 速度明确，用速度方向
      direction = visualVelocity > 0 ? 1 : -1;
      speed = visualVelocity;
    } else if (_accumulatedDragDelta.abs() > 10.0) {
      // 速度为零但累计位移超过阈值，用累计位移方向判断意图
      // 对于从中间向上抛的场景：向上拖拽时 dy < 0, _accumulatedDragDelta < 0
      // slideDirection=up 时，dy < 0 表示向上（展开方向）
      if (widget.slideDirection == SnapPanelSlideDirection.up) {
        direction = _accumulatedDragDelta < 0 ? 1 : -1;
      } else {
        direction = _accumulatedDragDelta > 0 ? 1 : -1;
      }
      // 使用一个适中的默认速度，确保动画能到达停靠点
      speed = 0.5;
    } else {
      // 几乎没有拖动，不移动
      direction = 0;
      speed = 0.0;
    }

    // 重置累计位移
    _accumulatedDragDelta = 0.0;

    if (direction == 0) return;

    // 根据方向找目标停靠点
    final target = direction > 0 ? _findNextSnapUp() : _findNextSnapDown();

    // 如果目标就是当前位置（已到边界），不做任何动画
    if ((target - currentValue).abs() < 0.001) return;

    _flingTo(target, speed);
  }

  /// 找下一个更高的停靠点
  double _findNextSnapUp() {
    final current = _ac.value;
    for (final p in _computedSnapPoints) {
      if (p > current) return p;
    }
    return 1.0;
  }

  /// 找下一个更低的停靠点
  double _findNextSnapDown() {
    final current = _ac.value;
    for (final p in _computedSnapPoints.reversed) {
      if (p < current) return p;
    }
    return 0.0;
  }

  /// 用 fling 动画抛到目标停靠点
  ///
  /// 快速滑动时，面板根据速度方向被"抛"到相邻的下一个停靠点。
  /// 使用 SpringSimulation 让面板以弹性动画到达目标，速度越大初始动能越大，
  /// 但最终精确停在停靠点位置。
  Future<void> _flingTo(double target, double visualVelocity) async {
    // 根据速度大小动态调整弹簧刚度：
    // 速度越快 → 刚度越大 → 动画完成越快
    final speed = visualVelocity.abs();
    final speedFactor = (speed / 2.0).clamp(0.5, 3.0);

    final spring = SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: widget.spring.stiffness * speedFactor,
      ratio: 1, // 0.85轻微欠阻尼，到达停靠点时有轻微回弹，手感更自然
    );

    // 使用 SpringSimulation，从当前位置以当前速度弹向目标停靠点
    final simulation = spring.simulation(_ac.value, target, visualVelocity);
    await _ac.animateWith(simulation);

    // 弹簧模拟由于数值积分精度限制，可能停在目标值的极小偏移处。
    // 动画结束后直接归位到精确的目标停靠点。
    _ac.value = target;
  }

  // ==================== 构建 ====================

  @override
  Widget build(BuildContext context) {
    final containerSize = MediaQuery.of(context).size;
    final containerW = containerSize.width;
    final containerH = containerSize.height;

    final marginH = widget.margin?.horizontal ?? 0.0;
    final paddingH = widget.padding?.horizontal ?? 0.0;
    final contentW = containerW - marginH - paddingH;

    return Stack(
      children: [
        // ---- 主体内容 ----
        if (widget.body != null) _buildBody(containerW, containerH),

        // ---- 背景遮罩 + 滑动面板 ----
        if (widget.backdropEnabled || _isPanelVisible)
          _buildBackdropAndPanel(containerW, containerH, contentW),
      ],
    );
  }

  Widget _buildBody(double containerW, double containerH) {
    // 视差效果使用 RepaintBoundary 隔离重绘
    if (widget.parallaxEnabled) {
      // Positioned 必须是 Stack 的直接子元素
      // RepaintBoundary 包裹在 SizedBox 外层，用于隔离重绘
      return ValueListenableBuilder<double>(
        valueListenable: _ac,
        builder: (context, panelValue, child) {
          final range = widget.maxHeight - widget.minHeight;
          final offset = widget.slideDirection == SnapPanelSlideDirection.up
              ? -panelValue * range * widget.parallaxOffset
              : panelValue * range * widget.parallaxOffset;
          return Positioned.fill(
            top: offset,
            child: child!,
          );
        },
        child: RepaintBoundary(
          child: SizedBox(
            width: containerW,
            height: containerH,
            child: widget.body,  // body 不为 null 时才调用此方法
          ),
        ),
      );
    }

    // 无视差时直接返回，无需监听动画
    return Positioned.fill(
      child: SizedBox(
        width: containerW,
        height: containerH,
        child: widget.body,  // body 不为 null 时才调用此方法
      ),
    );
  }

  /// 合并遮罩和面板的构建，使用单个 ValueListenableBuilder
  Widget _buildBackdropAndPanel(double containerW, double containerH, double contentW) {
    return RepaintBoundary(
      child: ValueListenableBuilder<double>(
        valueListenable: _ac,
        builder: (context, panelValue, _) {
          final panelHeight = panelValue * (widget.maxHeight - widget.minHeight) + widget.minHeight;

          return Stack(
            children: [
              // ---- 背景遮罩 ----
              if (widget.backdropEnabled)
                _buildBackdropContent(containerW, containerH, panelValue),

              // ---- 滑动面板（用 Positioned 定位到对应边缘）----
              if (_isPanelVisible)
                widget.slideDirection == SnapPanelSlideDirection.up
                    ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: panelHeight,
                  child: _buildPanelContent(contentW, panelValue),
                )
                    : Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: panelHeight,
                  child: _buildPanelContent(contentW, panelValue),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackdropContent(double containerW, double containerH, double panelValue) {
    if (widget.backdropOpacity == 0) {
      return const SizedBox.shrink();
    }

    // 遮罩透明度跟随面板位置：面板收起时透明，展开时达到最大Opacity
    // clamp 防止弹簧动画过冲导致负值（如 -0.000005 * 0.4 = -0.000002）
    final opacity = (panelValue * widget.backdropOpacity).clamp(0.0, 1.0);

    return IgnorePointer(
      ignoring: opacity == 0,
      child: GestureDetector(
        onTap: widget.backdropTapClosesPanel
            ? () => widget.controller?.collapse()
            : null,
        child: Container(
          height: containerH,
          width: containerW,
          color: widget.backdropColor.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildPanelContent(double contentW, double panelValue) {
    final panelHeight = panelValue * (widget.maxHeight - widget.minHeight) + widget.minHeight;

    Widget panelContent = _buildPanelContentStack(contentW, panelValue);

    // 面板装饰
    if (widget.renderPanelSheet) {
      panelContent = _wrapPanelDecoration(panelContent, panelHeight);
    }

    // 拖拽手势
    if (widget.isDraggable) {
      panelContent = _wrapGesture(panelContent);
    }

    return panelContent;
  }

  Widget _buildPanelContentStack(double contentW, double panelValue) {
    return SizedBox(
      height: widget.maxHeight,
      width: contentW,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 展开内容
          Positioned(
            top: widget.slideDirection == SnapPanelSlideDirection.up ? 0.0 : null,
            bottom: widget.slideDirection == SnapPanelSlideDirection.down ? 0.0 : null,
            width: contentW,
            height: widget.maxHeight,
            child: widget.panel ?? widget.panelBuilder!(_sc),
          ),

          // 拖拽手柄
          if (widget.dragHandle != null)
            Positioned(
              top: widget.slideDirection == SnapPanelSlideDirection.up ? 0.0 : null,
              bottom: widget.slideDirection == SnapPanelSlideDirection.down ? 0.0 : null,
              width: contentW,
              child: widget.dragHandle!,
            ),

          // Header
          if (widget.header != null)
            Positioned(
              top: widget.slideDirection == SnapPanelSlideDirection.up ? 0.0 : null,
              bottom: widget.slideDirection == SnapPanelSlideDirection.down ? 0.0 : null,
              width: contentW,
              child: widget.header!,
            ),

          // 收起态内容
          // 0.0 ~ firstSnapPoint: opacity 从 1.0 渐变到 0.0
          // firstSnapPoint ~ 1.0: opacity = 0（不显示）
          if (widget.collapsed != null)
            Positioned(
              top: widget.slideDirection == SnapPanelSlideDirection.up ? 0.0 : null,
              bottom: widget.slideDirection == SnapPanelSlideDirection.down ? 0.0 : null,
              width: contentW,
              height: widget.minHeight,
              child: _buildCollapsedWithFade(panelValue),
            ),
        ],
      ),
    );
  }

  /// 构建收起态内容的透明度动画
  ///
  /// 动画规则（假设停靠点为 0.0, 0.3, 1.0）：
  /// - 0.0 ~ firstSnapPoint: opacity 从 1.0 渐变到 0.0
  ///   - panelValue = 0.0 时 opacity = 1.0（完全不透明）
  ///   - panelValue = firstSnapPoint 时 opacity = 0.0（完全透明）
  /// - firstSnapPoint ~ 1.0: opacity = 0.0（不显示）
  ///
  /// 如果没有自定义停靠点（只有 0.0 和 1.0），则 firstSnapPoint = 1.0，
  /// 此时在整个范围内 opacity = 1.0（与原来行为一致）
  Widget _buildCollapsedWithFade(double panelValue) {
    // 使用缓存的第一个停靠点值
    final firstSnapPoint = _cachedFirstSnapPoint;

    // 计算透明度
    double opacity;
    if (panelValue >= firstSnapPoint) {
      // 在第一个停靠点以上，不显示
      opacity = 0.0;
    } else {
      // 在 0.0 ~ firstSnapPoint 之间，从1.0渐变到0.0
      // panelValue = 0.0 时 opacity = 1.0
      // panelValue = firstSnapPoint 时 opacity = 0.0
      opacity = 1.0 - panelValue / firstSnapPoint;
    }
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: widget.collapsed!,
    );
  }

  Widget _wrapGesture(Widget child) {
    if (widget.panel != null) {
      // 静态 panel 使用 GestureDetector（性能更好）
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (d) {
          // 每次手势开始时重置速度追踪器和累计位移
          _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
          _velocityTracker.addPosition(
            Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
            d.localPosition,
          );
          _accumulatedDragDelta = 0.0;
        },
        onVerticalDragUpdate: (d) {
          _velocityTracker.addPosition(
            Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
            d.localPosition,
          );
          _onGestureSlide(d.delta.dy);
        },
        // 注意：d.velocity 在 desktop 平台上经常返回零，
        // 所以统一用 _velocityTracker.getVelocity() 计算速度
        onVerticalDragEnd: (d) => _onGestureEnd(_velocityTracker.getVelocity()),
        child: child,
      );
    } else {
      // panelBuilder 使用 Listener（与滚动联动兼容）
      return Listener(
        onPointerDown: (event) {
          _pointerDownEvent = event;
          _isVerticalGesture = false;
          _accumulatedDragDelta = 0.0;
          // 每次手势开始时重置速度追踪器，避免残留数据影响
          _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
          _velocityTracker.addPosition(event.timeStamp, event.localPosition);
        },
        onPointerMove: (event) {
          if (_pointerDownEvent == null) return;

          if (!_isVerticalGesture) {
            // 尚未确认手势方向时，用累积位移判断
            final dx = (event.position.dx - _pointerDownEvent!.position.dx).abs();
            final dy = (event.position.dy - _pointerDownEvent!.position.dy).abs();
            if (dy > dx) {
              _isVerticalGesture = true;
              _velocityTracker.addPosition(event.timeStamp, event.localPosition);
              _onGestureSlide(event.delta.dy);
            }
          } else {
            // 已确认为垂直手势，直接追踪速度和位移
            _velocityTracker.addPosition(event.timeStamp, event.localPosition);
            _onGestureSlide(event.delta.dy);
          }
        },
        onPointerUp: (event) {
          // 只有确认为垂直手势时才处理结束
          if (_isVerticalGesture) {
            _onGestureEnd(_velocityTracker.getVelocity());
          }
          _pointerDownEvent = null;
          _isVerticalGesture = false;
        },
        onPointerCancel: (_) {
          _pointerDownEvent = null;
          _isVerticalGesture = false;
        },
        child: child,
      );
    }
  }

  Widget _wrapPanelDecoration(Widget child, double height) {
    return Container(
      height: height,
      margin: widget.margin,
      padding: widget.padding,
      decoration: _getPanelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // ==================== 控制器公开方法 ====================

  double get _panelPosition => _ac.value.clamp(0.0, 1.0);

  set _panelPosition(double value) {
    assert(value >= 0.0 && value <= 1.0);
    _ac.value = value;
  }

  bool get _isAnimating => _ac.isAnimating;
  bool get _isExpanded => _currentPanelState == SnapPanelState.expanded;

  Future<void> _animateTo(
      double target, {
        Duration? duration,
        Curve curve = Curves.easeOutCubic,
      }) async {
    assert(target >= 0.0 && target <= 1.0);

    // 如果有指定 duration，用普通动画
    if (duration != null) {
      await _ac.animateTo(
        target,
        duration: duration,
        curve: curve,
      );
      return;
    }

    // 默认用弹簧动画，手感更自然
    final velocity = _ac.velocity;
    final simulation = widget.spring.description
        .simulation(_ac.value, target, velocity);

    await _ac.animateWith(simulation);

    // 弹簧模拟由于数值积分精度限制，在接近边界（0.0 或 1.0）时
    // 可能停在极小偏移处（如 0.000005）而非精确值。
    // 动画结束后直接归位，避免影响遮罩收起状态判断。
    if (target == 0.0 || target == 1.0) {
      _ac.value = target;
    }
  }

  Future<void> _animateToSnapPoint() async {
    if (_computedSnapPoints.length <= 2) return;
    final current = _ac.value;
    double nearest = _computedSnapPoints[0];
    double minDist = double.infinity;
    for (final p in _computedSnapPoints) {
      final dist = (p - current).abs();
      if (dist < minDist) {
        minDist = dist;
        nearest = p;
      }
    }
    await _animateTo(nearest);
  }

  Future<void> _collapse() => _animateTo(0.0);

  Future<void> _hide() {
    return _ac.fling(velocity: -1.0).then((_) {
      if (mounted) setState(() => _isPanelVisible = false);
    });
  }

  Future<void> _show() {
    setState(() => _isPanelVisible = true);
    return _collapse();
  }

}

/// 扩展 SpringDescription 以提供便捷的 simulation 方法
extension SpringDescriptionExtension on SpringDescription {
  SpringSimulation simulation(double start, double end, double velocity) {
    return SpringSimulation(this, start, end, velocity);
  }
}

// ==================== 便捷默认面板组件 ====================

class SnapPanelDragHandle extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const SnapPanelDragHandle({
    super.key,
    this.color = const Color(0xFFDDDDDD),
    this.width = 36,
    this.height = 5,
    this.borderRadius = 2.5,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: margin,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}