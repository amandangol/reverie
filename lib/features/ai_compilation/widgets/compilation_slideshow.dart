import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'dart:io';
import '../provider/ai_compilation_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class CompilationSlideshow extends StatefulWidget {
  final AICompilation compilation;
  final Duration slideDuration;
  final Curve transitionCurve;

  const CompilationSlideshow({
    super.key,
    required this.compilation,
    this.slideDuration = const Duration(seconds: 3),
    this.transitionCurve = Curves.easeInOut,
  });

  @override
  State<CompilationSlideshow> createState() => _CompilationSlideshowState();
}

class _CompilationSlideshowState extends State<CompilationSlideshow>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  bool _isPlaying = true;
  int _currentPage = 0;
  bool _showControls = true;
  AudioPlayer? _audioPlayer;
  bool _isMuted = false;
  bool _isAudioInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startAutoPlay();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      await _playBackgroundMusic();
      setState(() {
        _isAudioInitialized = true;
      });
    } catch (e) {
      print('Error initializing audio: $e');
      setState(() {
        _isAudioInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer?.play(AssetSource('audio/background_music.mp3'));
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  void _toggleMute() async {
    if (_audioPlayer == null) return;

    setState(() {
      _isMuted = !_isMuted;
    });
    await _audioPlayer?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _startAutoPlay() {
    Future.delayed(widget.slideDuration, () {
      if (_isPlaying && mounted) {
        if (_currentPage < widget.compilation.mediaPaths.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: widget.transitionCurve,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: widget.transitionCurve,
          );
        }
        _startAutoPlay();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Slideshow
            PageView.builder(
              controller: _pageController,
              itemCount: widget.compilation.mediaPaths.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildMediaItem(widget.compilation.mediaPaths[index]),
                );
              },
            ),
            // Controls overlay
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  child: child,
                );
              },
              child: Stack(
                children: [
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Title and description
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.compilation.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.compilation.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom controls
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Progress indicator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: List.generate(
                              widget.compilation.mediaPaths.length,
                              (index) => Expanded(
                                child: Container(
                                  height: 2,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: index == _currentPage
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isAudioInitialized)
                              IconButton(
                                icon: Icon(
                                  _isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleMute,
                              ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPlaying = !_isPlaying;
                                  if (_isPlaying) {
                                    _startAutoPlay();
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${_currentPage + 1}/${widget.compilation.mediaPaths.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(String path) {
    if (path.startsWith('file://')) {
      return Image.file(
        File(path.replaceFirst('file://', '')),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else {
      return AssetEntityImage(
        AssetEntity(id: path, typeInt: 1, width: 0, height: 0),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }
}
