# SnapSheet - Flutter 高性能 Bottom Sheet 组件

类似 iOS Maps 的高性能 Bottom Sheet 组件，支持拖拽、snap points、velocity fling 等功能。

## 特性

✅ 使用 Stack 作为根布局，避免 Flex 布局问题
✅ 高性能：使用 AnimationController，避免每帧 rebuild
✅ 支持拖拽手势控制高度
✅ 支持 snap points（可自定义）
✅ 支持 velocity fling
✅ 支持控制器（animateTo / collapse / expand）
✅ 支持 backdrop
✅ 支持任意内容（ListView / Column / ScrollView）
✅ 避免 RenderFlex overflow

## 架构设计

### 核心组件

- **SnapSheet**: 主组件，负责 UI 渲染和手势处理
- **SnapSheetController**: 控制器，负责管理状态和动画
- **SnapPoints**: 预定义的 snap point 常量

### 性能优化

1. 使用 `AnimatedBuilder` 而非 `setState` 来更新 UI
2. 拖拽过程中只更新动画值，不触发 rebuild
3. 使用 Stack + Positioned 布局避免 Flex 布局的 overflow 问题
4. AnimationController 驱动所有动画

## 基本用法

```dart
import 'package:ai_panel/snap_sheet.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SnapSheetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SnapSheetController(
      initialHeight: SnapPoints.peek,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景内容
          Container(color: Colors.blue[100]),

          // SnapSheet
          SnapSheet(
            controller: _controller,
            snapPoints: SnapPoints.threePoints, // [0.0, 0.5, 1.0]
            child: _buildSheetContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent() {
    return Column(
      children: [
        // 头部
        Container(padding: EdgeInsets.all(16), child: Text('标题')),
        // 内容列表
        Expanded(
          child: ListView.builder(
            itemCount: 50,
            itemBuilder: (context, index) => ListTile(
              title: Text('项目 $index'),
            ),
          ),
        ),
      ],
    );
  }
}
```

## API 文档

### SnapSheet 属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `child` | `Widget` | 必填 | 底部表单的主要内容 |
| `controller` | `SnapSheetController?` | `null` | 控制器，如果为空则内部创建 |
| `backdrop` | `Widget?` | `null` | 自定义背景遮罩，为空则使用默认 |
| `handle` | `Widget?` | `null` | 自定义拖拽手柄，为空则使用默认 |
| `enableDrag` | `bool` | `true` | 是否启用拖拽 |
| `snapPoints` | `List<double>` | `SnapPoints.defaultSnapPoints` | 停靠点列表 |
| `initialHeight` | `double` | `0.3` | 初始高度 (0.0-1.0) |
| `animationDuration` | `Duration` | `300ms` | 动画持续时间 |
| `backdropOpacity` | `double` | `0.5` | 背景遮罩透明度 |
| `borderRadius` | `BorderRadius` | `顶部圆角16` | 边框圆角 |
| `backgroundColor` | `Color` | `Colors.white` | 背景颜色 |
| `elevation` | `double` | `8.0` | 阴影高度 |

### SnapSheetController 方法

| 方法 | 说明 |
|------|------|
| `animateTo(double height, {Duration? duration})` | 动画到指定高度 |
| `expand()` | 展开到最大高度 (1.0) |
| `collapse()` | 收起 (0.0) |
| `peek()` | 到预览位置 (0.3) |
| `half()` | 到一半位置 (0.6) |
| `updateHeight(double height)` | 直接更新高度（用于拖拽） |
| `startDrag()` | 开始拖拽 |
| `endDrag()` | 结束拖拽并自动停靠 |

### SnapPoints 预定义

```dart
// 默认：只有收起和展开两个状态
SnapPoints.defaultSnapPoints = [0.0, 1.0]

// 三个状态：收起、中间、展开
SnapPoints.threePoints = [0.0, 0.5, 1.0]

// 四个状态：收起、预览、一半、展开
SnapPoints.fourPoints = [0.0, 0.3, 0.6, 1.0]
```

## 高级用法

### 自定义 snap points

```dart
SnapSheet(
  controller: _controller,
  snapPoints: [0.0, 0.25, 0.75, 1.0], // 自定义停靠点
  child: MyContent(),
)
```

### 监听高度变化

```dart
_controller.addListener(() {
  print('当前高度: ${_controller.height}');
});
```

### 程序控制动画

```dart
// 展开到指定位置
await _controller.animateTo(0.7);

// 展开到最大
await _controller.expand();

// 收起
await _controller.collapse();
```

### 自定义样式

```dart
SnapSheet(
  backgroundColor: Colors.grey[100],
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  elevation: 16,
  backdropOpacity: 0.3,
  child: MyContent(),
)
```

## 性能注意事项

1. **避免在内容中使用 Expanded/Flexible**：由于使用 Stack 布局，内容内部可以使用 Expanded
2. **使用 const 构造函数**：对于静态内容使用 const 构造函数减少重建
3. **合理设置 snap points**：避免过多的停靠点影响性能
4. **内容高度自适应**：内容会根据 snapSheet 的高度自动调整

## 常见问题

### Q: 如何处理内容溢出？
A: SnapSheet 会自动根据当前高度调整内容区域大小，内部使用 SizedBox 限制高度。

### Q: 如何与页面其他手势共存？
A: SnapSheet 只在组件区域内响应拖拽手势，不会影响页面其他区域的交互。

### Q: 如何自定义动画曲线？
A: 目前使用固定的 `Curves.easeOutCubic`，后续版本会支持自定义。

## 示例

查看 `example/lib/snap_sheet_example.dart` 获取完整的示例代码。