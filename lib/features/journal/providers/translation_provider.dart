import 'package:flutter/foundation.dart';
import 'package:translator/translator.dart';
import 'package:flutter/material.dart';
import 'package:reverie/utils/language_utils.dart';

class TranslationProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, String> _translationCache = {};
  final GoogleTranslator _translator = GoogleTranslator();

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, String>> translateText({
    required String text,
    required String targetLanguage,
  }) async {
    // Check cache first
    final cacheKey = '${text}_$targetLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      return {
        'translatedText': _translationCache[cacheKey]!,
        'sourceLanguage': 'auto',
      };
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the language code from the language name
      final languageCode = LanguageUtils.getLanguageCode(targetLanguage);

      final translation = await _translator.translate(
        text,
        to: languageCode,
      );

      // Cache the result
      _translationCache[cacheKey] = translation.text;

      return {
        'translatedText': translation.text,
        'sourceLanguage': translation.sourceLanguage.code
      };
    } catch (e) {
      _error = 'Translation failed: $e';
      debugPrint(_error);
      return {
        'translatedText': text,
        'sourceLanguage': 'auto',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _translationCache.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
