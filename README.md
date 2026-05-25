# ai_panel

[中文文档](README_CN.md)

A highly customizable Flutter sliding panel component, similar to iOS Maps-style bottom sheet.

## Features

- **Multi-snap points** - Define custom snap points where the panel automatically docks
- **Smooth drag gestures** - Vertical dragging with velocity tracking and inertial fling
- **Spring animations** - Configurable spring physics parameters with bounce effects
- **Scroll linkage** - Seamless integration with scrollable content inside the panel
- **Background backdrop** - Optional semi-transparent overlay with tap-to-close
- **Parallax effects** - Background content follows panel movement with parallax offset
- **High performance** - Optimized with `AnimatedBuilder` + `Transform` + `RepaintBoundary`

## Installation

```yaml
dependencies:
  ai_panel: ^0.0.1
```

## Quick Start

```dart
import 'package:ai_panel/ai_panel.dart';

SnapPanel(
  // Content to display when expanded
  panel: MyPanelContent(),

  // Or use Builder for scroll linkage support
  // panelBuilder: (scrollController) => MyScrollableContent(controller: scrollController),

  // Collapsed state content
  collapsed: MyCollapsedBar(),

  // Background content behind the panel
  body: MyBackgroundContent(),

  // Collapsed / expanded height
  minHeight: 80,
  maxHeight: 500,

  // Snap points (0.0 = collapsed, 1.0 = expanded)
  snapPoints: const [
    SnapPanelSnapPoint(position: 0.3),
    SnapPanelSnapPoint(position: 0.6),
  ],

  // Enable backdrop
  backdropEnabled: true,
  backdropTapClosesPanel: true,

  // Enable parallax effect
  parallaxEnabled: true,
  parallaxOffset: 0.2,

  // State change callbacks
  onPanelStateChanged: (state) {
    print('Panel state: $state');
  },
  onPanelSlide: (position) {
    print('Panel position: $position');
  },
)
```

## Controller

```dart
final controller = SnapPanelController();

// Expand to maxHeight
controller.expand();

// Collapse to minHeight
controller.collapse();

// Animate to a specific position
controller.animateTo(0.5);

// Show / hide (completely off-screen)
controller.hide();
controller.show();
```

## Custom Snap Points

```dart
SnapPanelSnapPoint(
  position: 0.5, // Value between 0.0 and 1.0
  onReached: (state) => true, // Callback when this point is reached
)
```

## Custom Spring Parameters

```dart
spring: SnapPanelSpring(
  mass: 1.0,         // Mass, affects inertia
  stiffness: 500.0,  // Stiffness, affects snap-back speed
  dampingRatio: 1.0, // Damping ratio: 1.0=critical, <1.0=bouncy
)
```

## Widget Reference

| Widget | Description |
|--------|-------------|
| `SnapPanel` | Full-featured sliding panel with snap points, backdrop, parallax, etc. |
| `SnapPanelController` | Controller for programmatic panel manipulation |
| `SnapPanelDragHandle` | Built-in drag handle widget |
| `SnapPanelSnapPoint` | Snap point configuration |
| `SnapPanelSpring` | Spring physics parameters |
| `SnapPanelSlideDirection` | Slide direction (up / down) |
| `SnapPanelState` | Panel state (collapsed / half / expanded) |

## Architecture

```
lib/
├── src/
│   ├── widget/
│   │   └── snap_panel.dart        # Main widget
│   └── engine/
│       ├── snap_calculator.dart   # Snap point calculator
│       ├── physics_engine.dart    # Physics engine
│       └── gesture_engine.dart    # Gesture engine
└── ai_panel.dart  # Main export
```

## License

MIT