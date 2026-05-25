import 'package:flutter/material.dart';
import 'package:ai_panel/ai_panel.dart';

class SnapSheetExample extends StatefulWidget {
  const SnapSheetExample({super.key});

  @override
  State<SnapSheetExample> createState() => _SnapSheetExampleState();
}

class _SnapSheetExampleState extends State<SnapSheetExample> {
  late SnapSheetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SnapSheetController(
      initialHeight: 0.3,
      snapPoints: SnapPoints.fourPoints,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---- 背景内容 ----
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.teal[100]!, Colors.teal[300]!],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: Colors.teal[800]),
                const SizedBox(height: 16),
                Text(
                  'SnapSheet 演示',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Text(
                    '当前高度: ${(_controller.height * 100).toInt()}%',
                    style: TextStyle(fontSize: 16, color: Colors.teal[700]),
                  ),
                ),
                const SizedBox(height: 40),
                _btn('收起', () => _controller.collapse()),
                const SizedBox(height: 8),
                _btn('30%', () => _controller.peek()),
                const SizedBox(height: 8),
                _btn('60%', () => _controller.half()),
                const SizedBox(height: 8),
                _btn('展开', () => _controller.expand()),
              ],
            ),
          ),
          // ---- SnapSheet ----
          SnapSheet(
            controller: _controller,
            initialHeight: 0.3,
            snapPoints: SnapPoints.fourPoints,
            animationDuration: const Duration(milliseconds: 350),
            backdropOpacity: 0.4,
            backgroundColor: Colors.white,
            elevation: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildSheetContent(),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal[800],
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildSheetContent() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  '地点列表',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_controller.height * 100).toInt()}%',
                      style: TextStyle(color: Colors.teal[700], fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 列表
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: 30,
              itemBuilder: (context, index) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal[100],
                  child: Icon(Icons.place, color: Colors.teal[800], size: 20),
                ),
                title: Text('地点 ${index + 1}'),
                subtitle: Text('这是地点 ${index + 1} 的描述信息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('点击了地点 ${index + 1}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}