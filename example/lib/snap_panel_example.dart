import 'package:flutter/material.dart';
import 'package:ai_panel/ai_panel.dart';

class SnapPanelExample extends StatefulWidget {
  const SnapPanelExample({super.key});

  @override
  State<SnapPanelExample> createState() => _SnapPanelExampleState();
}

class _SnapPanelExampleState extends State<SnapPanelExample> {
  final _controller = SnapPanelController();
  SnapPanelState _currentState = SnapPanelState.collapsed;
  final ValueNotifier<double> _positionNotifier = ValueNotifier<double>(0.0);

  @override
  void dispose() {
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SnapPanel(
        controller: _controller,
        minHeight: 76,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        snapPoints: const [
          SnapPanelSnapPoint(position: 0.3),
          SnapPanelSnapPoint(position: 0.6),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        backdropEnabled: true,
        backdropTapClosesPanel: true,
        backdropOpacity: 0.8,
        backdropColor: Colors.black,
        dragHandle: const SnapPanelDragHandle(),
        defaultState: SnapPanelState.collapsed,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeOutCubic,
        onPanelSlide: (pos) {
          _positionNotifier.value = pos;
        },
        onPanelStateChanged: (state) {
          setState(() => _currentState = state);
        },
        // ---- 主体内容 ----
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildInfoCard(),
            ),
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: _buildActionButtons(),
            ),
          ],
        ),
        // ---- 收起态 ----
        collapsed: _buildCollapsedBar(),
        // ---- 展开内容 ----
        panelBuilder: (scrollCtrl) => _buildPanelContent(scrollCtrl),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SnapPanel 测试',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '状态: ${_stateText(_currentState)}',
              style: const TextStyle(fontSize: 14),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _positionNotifier,
              builder: (context, pos, _) => Text(
                '位置: ${(pos * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '停靠点: 0% → 30% → 60% → 100%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _actionChip('收起', () => _controller.collapse()),
          _actionChip('30%', () => _controller.animateTo(0.3)),
          _actionChip('60%', () => _controller.animateTo(0.6)),
          _actionChip('展开', () => _controller.expand()),
          _actionChip('隐藏', () => _controller.hide()),
          _actionChip('显示', () => _controller.show()),
        ],
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.blue),
    );
  }

  Widget _buildCollapsedBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              '上滑展开面板',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelContent(ScrollController scrollCtrl) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                '列表示例',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '共 50 条数据，支持滚动',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 50,
            itemBuilder: (ctx, i) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text('${i + 1}', style: TextStyle(color: Colors.blue[800])),
              ),
              title: Text('列表项 ${i + 1}'),
              subtitle: Text('这是第 ${i + 1} 条数据的描述信息'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('点击了列表项 ${i + 1}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _stateText(SnapPanelState state) {
    switch (state) {
      case SnapPanelState.collapsed:
        return '收起 (collapsed)';
      case SnapPanelState.half:
        return '半开 (half)';
      case SnapPanelState.expanded:
        return '展开 (expanded)';
    }
  }
}