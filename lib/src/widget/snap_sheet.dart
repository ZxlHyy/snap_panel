import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../controller/snap_sheet_controller.dart';

/// A high-performance bottom sheet widget similar to iOS Maps
class SnapSheet extends StatefulWidget {
  const SnapSheet({
    Key? key,
    required this.child,
    this.controller,
    this.backdrop,
    this.handle,
    this.enableDrag = true,
    this.snapPoints = SnapPoints.defaultSnapPoints,
    this.initialHeight = 0.3,
    this.animationDuration = const Duration(milliseconds: 300),
    this.backdropOpacity = 0.5,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
    this.backgroundColor = Colors.white,
    this.elevation = 8.0,
  }) : super(key: key);

  /// The main content of the bottom sheet
  final Widget child;

  /// Controller for the bottom sheet
  final SnapSheetController? controller;

  /// Optional backdrop widget (usually a semi-transparent container)
  final Widget? backdrop;

  /// Optional handle widget at the top of the sheet
  final Widget? handle;

  /// Whether dragging is enabled
  final bool enableDrag;

  /// Snap points for the sheet
  final List<double> snapPoints;

  /// Initial height of the sheet
  final double initialHeight;

  /// Animation duration
  final Duration animationDuration;

  /// Backdrop opacity
  final double backdropOpacity;

  /// Border radius for the sheet
  final BorderRadius borderRadius;

  /// Background color
  final Color backgroundColor;

  /// Elevation for shadow
  final double elevation;

  @override
  State<SnapSheet> createState() => _SnapSheetState();
}

class _SnapSheetState extends State<SnapSheet>
    with TickerProviderStateMixin {
  late SnapSheetController _controller;
  bool _isInternalController = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeAnimationController();
  }

  void _initializeController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = SnapSheetController(
        initialHeight: widget.initialHeight,
        snapPoints: widget.snapPoints,
      );
      _isInternalController = true;
    }
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animationController.value = widget.initialHeight;
    _controller.setAnimationController(_animationController);
  }

  @override
  void didUpdateWidget(SnapSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_isInternalController) {
        _controller.dispose();
      }
      _initializeController();
      _controller.setAnimationController(_animationController);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return _controller.height > 0
                ? GestureDetector(
                    onTap: () => _controller.collapse(),
                    child: widget.backdrop ??
                        Container(
                          color: Colors.black.withOpacity(
                            widget.backdropOpacity * _controller.height,
                          ),
                        ),
                  )
                : const SizedBox.shrink();
          },
        ),
        // Bottom Sheet
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return _buildBottomSheet(context);
          },
        ),
      ],
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final currentHeight = screenHeight * _controller.height;

    return Positioned(
      left: 0,
      right: 0,
      bottom: -screenHeight + currentHeight,
      height: screenHeight,
      child: GestureDetector(
        onPanStart: widget.enableDrag ? _onPanStart : null,
        onPanUpdate: widget.enableDrag ? _onPanUpdate : null,
        onPanEnd: widget.enableDrag ? _onPanEnd : null,
        child: Material(
          elevation: widget.elevation,
          borderRadius: widget.borderRadius,
          color: widget.backgroundColor,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: SizedBox(
              height: currentHeight,
              child: Stack(
                children: [
                  // Handle positioned at top
                  if (widget.handle != null || true) // Always show handle
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: widget.handle ?? _buildDefaultHandle(),
                    ),
                  // Content positioned below handle
                  Positioned(
                    top: 20, // Handle height + padding
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _controller.startDrag();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final deltaY = -details.delta.dy / screenHeight; // Invert Y axis
    final newHeight = (_controller.height + deltaY).clamp(0.0, 1.0);

    _controller.updateHeight(newHeight);
    _controller.updateVelocity(-details.delta.dy); // Invert for natural feel
  }

  void _onPanEnd(DragEndDetails details) {
    _controller.updateVelocity(details.velocity.pixelsPerSecond.dy);
    _controller.endDrag();
  }
}