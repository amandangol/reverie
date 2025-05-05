import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class AICompilation {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final List<String> mediaPaths;
  final String theme;
  final CompilationStatus status;
  final List<String> tags;
  final Map<String, double> emotions;
  final String mood;

  AICompilation({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.mediaPaths,
    required this.theme,
    this.status = CompilationStatus.pending,
    this.tags = const [],
    this.emotions = const {},
    this.mood = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'mediaPaths': mediaPaths,
        'theme': theme,
        'status': status.toString(),
        'tags': tags,
        'emotions': emotions,
        'mood': mood,
      };

  factory AICompilation.fromJson(Map<String, dynamic> json) => AICompilation(
        id: json['id'],
        title: json['title'],
        date: DateTime.parse(json['date']),
        description: json['description'],
        mediaPaths: List<String>.from(json['mediaPaths']),
        theme: json['theme'],
        status: CompilationStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => CompilationStatus.pending,
        ),
        tags: List<String>.from(json['tags'] ?? []),
        emotions: Map<String, double>.from(json['emotions'] ?? {}),
        mood: json['mood'] ?? '',
      );

  AICompilation copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    List<String>? mediaPaths,
    String? theme,
    CompilationStatus? status,
    List<String>? tags,
    Map<String, double>? emotions,
    String? mood,
  }) {
    return AICompilation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      theme: theme ?? this.theme,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      emotions: emotions ?? this.emotions,
      mood: mood ?? this.mood,
    );
  }
}

enum CompilationStatus {
  pending,
  completed,
  failed,
}

class AICompilationProvider extends ChangeNotifier {
  List<AICompilation> _compilations = [];
  bool _isLoading = false;
  String? _error;
  GenerativeModel? _model;
  final _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.7),
  );

  List<AICompilation> get compilations => _compilations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AICompilationProvider() {
    _initializeModel();
    loadCompilations();
  }

  @override
  void dispose() {
    _imageLabeler.close();
    super.dispose();
  }

  void _initializeModel() {
    try {
      final apiKey = 'AIzaSyCyCzEzKjHpkacME7Y8wj1u2E787Q-NAu4';
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );
    } catch (e) {
      print('Error initializing Gemini model: $e');
    }
  }

  Future<String> _generateDescription(
      String title, String theme, List<String> tags, String mood) async {
    try {
      if (_model == null) {
        return 'A collection of memories themed around "$theme". $title captures special moments and experiences.';
      }

      final prompt = '''
        Create a brief, engaging description for a photo compilation titled "$title" with the theme "$theme".
        The photos are tagged with: ${tags.join(", ")}.
        The overall mood is: $mood.
        The description should be concise (2-3 sentences) and capture the mood and essence of the collection.
        Focus on the emotional and visual aspects, and incorporate the theme and mood naturally.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'AI-generated compilation based on your memories';
    } catch (e) {
      print('Error generating AI description: $e');
      return 'A collection of memories themed around "$theme". $title captures special moments and experiences.';
    }
  }

  Future<List<String>> _analyzeImages(List<String> mediaPaths) async {
    final List<String> tags = [];
    final Map<String, double> emotions = {};
    String mood = '';

    try {
      for (final path in mediaPaths) {
        final file = File(path);
        if (await file.exists()) {
          final inputImage = InputImage.fromFile(file);
          final labels = await _imageLabeler.processImage(inputImage);

          for (final label in labels) {
            tags.add(label.label);
            emotions[label.label] = label.confidence;
          }
        }
      }

      // Determine mood based on emotions
      if (emotions.isNotEmpty) {
        final positiveEmotions = [
          'happy',
          'joy',
          'smile',
          'fun',
          'beautiful',
          'bright'
        ];
        final negativeEmotions = ['sad', 'dark', 'gloomy', 'serious'];

        double positiveScore = 0;
        double negativeScore = 0;

        emotions.forEach((emotion, confidence) {
          if (positiveEmotions.any((e) => emotion.toLowerCase().contains(e))) {
            positiveScore += confidence;
          }
          if (negativeEmotions.any((e) => emotion.toLowerCase().contains(e))) {
            negativeScore += confidence;
          }
        });

        if (positiveScore > negativeScore) {
          mood = 'Joyful and Uplifting';
        } else if (negativeScore > positiveScore) {
          mood = 'Reflective and Thoughtful';
        } else {
          mood = 'Balanced and Diverse';
        }
      }

      return tags;
    } catch (e) {
      print('Error analyzing images: $e');
      return [];
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/ai_compilations.json');
  }

  Future<void> loadCompilations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        _compilations =
            jsonList.map((json) => AICompilation.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading compilations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> generateCompilation({
    required String title,
    required String theme,
    required List<String> mediaPaths,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Analyze images for tags and emotions
      final tags = await _analyzeImages(mediaPaths);
      final emotions = await _analyzeImages(mediaPaths).then((tags) {
        final Map<String, double> emotionMap = {};
        for (final tag in tags) {
          emotionMap[tag] = 1.0;
        }
        return emotionMap;
      });

      // Determine mood
      String mood = '';
      if (emotions.isNotEmpty) {
        final positiveEmotions = [
          'happy',
          'joy',
          'smile',
          'fun',
          'beautiful',
          'bright'
        ];
        final negativeEmotions = ['sad', 'dark', 'gloomy', 'serious'];

        double positiveScore = 0;
        double negativeScore = 0;

        emotions.forEach((emotion, confidence) {
          if (positiveEmotions.any((e) => emotion.toLowerCase().contains(e))) {
            positiveScore += confidence;
          }
          if (negativeEmotions.any((e) => emotion.toLowerCase().contains(e))) {
            negativeScore += confidence;
          }
        });

        if (positiveScore > negativeScore) {
          mood = 'Joyful and Uplifting';
        } else if (negativeScore > positiveScore) {
          mood = 'Reflective and Thoughtful';
        } else {
          mood = 'Balanced and Diverse';
        }
      }

      // Generate description using AI
      final description = await _generateDescription(title, theme, tags, mood);

      final compilation = AICompilation(
        id: const Uuid().v4(),
        title: title,
        description: description,
        date: DateTime.now(),
        mediaPaths: mediaPaths,
        theme: theme,
        status: CompilationStatus.completed,
        tags: tags,
        emotions: emotions,
        mood: mood,
      );

      _compilations.add(compilation);
      await _saveCompilations();
      notifyListeners();
    } catch (e) {
      print('Error generating compilation: $e');
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCompilation(String id) async {
    try {
      _compilations.removeWhere((compilation) => compilation.id == id);
      await _saveCompilations();
      notifyListeners();
    } catch (e) {
      print('Error deleting compilation: $e');
    }
  }

  Future<void> _saveCompilations() async {
    try {
      final file = await _localFile;
      final jsonList =
          _compilations.map((compilation) => compilation.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving compilations: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      _compilations.clear();
      await _saveCompilations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
