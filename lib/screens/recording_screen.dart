import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import 'processing_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _recorderReady = false;
  bool _playerReady = false;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;

  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;

  Duration _audioDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  String? _filePath;
  StreamSubscription? _playerSub;

  late AnimationController _waveController;
  final List<double> _waveHeights = List.generate(24, (_) => 0);

  // -------------------- INIT --------------------

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _generateWave();
    _initRecorder();
    _initPlayer();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    setState(() => _recorderReady = true);
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    _player.setSubscriptionDuration(const Duration(milliseconds: 200));

    _playerSub = _player.onProgress!.listen((event) {
      if (!mounted) return;
      setState(() {
        _playbackPosition = event.position;
        _audioDuration = event.duration ?? Duration.zero;
      });
    });

    setState(() => _playerReady = true);
  }

  // -------------------- RECORD --------------------

  Future<void> _startRecording() async {
    if (!_recorderReady) return;

    if (_isPlaying) await _stopPlayback();

    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/wax_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacMP4,
      sampleRate: 44100,
      bitRate: 128000,
    );

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordDuration = Duration.zero;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    await _recorder.stopRecorder();
    _recordTimer?.cancel();

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _playbackPosition = Duration.zero;
    });
  }

  Future<void> _togglePause() async {
    if (!_isRecording) return;

    if (_isPaused) {
      await _recorder.resumeRecorder();
      _waveController.repeat(reverse: true);
    } else {
      await _recorder.pauseRecorder();
      _waveController.stop();
    }

    setState(() => _isPaused = !_isPaused);
  }

  // -------------------- PLAYBACK --------------------

  Future<void> _togglePlayback() async {
    if (_filePath == null || !_playerReady) return;

    if (_isPlaying) {
      await _stopPlayback();
    } else {
      await _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    await _player.startPlayer(
      fromURI: _filePath,
      codec: Codec.aacMP4,
      whenFinished: () {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      },
    );

    setState(() => _isPlaying = true);
  }

  Future<void> _stopPlayback() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
      _playbackPosition = Duration.zero;
    });
  }

  double _progress() {
    if (_audioDuration.inMilliseconds == 0) return 0;
    return (_playbackPosition.inMilliseconds /
            _audioDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  // -------------------- UI HELPERS --------------------

  void _generateWave() {
    final r = Random();
    for (int i = 0; i < _waveHeights.length; i++) {
      _waveHeights[i] = 20 + r.nextDouble() * 60;
    }
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  // -------------------- DISPOSE --------------------

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerSub?.cancel();
    _waveController.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  // -------------------- BUILD --------------------

  @override
  Widget build(BuildContext context) {
    final hasRecording = _filePath != null && !_isRecording;

    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrement')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _fmt(_isPlaying ? _playbackPosition : _recordDuration),
              style: GoogleFonts.jetBrainsMono(fontSize: 48),
            ),
            const SizedBox(height: 30),

            // WAVES
            SizedBox(
              height: 120,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _waveHeights.map((h) {
                      final scale = (_isRecording || _isPlaying)
                          ? 0.5 +
                              0.5 *
                                  sin(_waveController.value * 2 * pi)
                          : 1.0;
                      return Container(
                        width: 8,
                        height: h * scale,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            if (hasRecording) ...[
              Slider(
                value: _progress(),
                onChanged: _isPlaying
                    ? (v) =>
                        _player.seekToPlayer(_audioDuration * v)
                    : null,
              ),
              Text('${_fmt(_playbackPosition)} / ${_fmt(_audioDuration)}'),
            ],

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // RECORD
                GestureDetector(
                  onTap:
                      _isRecording ? _stopRecording : _startRecording,
                  child: _btn(
                    _isRecording ? LucideIcons.square : LucideIcons.mic,
                    _isRecording ? Colors.red : AppColors.emerald,
                    80,
                  ),
                ),

                if (_isRecording)
                  GestureDetector(
                    onTap: _togglePause,
                    child: _btn(
                      _isPaused
                          ? LucideIcons.play
                          : LucideIcons.pause,
                      Colors.white,
                      60,
                      iconColor: AppColors.emerald,
                    ),
                  ),

                if (hasRecording)
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: _btn(
                      _isPlaying
                          ? LucideIcons.square
                          : LucideIcons.play,
                      Colors.white,
                      60,
                      iconColor: AppColors.emerald,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(LucideIcons.sparkles),
              label: const Text('Transcrire'),
              onPressed: hasRecording
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProcessingScreen(filePath: _filePath!),
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, Color bg, double size,
      {Color iconColor = Colors.white}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 4),
            color: Colors.black26,
          )
        ],
      ),
      child: Icon(icon, color: iconColor, size: size / 2),
    );
  }
}
