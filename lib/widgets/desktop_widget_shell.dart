import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

// 바탕화면 위젯 모드의 창 틀: 위쪽 드래그바(이동/투명도/종료) + 가장자리 리사이즈 영역.
// 프레임 없는 창에서 이동/크기조정은 window_manager의 startDragging/startResizing이 담당한다.
class DesktopWidgetShell extends StatelessWidget {
  final Widget child;
  final double opacity;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onExit;

  const DesktopWidgetShell({
    super.key,
    required this.child,
    required this.opacity,
    required this.onOpacityChanged,
    required this.onExit,
  });

  static const _edge = 6.0;

  @override
  Widget build(BuildContext context) {
    // 창 자체는 픽셀 단위 투명 모드로 설정되어 있으므로(main.dart의 acrylic.Window.setEffect),
    // 여기서 배경만 알파를 조절하면 그 위에 그려지는 달력 격자/숫자/텍스트는 항상 불투명하게 유지된다.
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: backgroundColor.withValues(alpha: opacity)),
          ),
          Column(
            children: [
              _DragBar(
                opacity: opacity,
                onOpacityChanged: onOpacityChanged,
                onExit: onExit,
              ),
              Expanded(child: child),
            ],
          ),
          _resizeHandle(top: 0, left: _edge, right: _edge, height: _edge,
              cursor: SystemMouseCursors.resizeUpDown, edge: ResizeEdge.top),
          _resizeHandle(bottom: 0, left: _edge, right: _edge, height: _edge,
              cursor: SystemMouseCursors.resizeUpDown, edge: ResizeEdge.bottom),
          _resizeHandle(left: 0, top: _edge, bottom: _edge, width: _edge,
              cursor: SystemMouseCursors.resizeLeftRight, edge: ResizeEdge.left),
          _resizeHandle(right: 0, top: _edge, bottom: _edge, width: _edge,
              cursor: SystemMouseCursors.resizeLeftRight, edge: ResizeEdge.right),
          _resizeHandle(top: 0, left: 0, width: _edge, height: _edge,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              edge: ResizeEdge.topLeft),
          _resizeHandle(top: 0, right: 0, width: _edge, height: _edge,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              edge: ResizeEdge.topRight),
          _resizeHandle(bottom: 0, left: 0, width: _edge, height: _edge,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              edge: ResizeEdge.bottomLeft),
          _resizeHandle(bottom: 0, right: 0, width: _edge, height: _edge,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              edge: ResizeEdge.bottomRight),
        ],
      ),
    );
  }

  Widget _resizeHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
    required MouseCursor cursor,
    required ResizeEdge edge,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startResizing(edge),
        ),
      ),
    );
  }
}

class _DragBar extends StatelessWidget {
  final double opacity;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onExit;

  const _DragBar({
    required this.opacity,
    required this.onOpacityChanged,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 30,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.drag_indicator, size: 16),
            const SizedBox(width: 8),
            const Icon(Icons.opacity, size: 14),
            Expanded(
              child: Slider(
                value: opacity,
                min: 0.2,
                max: 1.0,
                onChanged: onOpacityChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              tooltip: '위젯 모드 종료',
              onPressed: onExit,
            ),
          ],
        ),
      ),
    );
  }
}
