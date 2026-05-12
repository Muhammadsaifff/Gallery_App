import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/photo_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final PhotoModel photo;
  final bool showUI;
  final VoidCallback onTap;

  const VideoPlayerWidget({
    super.key,
    required this.photo,
    required this.showUI,
    required this.onTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final file = await widget.photo.asset.file;
      if (file == null || !mounted) return;

      final controller = VideoPlayerController.file(File(file.path));
      _controller = controller;

      await controller.initialize();

      controller.addListener(_onVideoUpdate);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        // Auto-play like iPhone Photos
        controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;

    final isBuffering = controller.value.isBuffering;
    if (isBuffering != _isBuffering) {
      setState(() => _isBuffering = isBuffering);
    }

    // Loop video like iPhone
    if (controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      controller.seekTo(Duration.zero);
      controller.play();
    }

    setState(() {});
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _seekTo(double value) {
    final controller = _controller;
    if (controller == null) return;
    final duration = controller.value.duration;
    controller.seekTo(Duration(milliseconds: (value * duration.inMilliseconds).round()));
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
      );
    }

    if (_hasError || !_isInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'Unable to play video',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final controller = _controller!;
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        widget.onTap();
        _togglePlayPause();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),

          // Buffering indicator
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),

          // Controls overlay
          if (widget.showUI) ...[
            // Play/Pause center button (shows briefly on toggle)
            if (!value.isPlaying)
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),

            // Bottom controls bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scrubber
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: _seekTo,
                        onChangeStart: (_) => controller.pause(),
                        onChangeEnd: (_) => controller.play(),
                      ),
                    ),

                    // Time labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Mute button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                controller.setVolume(
                                  value.volume > 0 ? 0.0 : 1.0,
                                );
                              });
                            },
                            child: Icon(
                              value.volume > 0
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}