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
  @override
  Widget build(BuildContext context) {
    final zoom = ref.watch(zoomProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () {
          ref.read(zoomProvider.notifier).zoomIn();
        },
        const SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true): () {
          ref.read(zoomProvider.notifier).zoomIn();
        },
        const SingleActivator(LogicalKeyboardKey.add, control: true): () {
          ref.read(zoomProvider.notifier).zoomIn();
        },
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () {
          ref.read(zoomProvider.notifier).zoomOut();
        },
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): () {
          ref.read(zoomProvider.notifier).zoomOut();
        },
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () {
          ref.read(zoomProvider.notifier).resetZoom();
        },
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true): () {
          ref.read(zoomProvider.notifier).resetZoom();
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
                } else if (pointerSignal.scrollDelta.dy > 0) {
                  ref.read(zoomProvider.notifier).zoomOut();
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

                // FittedBox correctly remaps hit-test coordinates (unlike Transform.scale
                // which only affects painting). RenderFittedBox.hitTestChildren applies
                // the inverse transform for input events, so clicks on the right/bottom
                // area work correctly when zoomed out.
                scaledContent = SizedBox(
                  width: w,
                  height: h,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: targetW,
                      height: targetH,
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

              return scaledContent;
            },
          ),
        ),
      ),
    );
  }
}


