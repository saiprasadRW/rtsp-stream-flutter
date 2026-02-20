import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_provider.dart';

class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(cameraControllerProvider);
    final processedFrame = ref.watch(processedFrameProvider);

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Raw camera preview (fallback / background)
        CameraPreview(controller),

        // Processed frame overlay from Rust
        if (processedFrame != null)
          _ProcessedFrameOverlay(bytes: processedFrame),
      ],
    );
  }
}

class _ProcessedFrameOverlay extends StatelessWidget {
  final Uint8List bytes;
  const _ProcessedFrameOverlay({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true, // no flicker between frames
    );
  }
}
