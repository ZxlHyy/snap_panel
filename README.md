# snap_panel

A highly customizable Flutter sliding panel component, similar to iOS Maps-style bottom sheet.

高度可定制的 Flutter 滑动面板组件，类似 iOS Maps 风格的底部抽屉。

[![pub package](https://img.shields.io/pub/v/snap_panel.svg)](https://pub.dev/packages/snap_panel)

![示例](https://raw.githubusercontent.com/ZxlHyy/snap_panel/main/images/snap_panel_20260615.gif)

## Features / 特性

**English:**
- **Multi-snap points** - Define custom snap points where the panel automatically docks
- **Smooth drag gestures** - Vertical dragging with velocity tracking and inertial fling
- **Spring animations** - Configurable spring physics parameters with bounce effects
- **Scroll linkage** - Seamless integration with scrollable content inside the panel
- **Background backdrop** - Optional semi-transparent overlay with tap-to-close
- **Parallax effects** - Background content follows panel movement with parallax offset
- **High performance** - Optimized with `AnimatedBuilder` + `Transform` + `RepaintBoundary`

**中文:**
- **多停靠点吸附** - 支持自定义停靠点，面板会自动吸附到最近的位置
- **流畅的拖拽手势** - 支持垂直拖拽，带有速度追踪和惯性滑动
- **弹簧动画** - 可配置的弹簧物理参数，支持回弹效果
- **滚动联动** - 面板内容与系统滚动视图无缝联动
- **背景遮罩** - 可选的半透明遮罩，点击可收起面板
- **视差效果** - 主体内容可跟随面板滑动产生视差
- **高性能** - 使用 `AnimatedBuilder` + `Transform` + `RepaintBoundary` 优化渲染

## Installation / 安装

```yaml
dependencies:
  snap_panel: ^0.0.2
```

## Quick Start / 快速开始

```dart
import 'package:snap_panel/snap_panel.dart';

SnapPanel(
  // Content to display when expanded / 展开时显示的内容
  panel: MyPanelContent(),

  // Or use Builder for scroll linkage support / 或者使用 Builder（支持滚动联动）
  // panelBuilder: (scrollController) => MyScrollableContent(controller: scrollController),

  // Collapsed state content / 收起时显示的折叠内容
  collapsed: MyCollapsedBar(),

  // Background content behind the panel / 面板背后的主体内容
  body: MyBackgroundContent(),

  // Collapsed / expanded height / 收起/展开高度
  minHeight: 80,
  maxHeight: 500,

  // Snap points (0.0 = collapsed, 1.0 = expanded) / 停靠点（0.0 = 收起, 1.0 = 展开）
  snapPoints: const [
    SnapPanelSnapPoint(position: 0.3),
    SnapPanelSnapPoint(position: 0.6),
  ],

  // Enable backdrop / 启用背景遮罩
  backdropEnabled: true,
  backdropTapClosesPanel: true,

  // Enable parallax effect / 启用视差效果
  parallaxEnabled: true,
  parallaxOffset: 0.2,

  // State change callbacks / 状态变化回调
  onPanelStateChanged: (state) {
    print('Panel state / 面板状态: $state');
  },
  onPanelSlide: (position) {
    print('Panel position / 面板位置: $position');
  },
)
```

## Controller / 控制器

```dart
final controller = SnapPanelController();

// Expand to maxHeight / 展开
controller.expand();

// Collapse to minHeight / 收起
controller.collapse();

// Animate to a specific position / 动画到指定位置
controller.animateTo(0.5);
```

## Custom Snap Points / 自定义停靠点

```dart
SnapPanelSnapPoint(
  position: 0.5, // Value between 0.0 and 1.0 / 0.0 ~ 1.0 之间的值
  onReached: (state) => true, // Callback when reached / 到达此点时触发回调
)
```

## Custom Spring Parameters / 自定义弹簧参数

```dart
spring: SnapPanelSpring(
  mass: 1.0,         // Mass / 质量, affects inertia / 影响惯性
  stiffness: 500.0,  // Stiffness / 刚度, affects snap-back speed / 影响回弹速度
  dampingRatio: 1.0, // Damping ratio / 阻尼比: 1.0=critical damping / 临界阻尼, <1.0=bouncy / 有回弹
)
```

## Widget Reference / 组件说明

| Widget / 组件 | Description / 说明 |
|--------|--------|
| `SnapPanel` | Full-featured sliding panel with snap points, backdrop, parallax, etc. / 完整的滑动面板组件，支持停靠点、遮罩、视差等 |
| `SnapPanelController` | Controller for programmatic panel manipulation / 面板控制器，用于程序化控制 |
| `SnapPanelDragHandle` | Built-in drag handle widget / 拖拽手柄组件 |
| `SnapPanelSnapPoint` | Snap point configuration / 停靠点配置 |
| `SnapPanelSpring` | Spring physics parameters / 弹簧物理参数 |
| `SnapPanelSlideDirection` | Slide direction (up / down) / 滑动方向（上/下） |
| `SnapPanelState` | Panel state (collapsed / half / expanded) / 面板状态（收起/半开/展开） |

## Architecture / 架构

```
lib/
├── src/
│   └── engine/
│       ├── snap_calculator.dart   # Snap point calculator / 停靠点计算器
│       ├── physics_engine.dart    # Physics engine / 物理引擎
│       └── gesture_engine.dart    # Gesture engine / 手势引擎
└── snap_panel.dart  # Main export / 主导出
```

## License / 许可证

MIT