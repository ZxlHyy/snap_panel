# snap_panel

高度可定制的 Flutter 滑动面板组件，类似 iOS Maps 风格的底部抽屉。

> 完整的双语文档请查看 [README.md](README.md)

## 特性

- **多停靠点吸附** - 支持自定义停靠点，面板会自动吸附到最近的位置
- **流畅的拖拽手势** - 支持垂直拖拽，带有速度追踪和惯性滑动
- **弹簧动画** - 可配置的弹簧物理参数，支持回弹效果
- **滚动联动** - 面板内容与系统滚动视图无缝联动
- **背景遮罩** - 可选的半透明遮罩，点击可收起面板
- **视差效果** - 主体内容可跟随面板滑动产生视差
- **高性能** - 使用 `AnimatedBuilder` + `Transform` + `RepaintBoundary` 优化渲染

## 安装

```yaml
dependencies:
  snap_panel: ^0.0.1
```

## 快速开始

```dart
import 'package:snap_panel/snap_panel.dart';

SnapPanel(
  // 展开时显示的内容
  panel: MyPanelContent(),

  // 或者使用 Builder（支持滚动联动）
  // panelBuilder: (scrollController) => MyScrollableContent(controller: scrollController),

  // 收起时显示的折叠内容
  collapsed: MyCollapsedBar(),

  // 面板背后的主体内容
  body: MyBackgroundContent(),

  // 收起/展开高度
  minHeight: 80,
  maxHeight: 500,

  // 停靠点（0.0 = 收起, 1.0 = 展开）
  snapPoints: const [
    SnapPanelSnapPoint(position: 0.3),
    SnapPanelSnapPoint(position: 0.6),
  ],

  // 启用背景遮罩
  backdropEnabled: true,
  backdropTapClosesPanel: true,

  // 启用视差效果
  parallaxEnabled: true,
  parallaxOffset: 0.2,

  // 状态变化回调
  onPanelStateChanged: (state) {
    print('面板状态: $state');
  },
  onPanelSlide: (position) {
    print('面板位置: $position');
  },
)
```

## 控制器

```dart
final controller = SnapPanelController();

// 展开
controller.expand();

// 收起
controller.collapse();

// 动画到指定位置
controller.animateTo(0.5);
```

## 自定义停靠点

```dart
SnapPanelSnapPoint(
  position: 0.5, // 0.0 ~ 1.0 之间的值
  onReached: (state) => true, // 到达此点时是否触发回调
)
```

## 自定义弹簧参数

```dart
spring: SnapPanelSpring(
  mass: 1.0,         // 质量，影响惯性
  stiffness: 500.0,  // 刚度，影响回弹速度
  dampingRatio: 1.0, // 阻尼比，1.0=临界阻尼，<1.0=有回弹
)
```

## 组件说明

| 组件 | 说明 |
|------|------|
| `SnapPanel` | 完整的滑动面板组件，支持停靠点、遮罩、视差等 |
| `SnapPanelController` | 面板控制器，用于程序化控制 |
| `SnapPanelDragHandle` | 拖拽手柄组件 |
| `SnapPanelSnapPoint` | 停靠点配置 |
| `SnapPanelSpring` | 弹簧物理参数 |
| `SnapPanelSlideDirection` | 滑动方向（上/下） |
| `SnapPanelState` | 面板状态（收起/半开/展开） |

## 架构

```
lib/
├── src/
│   └── engine/
│       ├── snap_calculator.dart   # 停靠点计算器
│       ├── physics_engine.dart    # 物理引擎
│       └── gesture_engine.dart    # 手势引擎
└── snap_panel.dart  # 主导出
```

## 许可证

MIT