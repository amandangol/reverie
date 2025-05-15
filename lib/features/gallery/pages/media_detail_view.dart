import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:reverie/features/journal/pages/journal_detail_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../../commonwidgets/custom_markdown.dart';
import '../../../utils/snackbar_utils.dart';
import '../provider/media_provider.dart';
import '../../../utils/media_utils.dart';
import '../../journal/providers/journal_provider.dart';
import '../../journal/widgets/journal_entry_form.dart';
import '../../journal/models/journal_entry.dart';
import 'albums/album_page.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MediaDetailView extends StatefulWidget {
  final AssetEntity? asset;
  final File? file;
  final List<AssetEntity>? assetList;
  final String? heroTag;

  const MediaDetailView({
    super.key,
    this.asset,
    this.file,
    this.assetList,
    this.heroTag,
  }) : assert(asset != null || file != null,
            'Either asset or file must be provided');

  @override
  State<MediaDetailView> createState() => _MediaDetailViewState();
}

class _MediaDetailViewState extends State<MediaDetailView>
    with SingleTickerProviderStateMixin {
  PageController? _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;
  bool _showInfo = false;
  bool _showControls = true;
  bool _isFullScreen = false;
  bool _showJournal = false;
  bool _showLabels = false;
  bool _showObjectDetection = false;
  List<ImageLabel>? _detectedLabels;
  List<ImageLabel>? _detectedObjects;
  bool _showAnalysis = false;
  Map<String, dynamic>? _imageAnalysis;
  bool _isAnalyzing = false;
  bool _showTextRecognition = false;
  RecognizedText? _recognizedText;
  bool _isRecognizingText = false;

  Timer? _controlsTimer;
  AnimationController? _animationController;
  Animation<double>? _animation;

  // Track if we're currently swiping to prevent unwanted control toggles
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    _setupControlsAnimation();
    _setupSystemUI();

    if (widget.assetList != null) {
      _currentIndex = widget.assetList!.indexOf(widget.asset!);
      if (_currentIndex == -1) _currentIndex = 0;
      _pageController = PageController(initialPage: _currentIndex);

      // Preload adjacent images
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MediaProvider>().preloadAdjacentMedia(
              widget.assetList!,
              _currentIndex,
            );
      });
    }

    if (widget.asset?.type == AssetType.video ||
        widget.file?.path.endsWith('.mp4') == true) {
      _initializeVideoPlayer();
    }

    _startControlsTimer();
  }

  void _setupControlsAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animationController!, curve: Curves.easeInOut));

    if (_showControls) {
      _animationController!.value = 1.0;
    }
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _resetSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (!_showInfo) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isSwiping) {
          _toggleControls(false);
        }
      });
    }
  }

  void _toggleControls(bool show) {
    if (show == _showControls) return;

    setState(() {
      _showControls = show;
    });

    if (show) {
      _animationController!.forward();
      _startControlsTimer();
    } else {
      _animationController!.reverse();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    try {
      final asset = widget.assetList != null
          ? widget.assetList![_currentIndex]
          : widget.asset;
      if (asset == null) return;

      final file = await asset.file;
      if (file == null || !mounted) return;

      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();

      if (!mounted) {
        await _videoController!.dispose();
        _videoController = null;
        return;
      }

      setState(() {});
      _videoController!.play();
      _videoController!.setLooping(true);
      _videoController!.addListener(_videoListener);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
            context, 'Error playing video: ${e.toString()}');
      }
    }
  }

  void _videoListener() {
    if (_videoController == null) return;

    // If video finished, restart
    if (_videoController!.value.position >= _videoController!.value.duration) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.play();
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _animationController?.dispose();

    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      _videoController!.pause();
      _videoController!.dispose();
    }

    _pageController?.dispose();
    _resetSystemUI();
    super.dispose();
  }

  void _showJournalPanel() {
    setState(() {
      _showJournal = !_showJournal;
      _showInfo = false; // Close info panel when journal is opened
      if (_showJournal) {
        _toggleControls(true);
        _controlsTimer?.cancel();
      } else {
        _startControlsTimer();
      }
    });
  }

  void _showObjectDetectionResults() async {
    final asset = widget.assetList != null
        ? widget.assetList![_currentIndex]
        : widget.asset;

    if (asset == null || asset.type == AssetType.video) return;

    setState(() {
      _showObjectDetection = true;
      _showInfo = false;
      _showJournal = false;
      _showLabels = false;
      _toggleControls(true);
      _controlsTimer?.cancel();
    });

    try {
      final mediaProvider = context.read<MediaProvider>();
      final objects = await mediaProvider.detectObjects(asset);

      if (mounted) {
        setState(() {
          _detectedObjects = objects;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect objects: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageAnalysis() async {
    final asset = widget.assetList != null
        ? widget.assetList![_currentIndex]
        : widget.asset;

    if (asset == null || asset.type == AssetType.video) return;

    // Check if analysis is already in progress
    if (context.read<MediaProvider>().isAnalysisInProgress(asset.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis is already in progress'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading bottom sheet first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Analyzing image...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a few moments',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    try {
      final mediaProvider = context.read<MediaProvider>();
      final analysis = await mediaProvider.analyzeImage(asset);

      if (mounted) {
        // Pop the loading sheet
        Navigator.pop(context);

        // Show the analysis sheet
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.black.withOpacity(0.9),
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Image Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: analysis['rawResponse']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Analysis copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white30),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomMarkdown(
                          data: analysis['rawResponse'],
                          textColor: Colors.white,
                          headingColor: Colors.amberAccent,
                          fontSize: 14,
                          headingFontSize: 18,
                          lineSpacing: 1.5,
                          paragraphSpacing: 16,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Analyzed on: ${DateTime.parse(analysis['timestamp']).toString()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Pop the loading sheet
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: GestureDetector(
            onTap: () {
              if (!_isSwiping) {
                _toggleControls(!_showControls);
              }
            },
            child: Stack(
              children: [
                // Photo viewer
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      setState(() {
                        _isSwiping = true;
                      });
                    } else if (notification is ScrollEndNotification) {
                      setState(() {
                        _isSwiping = false;
                      });
                      _startControlsTimer();
                    }
                    return false;
                  },
                  child:
                      widget.assetList != null && widget.assetList!.length > 1
                          ? _buildPageView()
                          : _buildSingleAssetView(),
                ),

                // Controls
                _MediaControls(
                  showControls: _showControls,
                  isFullScreen: _isFullScreen,
                  showInfo: _showInfo,
                  showJournal: _showJournal,
                  currentIndex: _currentIndex,
                  totalItems: widget.assetList?.length ?? 1,
                  onClose: () {
                    _resetSystemUI();
                    Navigator.pop(context);
                  },
                  onToggleInfo: () {
                    setState(() {
                      _showInfo = !_showInfo;
                      _showJournal = false;
                      if (_showInfo) {
                        _toggleControls(true);
                        _controlsTimer?.cancel();
                      } else {
                        _startControlsTimer();
                      }
                    });
                  },
                  onToggleJournal: _showJournalPanel,
                  onShare: _shareMedia,
                  onDelete: _deleteMedia,
                  onDetectObjects: _showObjectDetectionResults,
                  onAnalyzeImage: _showImageAnalysis,
                  onRecognizeText: _recognizeText,
                  favoriteButtonBuilder: (context) => Consumer<MediaProvider>(
                    builder: (context, mediaProvider, _) {
                      final asset = widget.assetList != null
                          ? widget.assetList![_currentIndex]
                          : widget.asset;
                      return IconButton(
                        icon: Icon(
                          mediaProvider.isFavorite(asset!.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: mediaProvider.isFavorite(asset.id)
                              ? Colors.red
                              : Colors.white,
                        ),
                        onPressed: () => _toggleFavorite(asset),
                      );
                    },
                  ),
                  currentAsset: widget.assetList != null
                      ? widget.assetList![_currentIndex]
                      : widget.asset,
                ),

                // Info Panel
                if (_showInfo)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: _InfoPanel(
                        asset: widget.assetList != null
                            ? widget.assetList![_currentIndex]
                            : widget.asset!,
                        onClose: () {
                          setState(() {
                            _showInfo = false;
                            _startControlsTimer();
                          });
                        },
                      ),
                    ),
                  ),

                // Journal Panel
                if (_showJournal)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: _buildJournalPanel(),
                    ),
                  ),

                // Labels Panel
                if (_showLabels)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: _buildLabelsPanel(),
                    ),
                  ),

                // Object Detection Panel
                if (_showObjectDetection && _detectedObjects != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: _buildObjectDetectionPanel(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.assetList!.length,
      onPageChanged: (index) async {
        setState(() {
          _currentIndex = index;
          // Hide all panels when changing pages
          _showObjectDetection = false;
          _showLabels = false;
          _showInfo = false;
          _showJournal = false;
        });

        final currentAsset = widget.assetList![index];

        // Dispose of current video controller if it exists
        if (_videoController != null) {
          _videoController!.removeListener(_videoListener);
          await _videoController!.pause();
          await _videoController!.dispose();
          _videoController = null;
        }

        // Initialize new video controller if the asset is a video
        if (currentAsset.type == AssetType.video) {
          await _initializeVideoPlayer();
        }

        // Show controls briefly when switching media
        _toggleControls(true);

        // Preload adjacent images
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<MediaProvider>().preloadAdjacentMedia(
                widget.assetList!,
                _currentIndex,
              );
        });
      },
      itemBuilder: (context, index) {
        final asset = widget.assetList![index];
        if (asset.type == AssetType.video) {
          return _buildVideoPlayer();
        }

        return Consumer<MediaProvider>(
          builder: (context, mediaProvider, _) {
            final cachedFile = mediaProvider.getCachedFile(asset.id);
            if (cachedFile != null) {
              return _buildPhotoView(cachedFile, 'media_${asset.id}');
            }

            return FutureBuilder<File?>(
              future: MediaUtils.getFileForAsset(asset),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Icon(Icons.error_outline,
                        color: Colors.white, size: 50),
                  );
                }

                if (snapshot.data != null) {
                  return _buildPhotoView(snapshot.data!, 'media_${asset.id}');
                }

                return const Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSingleAssetView() {
    if (widget.asset?.type == AssetType.video ||
        widget.file?.path.endsWith('.mp4') == true) {
      return _buildVideoPlayer();
    }

    if (widget.asset != null) {
      return Consumer<MediaProvider>(
        builder: (context, mediaProvider, _) {
          final cachedFile = mediaProvider.getCachedFile(widget.asset!.id);
          if (cachedFile != null) {
            return _buildPhotoView(cachedFile, widget.heroTag);
          }

          return FutureBuilder<File?>(
            future: MediaUtils.getFileForAsset(widget.asset!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading();
              }

              if (snapshot.hasError) {
                return const Center(
                  child:
                      Icon(Icons.error_outline, color: Colors.white, size: 50),
                );
              }

              if (snapshot.data != null) {
                return _buildPhotoView(snapshot.data!, widget.heroTag);
              }

              return const Center(
                child: Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          );
        },
      );
    } else if (widget.file != null) {
      return _buildPhotoView(widget.file!, widget.heroTag);
    }

    return const Center(
      child: Text(
        'Failed to load media',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhotoView(File file, String? heroTag) {
    // Create a unique hero tag for each view
    final uniqueHeroTag = heroTag != null
        ? '${heroTag}_${DateTime.now().millisecondsSinceEpoch}'
        : null;

    return GestureDetector(
      onLongPress: () async {
        if (widget.asset?.type == AssetType.image) {
          await _recognizeText();
        }
      },
      child: Stack(
        children: [
          PhotoView(
            imageProvider: FileImage(file),
            heroAttributes: uniqueHeroTag != null
                ? PhotoViewHeroAttributes(tag: uniqueHeroTag)
                : null,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration:
                const BoxDecoration(color: Colors.transparent),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 50),
            ),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              // Video controls overlay
              if (_showControls)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                    _startControlsTimer();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Play/Pause button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: Colors.blue,
                            bufferedColor: Colors.grey.withOpacity(0.5),
                            backgroundColor: Colors.grey.withOpacity(0.2),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                        ),
                        // Time indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                    _videoController!.value.position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(
                                    _videoController!.value.duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Additional controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Volume control
                            IconButton(
                              icon: Icon(
                                _videoController!.value.volume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.setVolume(
                                    _videoController!.value.volume == 0
                                        ? 1.0
                                        : 0.0,
                                  );
                                });
                              },
                            ),
                            // Playback speed
                            PopupMenuButton<double>(
                              icon:
                                  const Icon(Icons.speed, color: Colors.white),
                              onSelected: (speed) {
                                setState(() {
                                  _videoController!.setPlaybackSpeed(speed);
                                });
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 0.5,
                                  child: Text('0.5x'),
                                ),
                                const PopupMenuItem(
                                  value: 1.0,
                                  child: Text('1.0x'),
                                ),
                                const PopupMenuItem(
                                  value: 1.5,
                                  child: Text('1.5x'),
                                ),
                                const PopupMenuItem(
                                  value: 2.0,
                                  child: Text('2.0x'),
                                ),
                              ],
                            ),
                            // Fullscreen toggle
                            IconButton(
                              icon: Icon(
                                _isFullScreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: _toggleFullScreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  Future<void> _shareMedia() async {
    final asset = widget.assetList != null
        ? widget.assetList![_currentIndex]
        : widget.asset;

    try {
      final file = await asset!.file;
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Check out this ${asset.type == AssetType.video ? 'video' : 'photo'}!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to share: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteMedia() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final mediaProvider = context.read<MediaProvider>();
        final asset = widget.assetList != null
            ? widget.assetList![_currentIndex]
            : widget.asset;
        await mediaProvider.deleteMedia(asset!);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Failed to delete: ${e.toString()}');
        }
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;

      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Widget _buildJournalPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Journal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showJournal = false;
                    _startControlsTimer();
                  });
                },
              ),
            ],
          ),
          const Divider(color: Colors.white30),
          const SizedBox(height: 8),
          _buildJournalContent(),
        ],
      ),
    );
  }

  Widget _buildJournalContent() {
    final asset = widget.assetList != null
        ? widget.assetList![_currentIndex]
        : widget.asset;

    return Consumer<JournalProvider>(
      builder: (context, journalProvider, _) {
        if (journalProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (journalProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading journal entries: ${journalProvider.error}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => journalProvider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Get all entries and filter those that contain the current media ID
        final allEntries = journalProvider.entries;
        final entries = allEntries
            .where((entry) => entry.mediaIds.contains(asset!.id))
            .toList();

        if (entries.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'No journal entries for this media',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddJournalEntryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add to Journal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${entries.length} Journal ${entries.length == 1 ? 'Entry' : 'Entries'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddJournalEntryDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Entry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.black54,
                    child: InkWell(
                      onTap: () => _showJournalDetailDialog(entry),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (entry.mood != null)
                                  Text(
                                    entry.mood!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, yyyy').format(entry.date),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            // if (entry.tags.isNotEmpty) ...[
                            //   const SizedBox(height: 8),
                            //   Wrap(
                            //     spacing: 4,
                            //     runSpacing: 4,
                            //     children: entry.tags
                            //         .map((tag) => Chip(
                            //               label: Text(tag),
                            //               backgroundColor:
                            //                   Colors.blue.withOpacity(0.2),
                            //               labelStyle: const TextStyle(
                            //                   color: Colors.white),
                            //               materialTapTargetSize:
                            //                   MaterialTapTargetSize.shrinkWrap,
                            //             ))
                            //         .toList(),
                            //   ),
                            // ],
                            const SizedBox(height: 8),
                            Text(
                              entry.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleFavorite(AssetEntity asset) async {
    try {
      final mediaProvider = context.read<MediaProvider>();
      await mediaProvider.toggleFavorite(asset);

      if (mounted) {
        if (mediaProvider.isFavorite(asset.id)) {
          SnackbarUtils.showMediaAddedToFavorites(
            context,
            count: 1,
            onView: () {
              final albums = mediaProvider.albums;
              if (albums.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumPage(
                      album: albums.first,
                      isGridView: true,
                      gridCrossAxisCount: 3,
                      isFavoritesAlbum: true,
                    ),
                  ),
                );
              }
            },
          );
        } else {
          SnackbarUtils.showMediaRemovedFromFavorites(context, count: 1);
        }
        setState(() {}); // Refresh the UI to update the favorite icon
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Failed to update favorite: ${e.toString()}',
        );
      }
    }
  }

  void _showAddJournalEntryDialog() {
    final asset = widget.assetList != null
        ? widget.assetList![_currentIndex]
        : widget.asset;
    _videoController?.pause();

    showDialog(
      context: context,
      builder: (context) => JournalEntryForm(
        initialMediaIds: [asset!.id],
        onSave: (title, content, mediaIds, mood, tags, {DateTime? lastEdited}) {
          final entry = JournalEntry(
            id: const Uuid().v4(),
            title: title,
            content: content,
            mediaIds: mediaIds,
            mood: mood,
            tags: tags,
            date: DateTime.now(),
          );
          context.read<JournalProvider>().addEntry(entry);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showJournalDetailDialog(JournalEntry entry) {
    _videoController?.pause();

    showDialog(
      context: context,
      builder: (context) => JournalDetailScreen(
        entry: entry,
      ),
    );
  }

  Widget _buildLabelsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Google Lens',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showLabels = false;
                    _startControlsTimer();
                  });
                },
              ),
            ],
          ),
          const Divider(color: Colors.white30),
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Opening Google Lens...',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'This will open Google Lens in your browser where you can search using this image.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildObjectDetectionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Object Detection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showObjectDetection = false;
                    _startControlsTimer();
                  });
                },
              ),
            ],
          ),
          const Divider(color: Colors.white30),
          const SizedBox(height: 8),
          if (_detectedObjects == null)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else if (_detectedObjects!.isEmpty)
            const Center(
              child: Text(
                'No objects detected',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Detected Objects',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _detectedObjects!.map((label) {
                    return ActionChip(
                      label: Text(
                        '${label.label} (${(label.confidence * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.3),
                      onPressed: () {
                        context
                            .read<MediaProvider>()
                            .searchOnGoogle(label.label);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tap on a detected object to search it on Google.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _recognizeText() async {
    if (_isRecognizingText) return;

    // Show loading bottom sheet first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Recognizing text...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a few moments',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    try {
      final asset = widget.assetList != null
          ? widget.assetList![_currentIndex]
          : widget.asset;

      if (asset == null) return;

      final recognizedText =
          await context.read<MediaProvider>().recognizeText(asset);

      if (recognizedText != null) {
        if (mounted) {
          // Pop the loading sheet
          Navigator.pop(context);

          // Show the results sheet
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black.withOpacity(0.9),
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Text Recognition',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: recognizedText.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Text copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white30),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (recognizedText.text.isEmpty)
                            const Center(
                              child: Text(
                                'No text detected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          else ...[
                            Text(
                              recognizedText.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Text Blocks',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: recognizedText.blocks.map((block) {
                                return ActionChip(
                                  label: Text(
                                    block.text,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.blue.withOpacity(0.3),
                                  onPressed: () {
                                    context
                                        .read<MediaProvider>()
                                        .searchOnGoogle(block.text);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Tap on any text block to search it on Google.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      if (mounted) {
        // Pop the loading sheet
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to recognize text in image'),
          ),
        );
      }
    } finally {
      setState(() {
        _isRecognizingText = false;
      });
    }
  }
}

class _MediaControls extends StatelessWidget {
  final bool showControls;
  final bool isFullScreen;
  final bool showInfo;
  final bool showJournal;
  final int currentIndex;
  final int totalItems;
  final VoidCallback onClose;
  final VoidCallback onToggleInfo;
  final VoidCallback onToggleJournal;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onDetectObjects;
  final VoidCallback onAnalyzeImage;
  final VoidCallback onRecognizeText;
  final Widget Function(BuildContext) favoriteButtonBuilder;
  final AssetEntity? currentAsset;

  const _MediaControls({
    required this.showControls,
    required this.isFullScreen,
    required this.showInfo,
    required this.showJournal,
    required this.currentIndex,
    required this.totalItems,
    required this.onClose,
    required this.onToggleInfo,
    required this.onToggleJournal,
    required this.onShare,
    required this.onDelete,
    required this.onDetectObjects,
    required this.onAnalyzeImage,
    required this.onRecognizeText,
    required this.favoriteButtonBuilder,
    required this.currentAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (!showControls) return const SizedBox.shrink();

    return Stack(
      children: [
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                  const Spacer(),
                  Text(
                    '${currentIndex + 1}/$totalItems',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Essential icons
                  favoriteButtonBuilder(context),
                  IconButton(
                    icon: const Icon(Icons.book_outlined, color: Colors.white),
                    onPressed: onToggleJournal,
                  ),
                  if (currentAsset?.type == AssetType.image) ...[
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: onDetectObjects,
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      onPressed: onAnalyzeImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields, color: Colors.white),
                      onPressed: onRecognizeText,
                    ),
                  ],
                  // More options menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          onShare();
                          break;
                        case 'info':
                          onToggleInfo();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Info'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onClose;

  const _InfoPanel({
    required this.asset,
    required this.onClose,
  });

  Future<Map<String, dynamic>> _getMediaDetails(
      MediaProvider mediaProvider) async {
    final details = <String, dynamic>{};

    // Get creation date
    details['date'] = mediaProvider.getCreateDate(asset.id);

    // Get dimensions
    details['size'] = mediaProvider.getSize(asset.id);

    // Get file size
    try {
      final file = await asset.file;
      if (file != null) {
        details['filePath'] = file.path;
        // Try to get file size
        try {
          final fileSize = await file.length();
          details['fileSize'] = fileSize;
        } catch (e) {}
      }
    } catch (e) {}

    // Get duration for videos
    if (asset.type == AssetType.video) {
      details['duration'] = mediaProvider.getDuration(asset.id);
    }

    // Get device info
    if (asset.title != null) {
      details['device'] = asset.title;
    }

    // Get modified date
    if (asset.modifiedDateTime != null) {
      details['modifiedDate'] = asset.modifiedDateTime;
    }

    return details;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Media Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ],
          ),
          const Divider(color: Colors.white30),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _getMediaDetails(context.read<MediaProvider>()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading details: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final details = snapshot.data ?? {};
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Type',
                      asset.type == AssetType.video ? 'Video' : 'Image'),
                  const SizedBox(height: 12),
                  if (details['date'] != null)
                    _buildInfoRow(
                        'Date', MediaUtils.formatDate(details['date'])),
                  const SizedBox(height: 12),
                  if (details['size'] != null)
                    _buildInfoRow('Dimensions',
                        MediaUtils.formatDimensions(details['size'])),
                  const SizedBox(height: 12),
                  if (details['fileSize'] != null)
                    _buildInfoRow('File Size',
                        MediaUtils.formatFileSize(details['fileSize'])),
                  const SizedBox(height: 12),
                  if (details['filePath'] != null)
                    _buildInfoRow('File Path', details['filePath']),
                  const SizedBox(height: 12),
                  if (asset.type == AssetType.video &&
                      details['duration'] != null)
                    _buildInfoRow('Duration',
                        MediaUtils.formatDuration(details['duration'])),
                  const SizedBox(height: 12),
                  if (details['device'] != null)
                    _buildInfoRow('Device', details['device']),
                  const SizedBox(height: 12),
                  if (details['modifiedDate'] != null)
                    _buildInfoRow('Modified',
                        MediaUtils.formatDate(details['modifiedDate'])),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
