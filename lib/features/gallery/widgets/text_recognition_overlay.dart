import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';

class TextRecognitionOverlay extends StatelessWidget {
  final RecognizedText recognizedText;
  final Size imageSize;
  final VoidCallback onClose;

  const TextRecognitionOverlay({
    super.key,
    required this.recognizedText,
    required this.imageSize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent background with blur effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                color: Colors.black54,
              ),
            ),
          ),
        ),
        // Text blocks overlay
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.text_fields, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Recognized Text',
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
                ),
                const SizedBox(height: 16),
                // Text blocks
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recognizedText.blocks.length,
                    itemBuilder: (context, index) {
                      final block = recognizedText.blocks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.withOpacity(0.9),
                                Colors.grey.withOpacity(0.9),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  block.text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        height: 1.5,
                                      ),
                                ),
                              ),
                              // Action buttons
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.copy, size: 20),
                                      label: const Text('Copy'),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: block.text),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Text copied to clipboard'),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.share, size: 20),
                                      label: const Text('Share'),
                                      onPressed: () => Share.share(block.text),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
