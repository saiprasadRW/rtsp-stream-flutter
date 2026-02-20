import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_provider.dart';
import '../providers/camera_state.dart';
import '../widgets/camera_preview_widget.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start camera on screen open
    Future.microtask(() => ref.read(cameraProvider.notifier).initCamera());
  }

  @override
  void dispose() {
    ref.read(cameraProvider.notifier).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Full screen camera preview ──────────────────
            const Positioned.fill(child: CameraPreviewWidget()),

            // ── Top bar ────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(state: camState),
            ),

            // ── Bottom controls ────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomControls(state: camState),
            ),

            // ── Error banner ───────────────────────────────
            if (camState.error != null)
              Positioned(
                top: 60,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(camState.error!,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final CameraState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: state.status == CameraStatus.streaming
                  ? Colors.red
                  : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              state.status == CameraStatus.streaming
                  ? '● LIVE'
                  : state.status.name.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          // Frame counter
          Text(
            '${state.frameCount} frames',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 12),
          // Resolution toggle
          GestureDetector(
            onTap: () {
              final newRes = state.resolution == "1080p" ? "4K" : "1080p";
              ref.read(cameraProvider.notifier).setResolution(newRes);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(state.resolution,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends ConsumerWidget {
  final CameraState state;
  const _BottomControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cameraProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FilterChip(
                label: 'Normal',
                selected: state.activeFilter == FrameFilter.none,
                onTap: () => notifier.setFilter(FrameFilter.none),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Grayscale',
                selected: state.activeFilter == FrameFilter.grayscale,
                onTap: () => notifier.setFilter(FrameFilter.grayscale),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Brightness',
                selected: state.activeFilter == FrameFilter.brightness,
                onTap: () => notifier.setFilter(FrameFilter.brightness),
              ),
            ],
          ),

          // Brightness slider (only when filter is brightness)
          if (state.activeFilter == FrameFilter.brightness) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.brightness_low, color: Colors.white70),
                Expanded(
                  child: Slider(
                    value: state.brightness.toDouble(),
                    min: -255,
                    max: 255,
                    divisions: 510,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (v) => notifier.setBrightness(v.toInt()),
                  ),
                ),
                const Icon(Icons.brightness_high, color: Colors.white70),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Camera flip button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, size: 32),
                color: Colors.white,
                onPressed: () => notifier.flipCamera(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
