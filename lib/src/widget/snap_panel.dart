// 高度可定制的滑动面板组件

import 'package:flutter/material.dart';

import '../engine/snap_calculator.dart';
import '../engine/physics_engine.dart';
import '../engine/gesture_engine.dart';

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

  /// 当前面板状态（从 position 派生，单一数据源）
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
        Curve curve = Curves.easeOut,
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
    this.animationCurve = Curves.easeOut,
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

  /// 内部滚动是否启用
  bool _scrollingEnabled = false;

  // ==================== 引擎实例 ====================

  /// 停靠点计算器
  final SnapCalculator _snapCalculator = SnapCalculator();

  /// 物理引擎
  late PhysicsEngine _physicsEngine;

  /// 手势引擎
  final GestureEngine _gestureEngine = GestureEngine();

  // ==================== 缓存 ====================

  /// 缓存的面板内容（避免 panelBuilder 重复构建）
  Widget? _cachedPanelContent;

  /// 缓存的装饰参数
  BoxDecoration? _cachedDecoration;
  List<BoxShadow>? _cachedBoxShadow;
  Border? _cachedBorder;
  BorderRadiusGeometry? _cachedBorderRadius;
  Color? _cachedColor;
  double? _cachedElevation;

  /// 缓存的容器尺寸
  double _cachedContainerW = 0.0;
  double _cachedContainerH = 0.0;
  double _cachedContentW = 0.0;
  EdgeInsetsGeometry? _cachedMargin;
  EdgeInsetsGeometry? _cachedPadding;

  @override
  void initState() {
    super.initState();

    _snapCalculator.compute(widget.snapPoints);
    _physicsEngine = PhysicsEngine(spring: widget.spring);

    _ac = AnimationController.unbounded(
      vsync: this,
      value: _snapCalculator.stateToValue(widget.defaultState),
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
      _snapCalculator.compute(widget.snapPoints);
    }

    // 弹簧参数变化时更新物理引擎
    if (oldWidget.spring.mass != widget.spring.mass ||
        oldWidget.spring.stiffness != widget.spring.stiffness ||
        oldWidget.spring.dampingRatio != widget.spring.dampingRatio) {
      _physicsEngine = PhysicsEngine(spring: widget.spring);
    }

    // 默认状态变化时更新
    if (oldWidget.defaultState != widget.defaultState && mounted) {
      final targetValue = _snapCalculator.stateToValue(widget.defaultState);
      _ac.animateTo(targetValue, duration: widget.animationDuration, curve: widget.animationCurve);
    }

    // 控制器变化时重新绑定
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }

    // 内容变化时清除缓存
    if (oldWidget.panel != widget.panel ||
        oldWidget.panelBuilder != widget.panelBuilder) {
      _cachedPanelContent = null;
    }

    // 装饰变化时清除缓存
    if (oldWidget.color != widget.color ||
        oldWidget.border != widget.border ||
        oldWidget.borderRadius != widget.borderRadius ||
        oldWidget.boxShadow != widget.boxShadow ||
        oldWidget.elevation != widget.elevation) {
      _cachedDecoration = null;
      _cachedBoxShadow = null;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _ac.dispose();
    _sc.dispose();
    super.dispose();
  }

  // ==================== 属性访问器 ====================

  /// 当前面板位置（单一数据源）
  double get _panelPosition => _ac.value.clamp(0.0, 1.0);

  set _panelPosition(double value) {
    assert(value >= 0.0 && value <= 1.0);
    _ac.value = value;
  }

  /// 当前面板状态（从 position 派生，不单独存储）
  SnapPanelState get _currentPanelState {
    final state = _snapCalculator.getStateFromPosition(_panelPosition);
    return state ?? SnapPanelState.half; // 默认返回 half
  }

  bool get _isAnimating => _ac.isAnimating;
  bool get _isExpanded => _currentPanelState == SnapPanelState.expanded;

  // ==================== 动画监听 ====================

  void _onAnimationTick() {
    final position = _panelPosition;
    widget.onPanelSlide?.call(position);

    // 检测是否到达某个停靠点
    _checkSnapPointReached(position);
  }

  void _checkSnapPointReached(double position) {
    final newState = _snapCalculator.getStateFromPosition(position);
    if (newState == null) return;

    // 使用 controller 获取之前的状态
    final oldState = widget.controller?.panelState ?? _currentPanelState;
    if (newState == oldState) return;

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
    // 累计拖拽位移
    _gestureEngine.addDragDelta(dy);

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

    // 使用物理引擎计算方向和速度
    final result = _physicsEngine.calculateDirection(
      velocityPixelsPerSecond: dy,
      panelRange: panelRange,
      accumulatedDragDelta: _gestureEngine.accumulatedDragDelta,
      slideDirection: widget.slideDirection,
    );

    // 重置累计位移
    _gestureEngine.resetAccumulatedDelta();

    if (result.direction == 0) return;

    // 根据方向找目标停靠点
    final target = _snapCalculator.findTargetSnap(currentValue, result.direction);

    // 如果目标就是当前位置（已到边界），不做任何动画
    if ((target - currentValue).abs() < 0.01) return;

    _flingTo(target, result.speed);
  }

  /// 用 fling 动画抛到目标停靠点
  Future<void> _flingTo(double target, double visualVelocity) async {
    final distance = (_ac.value - target).abs();
    // 如果距离目标已经很近，直接跳转，避免无意义动画
    if (distance < 0.01) {
      _ac.value = target;
      return;
    }

    // 使用物理引擎创建弹簧模拟
    final simulation = _physicsEngine.createSpringSimulation(
      currentValue: _ac.value,
      targetValue: target,
      visualVelocity: visualVelocity,
    );

    await _ac.animateWith(simulation);

    // 动画结束后精确归位到目标停靠点
    _ac.value = target;
  }

  // ==================== 构建 ====================

  @override
  Widget build(BuildContext context) {
    // 缓存容器尺寸，避免每帧重复计算
    if (_cachedContainerW == 0 || _cachedMargin != widget.margin || _cachedPadding != widget.padding) {
      _cachedMargin = widget.margin;
      _cachedPadding = widget.padding;
      final containerSize = MediaQuery.of(context).size;
      _cachedContainerW = containerSize.width;
      _cachedContainerH = containerSize.height;
      final marginH = widget.margin?.horizontal ?? 0.0;
      final paddingH = widget.padding?.horizontal ?? 0.0;
      _cachedContentW = _cachedContainerW - marginH - paddingH;
    }

    return Stack(
      children: [
        // ---- 主体内容 ----
        if (widget.body != null) _buildBody(_cachedContainerW, _cachedContainerH),

        // ---- 背景遮罩（独立动画层）----
        if (widget.backdropEnabled)
          _buildBackdropLayer(_cachedContainerW, _cachedContainerH),

        // ---- 滑动面板（独立动画层）----
        if (_isPanelVisible)
          _buildPanelLayer(_cachedContainerW, _cachedContainerH, _cachedContentW),
      ],
    );
  }

  Widget _buildBody(double containerW, double containerH) {
    // 视差效果使用 AnimatedBuilder 替代 ValueListenableBuilder
    if (widget.parallaxEnabled) {
      return AnimatedBuilder(
        animation: _ac,
        builder: (context, child) {
          final panelValue = _ac.value;
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
            child: widget.body,
          ),
        ),
      );
    }

    // 无视差时直接返回，无需监听动画
    return Positioned.fill(
      child: SizedBox(
        width: containerW,
        height: containerH,
        child: widget.body,
      ),
    );
  }

  /// 独立遮罩动画层
  ///
  /// 优化：遮罩和面板分离，互不影响 rebuild
  Widget _buildBackdropLayer(double containerW, double containerH) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        final opacity = (_ac.value * widget.backdropOpacity).clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: opacity == 0,
          child: GestureDetector(
            onTap: widget.backdropTapClosesPanel
                ? () => widget.controller?.collapse()
                : null,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          ),
        );
      },
      child: RepaintBoundary(
        child: Container(
          height: containerH,
          width: containerW,
          color: widget.backdropColor,
        ),
      ),
    );
  }

  /// 独立面板动画层
  ///
  /// 优化：面板内容只构建一次，通过 child 参数缓存
  Widget _buildPanelLayer(double containerW, double containerH, double contentW) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: widget.maxHeight,
      child: AnimatedBuilder(
        animation: _ac,
        builder: (context, child) {
          // 计算当前可见面板高度
          final panelHeight = _ac.value * (widget.maxHeight - widget.minHeight) + widget.minHeight;
          // 向下平移距离 = maxHeight - panelHeight
          final offsetY = widget.maxHeight - panelHeight;
          return ClipRect(
            child: Transform.translate(
              offset: Offset(0, offsetY),
              child: child,
            ),
          );
        },
        child: RepaintBoundary(
          child: _buildPanelContentStatic(contentW),
        ),
      ),
    );
  }

  /// 构建静态面板内容（只构建一次，不依赖 panelValue）
  Widget _buildPanelContentStatic(double contentW) {
    final stack = SizedBox(
      height: widget.maxHeight,
      width: contentW,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 展开内容（使用缓存）
          Positioned(
            top: widget.slideDirection == SnapPanelSlideDirection.up ? 0.0 : null,
            bottom: widget.slideDirection == SnapPanelSlideDirection.down ? 0.0 : null,
            width: contentW,
            height: widget.maxHeight,
            child: _cachedPanelContent ??=
                (widget.panel ?? widget.panelBuilder!(_sc)),
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

          // 收起态内容 - 内部独立监听动画值
          if (widget.collapsed != null)
            Positioned(
              top: widget.slideDirection == SnapPanelSlideDirection.up ? 0.0 : null,
              bottom: widget.slideDirection == SnapPanelSlideDirection.down ? 0.0 : null,
              width: contentW,
              height: widget.minHeight,
              child: AnimatedBuilder(
                animation: _ac,
                builder: (context, child) =>
                    _buildCollapsedWithFade(_ac.value, child),
                child: widget.collapsed!,
              ),
            ),
        ],
      ),
    );

    // 面板装饰
    Widget result = stack;
    if (widget.renderPanelSheet) {
      result = _wrapPanelDecoration(result);
    }

    // 拖拽手势
    if (widget.isDraggable) {
      result = _wrapGesture(result);
    }

    return result;
  }

  /// 构建收起态内容的透明度动画
  Widget _buildCollapsedWithFade(double panelValue, Widget? child) {
    final firstSnapPoint = _snapCalculator.firstSnapPoint;

    double opacity;
    if (panelValue >= firstSnapPoint) {
      opacity = 0.0;
    } else {
      opacity = 1.0 - panelValue / firstSnapPoint;
    }
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: child ?? const SizedBox.shrink(),
    );
  }

  Widget _wrapGesture(Widget child) {
    if (widget.panel != null) {
      // 静态 panel 使用 GestureDetector（性能更好）
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (d) {
          _gestureEngine.reset();
          _gestureEngine.addDragPosition(
            Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
            d.localPosition,
          );
        },
        onVerticalDragUpdate: (d) {
          _gestureEngine.addDragPosition(
            Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
            d.localPosition,
          );
          _onGestureSlide(d.delta.dy);
        },
        onVerticalDragEnd: (d) => _onGestureEnd(_gestureEngine.getVelocity()),
        child: child,
      );
    } else {
      // panelBuilder 使用 Listener（与滚动联动兼容）
      return Listener(
        onPointerDown: (event) {
          _gestureEngine.startGesture(event);
        },
        onPointerMove: (event) {
          if (_gestureEngine.updateGesture(event)) {
            _onGestureSlide(event.delta.dy);
          }
        },
        onPointerUp: (event) {
          if (_gestureEngine.isVerticalGesture) {
            _onGestureEnd(_gestureEngine.getVelocity());
          }
          _gestureEngine.endGesture();
        },
        onPointerCancel: (_) {
          _gestureEngine.endGesture();
        },
        child: child,
      );
    }
  }

  Widget _wrapPanelDecoration(Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Container(
        margin: widget.margin,
        padding: widget.padding,
        decoration: _getPanelDecoration(),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  /// 获取面板装饰（简化缓存）
  BoxDecoration _getPanelDecoration() {
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

  /// 获取默认阴影
  List<BoxShadow> _getDefaultShadow() {
    if (widget.elevation != null) {
      return [
        BoxShadow(
          blurRadius: widget.elevation! * 2,
          offset: Offset(0, -widget.elevation!),
          color: Colors.black.withValues(alpha: 0.2),
        ),
      ];
    }
    return const [
      BoxShadow(
        blurRadius: 8.0,
        color: Color.fromRGBO(0, 0, 0, 0.25),
      ),
    ];
  }

  // ==================== 控制器公开方法 ====================

  Future<void> _animateTo(
      double target, {
        Duration? duration,
        Curve curve = Curves.easeOut,
      }) async {
    assert(target >= 0.0 && target <= 1.0);

    final distance = (_ac.value - target).abs();
    if (distance < 0.005) {
      _ac.value = target;
      return;
    }

    if (duration != null) {
      await _ac.animateTo(
        target,
        duration: duration,
        curve: curve,
      );
      _ac.value = target;
      return;
    }

    final baseDuration = widget.animationDuration.inMilliseconds;
    final adjustedDuration = (baseDuration * (0.3 + 0.7 * distance)).round().clamp(100, baseDuration);

    await _ac.animateTo(
      target,
      duration: Duration(milliseconds: adjustedDuration),
      curve: Curves.easeOutCubic,
    );

    _ac.value = target;
  }

  Future<void> _animateToSnapPoint() async {
    if (_snapCalculator.computedSnapPoints.length <= 2) return;
    final nearest = _snapCalculator.findNearestSnap(_ac.value);
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