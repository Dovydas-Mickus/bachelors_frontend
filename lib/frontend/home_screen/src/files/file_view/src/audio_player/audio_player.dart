// lib/frontend/home_screen/src/files/components/src/audio_player/audio_player_widget.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class AudioPlayerWidget extends StatefulWidget {
  final Uint8List bytes;
  final String? fileName; // Optional: Display filename

  const AudioPlayerWidget({
    super.key,
    required this.bytes,
    this.fileName,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  double _currentVolume = 1.0; // State for volume control
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _isSeeking = false;
  bool _isSourceSet = false; // Track if source setting was attempted/successful

  @override
  void initState() {
    super.initState();
    debugPrint('AudioPlayerWidget: initState');
    debugPrint('AudioPlayerWidget received bytes length: ${widget.bytes.length}');

    // Set initial volume for the player instance
    _audioPlayer.setVolume(_currentVolume);

    // Set up listeners
    _setupListeners();

    // Attempt to set the audio source
    _setAudioSource();
  }

  void _setupListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('AudioPlayer state changed: $state');
      if (mounted) {
        setState(() { _playerState = state; });
      }
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      debugPrint('AudioPlayer duration changed: $newDuration');
      if (mounted) {
        setState(() { _duration = newDuration; });
      }
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted && !_isSeeking) { // Only update if not currently seeking
        setState(() { _position = newPosition; });
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      debugPrint('AudioPlayer completed');
      if (mounted) {
        setState(() {
          _position = _duration; // Keep position at end
          _playerState = PlayerState.completed; // Use completed state
        });
      }
    });
    _audioPlayer.onLog.listen((msg) {
      debugPrint('AudioPlayer Internal Log: $msg');
    }, onError: (e) {
      debugPrint('AudioPlayer Internal Error Log: $e');
    });
  }


  Future<void> _setAudioSource() async {
    try {
      debugPrint('AudioPlayerWidget: Setting BytesSource...');
      await _audioPlayer.setSource(BytesSource(widget.bytes));
      _isSourceSet = true;
      debugPrint('AudioPlayerWidget: BytesSource set command sent.');

      await Future.delayed(const Duration(milliseconds: 100));
      final initialDuration = await _audioPlayer.getDuration();
      if (mounted && initialDuration != null) {
        debugPrint('AudioPlayerWidget: Initial duration fetched: $initialDuration');
        setState(() { _duration = initialDuration; });
      } else {
        debugPrint('AudioPlayerWidget: WARN - Failed to get initial duration after setting source.');
      }
    } catch (e) {
      _isSourceSet = false;
      debugPrint('AudioPlayerWidget: ❌ ERROR setting BytesSource: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading audio data: ${e.toString()}'))
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('AudioPlayerWidget: dispose');
    // Best practice: Stop, release, then dispose
    _audioPlayer.stop().catchError((e) {
      debugPrint("Error stopping player during dispose: $e"); // Log potential error
    }).whenComplete(() {
      _audioPlayer.release().catchError((e) {
        debugPrint("Error releasing player during dispose: $e"); // Log potential error
      }).whenComplete(() {
        _audioPlayer.dispose();
        debugPrint('AudioPlayer released and disposed');
      });
    });
    super.dispose();
  }


  String _formatDuration(Duration duration) {
    // Avoid negative durations if possible
    if (duration.isNegative) duration = Duration.zero;

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card( // Wrap controls in a card for better visuals
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Optional: Rounded corners
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take only necessary vertical space
              children: [
                // --- File Name ---
                if (widget.fileName != null) ...[
                  Text(
                    widget.fileName!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
                // --- Seek Slider ---
                Slider(
                  min: 0,
                  // Ensure max is at least 0, use 1.0 as fallback if duration is zero
                  max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                  value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()), // Ensure value is within bounds
                  onChanged: (value) {
                    if (mounted) {
                      // Update position visually while dragging
                      setState(() { _position = Duration(seconds: value.toInt()); });
                    }
                  },
                  onChangeStart: (value) {
                    if (mounted) { setState(() { _isSeeking = true; }); }
                  },
                  onChangeEnd: (value) async {
                    // Seek when user finishes dragging
                    debugPrint('Slider onChangeEnd: Seeking to ${value.toInt()} seconds');
                    try {
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    } catch (e) { debugPrint("Error seeking: $e");}
                    if (mounted) { setState(() { _isSeeking = false; }); }
                  },
                ),
                // --- Time Labels ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position)),
                      Text(_formatDuration(_duration)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // --- Playback Controls ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Stop Button ---
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined),
                      tooltip: 'Stop',
                      iconSize: 48.0,
                      onPressed: () async {
                        debugPrint('Stop button pressed.');
                        try {
                          await _audioPlayer.stop();
                          if (mounted) { setState(() { _position = Duration.zero; }); } // Reset position on stop
                        } catch (e) { debugPrint("Error stopping: $e"); }
                      },
                    ),
                    const SizedBox(width: 20),
                    // --- Play/Pause Button ---
                    IconButton(
                      icon: Icon(
                        // Show play icon if not playing (paused, stopped, completed, initial)
                        _playerState != PlayerState.playing
                            ? Icons.play_circle_filled_outlined
                            : Icons.pause_circle_filled_outlined,
                      ),
                      tooltip: _playerState == PlayerState.playing ? 'Pause' : 'Play',
                      iconSize: 64.0,
                      color: Theme.of(context).colorScheme.primary, // Use theme color
                      onPressed: () async {
                        debugPrint('Play/Pause button pressed. Current state: $_playerState, isSourceSet: $_isSourceSet');
                        try {
                          if (_playerState == PlayerState.playing) {
                            debugPrint('Attempting to pause...');
                            await _audioPlayer.pause();
                            debugPrint('Pause command finished.');
                          } else if (_playerState == PlayerState.paused) {
                            debugPrint('Attempting to resume...');
                            await _audioPlayer.resume();
                            debugPrint('Resume command finished.');
                          } else { // Stopped, Completed, or Initial state
                            if (!_isSourceSet) {
                              debugPrint('Source was not set previously, attempting now...');
                              await _setAudioSource();
                              if (!_isSourceSet && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cannot play: Failed to load audio source.'))
                                );
                                return;
                              }
                            }
                            if (_isSourceSet) {
                              debugPrint('Attempting to play (BytesSource)...');
                              await _audioPlayer.play(BytesSource(widget.bytes));
                              debugPrint('Play command finished.');
                            }
                          }
                        } catch (e) {
                          debugPrint('❌ ERROR during play/pause/resume: $e');
                          if(mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error playing audio: ${e.toString()}'))
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15), // Add some space

                // --- Volume Control ---
                Padding( // Add padding for better spacing
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center volume controls
                    children: [
                      // Mute/Unmute Button
                      IconButton(
                        icon: Icon(
                          _currentVolume <= 0 ? Icons.volume_off : Icons.volume_up,
                          color: Colors.grey.shade700,
                        ),
                        tooltip: _currentVolume > 0 ? 'Mute' : 'Unmute',
                        onPressed: () {
                          final newVolume = _currentVolume > 0 ? 0.0 : 1.0; // Toggle between 0 and 1
                          setState(() { _currentVolume = newVolume; });
                          _audioPlayer.setVolume(newVolume);
                        },
                      ),
                      // Volume Slider
                      Expanded(
                        child: Slider(
                          min: 0.0,
                          max: 1.0,
                          value: _currentVolume,
                          // Optional: Add divisions for discrete steps
                          // divisions: 10,
                          label: "${(_currentVolume * 100).toStringAsFixed(0)}%", // Show percentage label
                          activeColor: Colors.grey.shade700,
                          inactiveColor: Colors.grey.shade400,
                          onChanged: (value) {
                            setState(() { _currentVolume = value; });
                            _audioPlayer.setVolume(value); // Update player volume in real-time
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}