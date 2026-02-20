enum CameraStatus { idle, initializing, streaming, error, disposed }

enum FrameFilter { none, grayscale, brightness }

class CameraState {
  final CameraStatus status;
  final String? error;
  final int frameCount;
  final FrameFilter activeFilter;
  final int brightness; // -255 to +255
  final bool isFrontCamera;
  final String resolution; // "1080p", "4K"

  const CameraState({
    this.status = CameraStatus.idle,
    this.error,
    this.frameCount = 0,
    this.activeFilter = FrameFilter.none,
    this.brightness = 0,
    this.isFrontCamera = false,
    this.resolution = "1080p",
  });

  CameraState copyWith({
    CameraStatus? status,
    String? error,
    int? frameCount,
    FrameFilter? activeFilter,
    int? brightness,
    bool? isFrontCamera,
    String? resolution,
  }) {
    return CameraState(
      status: status ?? this.status,
      error: error ?? this.error,
      frameCount: frameCount ?? this.frameCount,
      activeFilter: activeFilter ?? this.activeFilter,
      brightness: brightness ?? this.brightness,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      resolution: resolution ?? this.resolution,
    );
  }
}
