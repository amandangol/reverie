import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../gallery/provider/media_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

class SlideshowWithCollage extends StatefulWidget {
  final int numberOfImages;
  final Duration slideDuration;
  final Duration transitionDuration;

  const SlideshowWithCollage({
    super.key,
    this.numberOfImages = 10,
    this.slideDuration = const Duration(seconds: 3),
    this.transitionDuration = const Duration(milliseconds: 500),
  });

  @override
  State<SlideshowWithCollage> createState() => _SlideshowWithCollageState();
}

class _SlideshowWithCollageState extends State<SlideshowWithCollage>
    with SingleTickerProviderStateMixin {
  final CarouselController _carouselController = CarouselController();
  List<AssetEntity> _selectedImages = [];
  bool _showCollage = false;
  int _currentIndex = 0;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectRandomDayImages();
    _initializeAudio();
    // Start slideshow automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSlideshow();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/background_music.mp3'));
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _selectRandomDayImages() {
    final mediaProvider = context.read<MediaProvider>();
    final groupedPhotos = mediaProvider.groupedPhotos;

    if (groupedPhotos.isEmpty) return;

    final random = Random();
    final randomDay =
        groupedPhotos.keys.elementAt(random.nextInt(groupedPhotos.length));

    final dayImages = groupedPhotos[randomDay]!
        .where((asset) => asset.type == AssetType.image)
        .toList();

    if (dayImages.isEmpty) return;

    _selectedImages =
        dayImages.take(min(widget.numberOfImages, dayImages.length)).toList();
  }

  void _startSlideshow() {
    Future.delayed(widget.slideDuration, () {
      if (!mounted) return;

      if (_currentIndex < _selectedImages.length - 1) {
        _carouselController.nextPage();
        _startSlideshow();
      } else {
        setState(() {
          _showCollage = true;
        });
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
    if (_selectedImages.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No images available'),
        ),
      );
    }

    if (_showCollage) {
      return _buildCollage();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index, realIndex) {
                return _buildAnimatedImage(_selectedImages[index], index);
              },
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
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
            // Controls
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
                  // Progress indicator
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                _selectedImages.asMap().entries.map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(
                                        _currentIndex == entry.key ? 0.9 : 0.4,
                                      ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                              ),
                              onPressed: _toggleMute,
                            ),
                            Text(
                              '${_currentIndex + 1}/${_selectedImages.length}',
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

  Widget _buildAnimatedImage(AssetEntity asset, int index) {
    return Animate(
      effects: [
        FadeEffect(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ),
        ScaleEffect(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ),
      ],
      child: AssetEntityImage(
        asset,
        fit: BoxFit.contain,
        isOriginal: true,
      ),
    );
  }

  Widget _buildCollage() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Photo Collage')
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 500))
            .slideX(begin: -0.2, end: 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _showCollage = false;
                _currentIndex = 0;
                _selectRandomDayImages();
              });
              _startSlideshow();
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return _buildAnimatedCollageItem(_selectedImages[index], index);
        },
      ),
    );
  }

  Widget _buildAnimatedCollageItem(AssetEntity asset, int index) {
    return Animate(
      effects: [
        FadeEffect(
          delay: Duration(milliseconds: index * 100),
          duration: const Duration(milliseconds: 500),
        ),
        ScaleEffect(
          delay: Duration(milliseconds: index * 100),
          duration: const Duration(milliseconds: 500),
        ),
      ],
      child: AssetEntityImage(
        asset,
        fit: BoxFit.cover,
      ),
    );
  }
}
