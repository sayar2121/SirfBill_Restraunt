import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/zoom_provider.dart';

class AppZoomWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppZoomWrapper({super.key, required this.child});

  @override
  ConsumerState<AppZoomWrapper> createState() => _AppZoomWrapperState();
}

class _AppZoomWrapperState extends ConsumerState<AppZoomWrapper> {
  bool _showIndicator = false;
  Timer? _hideTimer;
  double _lastZoom = 1.0;

  void _triggerIndicator() {
    if (mounted) {
      setState(() {
        _showIndicator = true;
      });
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _showIndicator = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoom = ref.watch(zoomProvider);

    // If zoom changed, trigger floating indicator
    if (zoom != _lastZoom) {
      _lastZoom = zoom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerIndicator();
      });
    }

    final percentage = (zoom * 100).round();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () {
          ref.read(zoomProvider.notifier).zoomIn();
          _triggerIndicator();
        },
        const SingleActivator(LogicalKeyboardKey.add, control: true): () {
          ref.read(zoomProvider.notifier).zoomIn();
          _triggerIndicator();
        },
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () {
          ref.read(zoomProvider.notifier).zoomOut();
          _triggerIndicator();
        },
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): () {
          ref.read(zoomProvider.notifier).zoomOut();
          _triggerIndicator();
        },
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () {
          ref.read(zoomProvider.notifier).resetZoom();
          _triggerIndicator();
        },
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true): () {
          ref.read(zoomProvider.notifier).resetZoom();
          _triggerIndicator();
        },
      },
      child: Focus(
        autofocus: true,
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
              if (isCtrlPressed) {
                if (pointerSignal.scrollDelta.dy < 0) {
                  ref.read(zoomProvider.notifier).zoomIn();
                  _triggerIndicator();
                } else if (pointerSignal.scrollDelta.dy > 0) {
                  ref.read(zoomProvider.notifier).zoomOut();
                  _triggerIndicator();
                }
              }
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              Widget scaledContent = widget.child;

              if (zoom != 1.0) {
                final targetW = w / zoom;
                final targetH = h / zoom;

                scaledContent = SizedBox(
                  width: w,
                  height: h,
                  child: Transform.scale(
                    scale: zoom,
                    alignment: Alignment.topLeft,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: targetW,
                      maxWidth: targetW,
                      minHeight: targetH,
                      maxHeight: targetH,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: Size(targetW, targetH),
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  scaledContent,

                  // Floating HUD Zoom Indicator (appears on zoom change or mouse hover)
                  Positioned(
                    top: 14,
                    right: 180,
                    child: MouseRegion(
                      onEnter: (_) => _triggerIndicator(),
                      child: AnimatedOpacity(
                        opacity: _showIndicator ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: !_showIndicator,
                          child: Material(
                            elevation: 8,
                            shadowColor: Colors.black38,
                            borderRadius: BorderRadius.circular(24),
                            color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Zoom Out
                                  IconButton(
                                    constraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 16),
                                    tooltip: 'Zoom Out (Ctrl -)',
                                    onPressed: () {
                                      ref.read(zoomProvider.notifier).zoomOut();
                                      _triggerIndicator();
                                    },
                                  ),
                                  const SizedBox(width: 4),

                                  // Percentage / Reset
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      ref.read(zoomProvider.notifier).resetZoom();
                                      _triggerIndicator();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.zoom_in_rounded, color: Color(0xFF10B981), size: 15),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$percentage%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Zoom In
                                  IconButton(
                                    constraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                    tooltip: 'Zoom In (Ctrl +)',
                                    onPressed: () {
                                      ref.read(zoomProvider.notifier).zoomIn();
                                      _triggerIndicator();
                                    },
                                  ),
                                  const SizedBox(width: 4),

                                  // Reset button if not 100%
                                  if (percentage != 100) ...[
                                    Container(
                                      width: 1,
                                      height: 14,
                                      color: Colors.white24,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        ref.read(zoomProvider.notifier).resetZoom();
                                        _triggerIndicator();
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          'Reset',
                                          style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

