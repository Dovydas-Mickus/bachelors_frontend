import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final Uint8List bytes;

  const VideoPlayerWidget({super.key, required this.bytes});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Write the video bytes to a temporary file.
    final tempDir = await getTemporaryDirectory();
    final file =
    await File('${tempDir.path}/temp_video.mp4').writeAsBytes(widget.bytes);

    // Create and initialize the VideoPlayerController.
    final controller = VideoPlayerController.file(file);
    await controller.initialize();

    // Add a listener so we update the UI as the video position changes.
    controller.addListener(() {
      setState(() {});
    });

    setState(() {
      _videoController = controller;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator until the controller is ready.
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    final isPlaying = _videoController!.value.isPlaying;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            // Tapping the video toggles play/pause.
            onTap: () {
              setState(() {
                isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
        Container(
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row for play/pause button and time display.
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                  ),
                  Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              // Seek bar slider.
              Slider(
                activeColor: Colors.red,
                inactiveColor: Colors.white,
                value: position.inSeconds.toDouble(),
                min: 0,
                max: duration.inSeconds.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _videoController!
                        .seekTo(Duration(seconds: value.toInt()));
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
