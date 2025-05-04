import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

class AICompilation {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final List<String> mediaPaths;
  final String theme;

  AICompilation({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.mediaPaths,
    required this.theme,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'mediaPaths': mediaPaths,
        'theme': theme,
      };

  factory AICompilation.fromJson(Map<String, dynamic> json) => AICompilation(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        mediaPaths: List<String>.from(json['mediaPaths']),
        theme: json['theme'],
      );
}

class AICompilationProvider extends ChangeNotifier {
  List<AICompilation> _compilations = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<AICompilation> get compilations => _compilations;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  AICompilationProvider() {
    loadCompilations();
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
    _isGenerating = true;
    notifyListeners();

    try {
      // TODO: Implement AI generation logic here
      // For now, we'll just create a mock compilation
      final compilation = AICompilation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: 'AI-generated compilation based on your summer memories',
        date: DateTime.now(),
        mediaPaths: mediaPaths,
        theme: theme,
      );

      _compilations.add(compilation);
      await _saveCompilations();
    } catch (e) {
      print('Error generating compilation: $e');
    }

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> deleteCompilation(String id) async {
    _compilations.removeWhere((compilation) => compilation.id == id);
    await _saveCompilations();
    notifyListeners();
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
      final compilationsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${compilationsDir.path}/compilations');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _compilations.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
