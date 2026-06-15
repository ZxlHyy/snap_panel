## 0.0.3

> Changelog[CHANGELOG.md](CHANGELOG.md)

* snap_panel 初始版本发布
* SnapPanel: 高度可定制的滑动面板，支持多停靠点吸附
* SnapPanelController: 面板控制器，支持 expand/collapse/animateTo 等程序化控制
* SnapPanelDragHandle: 内置拖拽手柄组件
* 弹簧动画：可配置物理参数（质量/刚度/阻尼比）
* 背景遮罩：半透明遮罩层，支持点击收起面板
* 视差效果：背景内容跟随面板滑动产生视差
* 滚动联动：支持面板内滚动视图与面板拖拽的无缝联动
* 渲染优化：使用 AnimatedBuilder + Transform + RepaintBoundary 避免不必要的 rebuild