import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ira/theme/app_theme.dart';
import 'EmojiFeedback.dart';

class PlayerPage extends StatefulWidget {
  final String videoUrl;
  final String email;
  final String Foldername;
  final String day;
  final String activity;

  const PlayerPage({
    Key? key,
    required this.videoUrl,
    required this.email,
    required this.Foldername,
    required this.day,
    required this.activity,
  }) : super(key: key);

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  bool _showDoneButton = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  String _loadingMessage = 'Buffering therapy video stream...';
  bool _hasError = false;

  String _errorMessage = '';

  Timer? _countdownTimer;
  int _secondsRemaining = 30; // Mandatory 30-second adherence timer

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _setupController(VideoPlayerController controller) {
    _videoPlayerController = controller;
    _isInitialized = true;
    _isLoading = false;
    _hasError = false;
    _errorMessage = '';

    controller.setLooping(true);
    controller.addListener(() {
      if (!mounted) return;
      final isPlayingNow = controller.value.isPlaying;
      if (isPlayingNow != _isPlaying) {
        setState(() {
          _isPlaying = isPlayingNow;
        });
      }
    });

    if (_isPlaying) {
      controller.play();
    }
    setState(() {});
  }

  Future<void> _cacheVideoInBackground(Uri uri, File targetFile) async {
    if (kIsWeb) return;
    try {
      if (await targetFile.exists() && (await targetFile.length()) > 200000) {
        return; // Already cached
      }
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200 || response.statusCode == 206) {
        final tempFile = File('${targetFile.path}.tmp');
        final sink = tempFile.openWrite();
        await response.pipe(sink);
        client.close();
        if (await tempFile.exists() && (await tempFile.length()) > 50000) {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          await tempFile.rename(targetFile.path);
          debugPrint('Therapy video successfully cached in background: ${targetFile.path}');
        }
      } else {
        client.close();
      }
    } catch (e) {
      debugPrint('Background caching ignored error: $e');
    }
  }

  Future<void> _initializeVideo() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isInitialized = false;
      _errorMessage = '';
      _loadingMessage = 'Connecting to therapy stream...';
    });

    try {
      // 1. Properly release any previous controller and hardware decoder surface
      if (_videoPlayerController != null) {
        final oldController = _videoPlayerController;
        _videoPlayerController = null;
        await oldController?.dispose();
      }

      // 2. Normalize and parse URL safely
      final decodedUrl = Uri.decodeFull(widget.videoUrl.trim());
      final cleanUrl = Uri.encodeFull(decodedUrl);
      final uri = Uri.parse(cleanUrl);

      // Web specific: Browser manages streaming and caching natively without dart:io FileSystem
      if (kIsWeb) {
        debugPrint('Web platform detected: Streaming directly from $uri');
        final webController = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await webController.initialize();
        if (!mounted) {
          await webController.dispose();
          return;
        }
        _setupController(webController);
        return;
      }

      // 3. Prepare local cache path in system temporary directory (Native platforms only)
      final sanitizedDay = widget.day.replaceAll(RegExp(r'[^\w\d]'), '_');
      final sanitizedActivity = widget.activity.replaceAll(RegExp(r'[^\w\d]'), '_');
      final sanitizedFolder = widget.Foldername.replaceAll(RegExp(r'[^\w\d]'), '_');
      final cacheFilename = 'therapy_${sanitizedFolder}_Day_${sanitizedDay}_${sanitizedActivity}.mp4';
      final cacheFile = File('${Directory.systemTemp.path}/$cacheFilename');

      // Clean up any stale partial .tmp downloads
      final tempFile = File('${cacheFile.path}.tmp');
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      // 4. If valid local cache exists (> 200KB), initialize from local file
      if (await cacheFile.exists() && (await cacheFile.length()) > 200000) {
        debugPrint('Loading video directly from local cache: ${cacheFile.path}');
        try {
          final fileController = VideoPlayerController.file(
            cacheFile,
            viewType: VideoViewType.platformView,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
          await fileController.initialize();

          if (!mounted) {
            await fileController.dispose();
            return;
          }

          _setupController(fileController);
          return;
        } catch (cacheErr) {
          debugPrint('Corrupted cache detected, clearing: $cacheErr');
          try {
            await cacheFile.delete();
          } catch (_) {}
        }
      }

      // 5. PRIMARY ATTEMPT: Direct progressive network streaming with PlatformView (SurfaceView)
      // This bypasses the MediaTek OMX_CONFIG_ROTATIONTYPE (-1010) hardware decoder crash on SurfaceTexture!
      if (mounted) {
        setState(() {
          _loadingMessage = 'Buffering therapy video stream...';
        });
      }

      debugPrint('Attempting VideoViewType.platformView streaming for: $uri');
      try {
        final platformController = VideoPlayerController.networkUrl(
          uri,
          viewType: VideoViewType.platformView,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await platformController.initialize();

        if (!mounted) {
          await platformController.dispose();
          return;
        }

        _setupController(platformController);

        // In the background, cache the video for future instant playback without blocking
        _cacheVideoInBackground(uri, cacheFile);
        return;
      } catch (streamError) {
        debugPrint('PlatformView streaming failed: $streamError. Trying textureView fallback...');
      }

      // 6. SECONDARY FALLBACK: TextureView Progressive Stream
      try {
        final textureController = VideoPlayerController.networkUrl(
          uri,
          viewType: VideoViewType.textureView,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await textureController.initialize();

        if (!mounted) {
          await textureController.dispose();
          return;
        }

        _setupController(textureController);
        _cacheVideoInBackground(uri, cacheFile);
        return;
      } catch (texError) {
        debugPrint('TextureView streaming failed: $texError. Attempting direct chunked file download...');
      }

      // 7. TERTIARY FALLBACK: Download video file with HTTP client and play locally
      if (mounted) {
        setState(() {
          _loadingMessage = 'Fetching video into local storage...';
        });
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 20);
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 45));

      if (response.statusCode == 200 || response.statusCode == 206) {
        final sink = cacheFile.openWrite();
        await response.pipe(sink);
        client.close();

        if (await cacheFile.exists() && (await cacheFile.length()) > 50000) {
          final fileController = VideoPlayerController.file(
            cacheFile,
            viewType: VideoViewType.platformView,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
          await fileController.initialize();

          if (!mounted) {
            await fileController.dispose();
            return;
          }

          _setupController(fileController);
          return;
        }
      } else {
        client.close();
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      throw Exception('Video stream could not be initialized into player.');
    } catch (error) {
      debugPrint('Error loading therapy video into in-app player: $error');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _startTherapySession() {
    setState(() {
      _isPlaying = true;
      _secondsRemaining = 30;
    });

    if (_isInitialized && _videoPlayerController != null) {
      _videoPlayerController!.play();
    }

    // Mandatory 30-second adherence timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _showDoneButton = true;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (!_isInitialized || _videoPlayerController == null) return;
    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
    });
  }

  void doneButtonPressed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmojiFeedback(
          email: widget.email,
          fn: widget.Foldername,
          day: widget.day,
          activity: widget.activity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: Text('Day ${widget.day} - ${widget.activity}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // In-App Video Player Container
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _buildVideoContent(),
              ),
            ),

            const SizedBox(height: 20),

            // Adherence guidance note with live countdown
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppStyles.cardDecoration(
                backgroundColor: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_showDoneButton
                              ? AppColors.positiveGreen
                              : (_isPlaying ? AppColors.warningAmber : AppColors.patientPrimary))
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _showDoneButton
                          ? Icons.check_circle_rounded
                          : (_isPlaying ? Icons.timer_outlined : Icons.self_improvement_rounded),
                      color: _showDoneButton
                          ? AppColors.positiveGreen
                          : (_isPlaying ? AppColors.warningAmber : AppColors.patientPrimary),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showDoneButton
                              ? 'Session Complete!'
                              : (_isPlaying
                                  ? 'Session in Progress (${_secondsRemaining}s remaining)'
                                  : 'Guided Adherence Session'),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: _showDoneButton
                                ? AppColors.positiveGreen
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _showDoneButton
                              ? 'You have satisfied the 30-second therapeutic adherence requirement. Tap below to log your emotions.'
                              : (_isPlaying
                                  ? 'Focus on deep, steady breathing and reflection while the exercise timer runs.'
                                  : 'Complete the minimum 30-second mindful session to advance your therapy program.'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (!_isPlaying)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Text(
                    'Begin Therapy Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patientPrimary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.patientPrimary.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _startTherapySession,
                ),
              ),

            // Done / Complete Mood Record Button
            if (_showDoneButton)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sentiment_satisfied_alt_rounded, size: 24),
                  label: const Text(
                    'Complete & Record Mood',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.positiveGreen,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.positiveGreen.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: doneButtonPressed,
                ),
              )
            else if (_isPlaying)
              // Progress bar during the 30s session
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (30 - _secondsRemaining) / 30.0,
                      minHeight: 8,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.patientPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Adherence Timer: ${_secondsRemaining}s remaining',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isInitialized && _videoPlayerController != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: (_videoPlayerController!.value.isInitialized &&
                        _videoPlayerController!.value.aspectRatio > 0)
                    ? _videoPlayerController!.value.aspectRatio
                    : (16 / 9),
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
            // Play / Pause overlay indicator
            if (!_isPlaying)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            // Bottom video progress indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoPlayerController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.patientPrimary,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: const Color(0xFF1B2A32),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  size: 32,
                  color: AppColors.patientWarmAccent,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Video Fetch Issue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Could not load video into player. Tap below to retry fetching.',
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _initializeVideo,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Retry Fetching Video',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading / buffering state
    if (_isLoading) {
      return Container(
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.patientPrimary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 14),
            Text(
              _loadingMessage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
