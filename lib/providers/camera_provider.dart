// ignore_for_file: invalid_use_of_internal_member

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bridge_generated.dart/frb_generated.dart'; // ← Native class
// ← FrameInfo, ProcessedFrame
import 'camera_state.dart';

// ── Available cameras list ─────────────────────────────────────────────────
final availableCamerasProvider =
    FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

// ── Camera Controller ──────────────────────────────────────────────────────
final cameraControllerProvider =
    StateProvider<CameraController?>((ref) => null);

// ── Processed frame bytes (after Rust processing) ─────────────────────────
final processedFrameProvider = StateProvider<Uint8List?>((ref) => null);

// ── Main Camera Notifier ───────────────────────────────────────────────────
class CameraNotifier extends StateNotifier<CameraState> {
  final Ref _ref;
  final NativeApi _api; // ← use NativeApi
  CameraController? _controller;

  CameraNotifier(this._ref)
      : _api = Native.instance.api, // ← get api from Native
        super(const CameraState());

  Future<void> initCamera({bool frontCamera = false}) async {
    state = state.copyWith(status: CameraStatus.initializing);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras found');

      final selected = cameras.firstWhere(
        (c) => frontCamera
            ? c.lensDirection == CameraLensDirection.front
            : c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final resolution = state.resolution == "4K"
          ? ResolutionPreset.ultraHigh
          : ResolutionPreset.veryHigh;

      _controller = CameraController(
        selected,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      _ref.read(cameraControllerProvider.notifier).state = _controller;
      await _controller!.startImageStream(_onFrameAvailable);

      state = state.copyWith(
        status: CameraStatus.streaming,
        isFrontCamera: frontCamera,
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        error: e.toString(),
      );
    }
  }

  void _onFrameAvailable(CameraImage image) async {
    final bytes = _extractBytes(image);
    if (bytes == null) return;

    try {
      final result = await _applyFilter(bytes, image.width, image.height);
      _ref.read(processedFrameProvider.notifier).state = result;
      state = state.copyWith(frameCount: state.frameCount + 1);
    } catch (_) {}
  }

  Uint8List? _extractBytes(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.bgra8888) {
        return image.planes[0].bytes;
      }
      if (image.format.group == ImageFormatGroup.yuv420) {
        return image.planes[0].bytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _applyFilter(
    Uint8List bytes,
    int width,
    int height,
  ) async {
    final byteList = bytes.toList();

    switch (state.activeFilter) {
      case FrameFilter.grayscale:
        final result = _api.crateFrameProcessorApplyGrayscale(
          bytes: byteList,
          width: width,
          height: height,
        );
        return Uint8List.fromList(result.data);

      case FrameFilter.brightness:
        final result = _api.crateFrameProcessorApplyBrightness(
          bytes: byteList,
          width: width,
          height: height,
          value: state.brightness,
        );
        return Uint8List.fromList(result.data);

      case FrameFilter.none:
      default:
        final result = _api.crateFrameProcessorProcessFrame(
          bytes: byteList,
          width: width,
          height: height,
        );
        return Uint8List.fromList(result.data);
    }
  }

  void setFilter(FrameFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setBrightness(int value) {
    state = state.copyWith(brightness: value);
  }

  void setResolution(String res) {
    state = state.copyWith(resolution: res);
  }

  Future<void> flipCamera() async {
    await dispose();
    await initCamera(frontCamera: !state.isFrontCamera);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _ref.read(cameraControllerProvider.notifier).state = null;
    state = state.copyWith(status: CameraStatus.disposed);
  }
}

final cameraProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier(ref);
});
