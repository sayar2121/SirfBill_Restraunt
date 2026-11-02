import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Wraps any horizontal scroll area to enable:
/// 1. Laptop touchpad two-finger horizontal scrolling (PointerScrollEvent / PointerPanZoomUpdateEvent)
/// 2. Mouse click-and-drag horizontal scrolling
/// 3. Shift + mouse wheel horizontal scrolling
class HorizontalMouseTouchpadScroll extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const HorizontalMouseTouchpadScroll({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<HorizontalMouseTouchpadScroll> createState() =>
      _HorizontalMouseTouchpadScrollState();
}

class _HorizontalMouseTouchpadScrollState
    extends State<HorizontalMouseTouchpadScroll> {
  int? _activePointer;
  Offset? _startOffset;
  Offset? _lastOffset;
  bool _isDragging = false;
  bool _dragLocked = false;

  void _scrollBy(double delta) {
    if (!widget.controller.hasClients || widget.controller.positions.length != 1) {
      return;
    }
    final position = widget.controller.position;
    final double current = position.pixels;
    final double min = position.minScrollExtent;
    final double max = position.maxScrollExtent;
    final double target = (current + delta).clamp(min, max);
    if (target != current) {
      widget.controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // Track left-click or trackpad/touch contact
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons != kPrimaryMouseButton) {
          return;
        }
        _activePointer = event.pointer;
        _startOffset = event.position;
        _lastOffset = event.position;
        _isDragging = false;
        _dragLocked = false;
      },
      onPointerMove: (event) {
        if (event.pointer != _activePointer || _startOffset == null || _lastOffset == null) {
          return;
        }

        final double dxTotal = event.position.dx - _startOffset!.dx;
        final double dyTotal = event.position.dy - _startOffset!.dy;

        if (!_dragLocked) {
          if (dxTotal.abs() > 6 || dyTotal.abs() > 6) {
            _dragLocked = true;
            // Only engage horizontal drag if horizontal intent exceeds vertical
            if (dxTotal.abs() >= dyTotal.abs()) {
              _isDragging = true;
              _lastOffset = event.position;
            } else {
              _isDragging = false;
            }
          }
        }

        if (_isDragging) {
          final double deltaX = event.position.dx - _lastOffset!.dx;
          _lastOffset = event.position;
          // Dragging left moves scroll right (natural drag)
          _scrollBy(-deltaX);
        }
      },
      onPointerUp: (event) {
        if (event.pointer == _activePointer) {
          _activePointer = null;
          _startOffset = null;
          _lastOffset = null;
          _isDragging = false;
          _dragLocked = false;
        }
      },
      onPointerCancel: (event) {
        if (event.pointer == _activePointer) {
          _activePointer = null;
          _startOffset = null;
          _lastOffset = null;
          _isDragging = false;
          _dragLocked = false;
        }
      },
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          double dx = pointerSignal.scrollDelta.dx;
          // Support Shift + mouse wheel for horizontal scrolling
          if (dx == 0 && HardwareKeyboard.instance.isShiftPressed) {
            dx = pointerSignal.scrollDelta.dy;
          }
          if (dx != 0) {
            _scrollBy(dx);
          }
        }
      },
      onPointerPanZoomUpdate: (event) {
        // Trackpad two-finger pan gesture on Mac/Chrome
        if (event.panDelta.dx != 0) {
          _scrollBy(-event.panDelta.dx);
        }
      },
      child: widget.child,
    );
  }
}
