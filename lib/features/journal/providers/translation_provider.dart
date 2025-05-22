import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:translator/translator.dart';

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
      final translation = await _translator.translate(
        text,
        to: _getLanguageCode(targetLanguage),
      );

      // Cache the result
      _translationCache[cacheKey] = translation.text;

      return {
        'translatedText': translation.text,
        'sourceLanguage': translation.sourceLanguage?.code ?? 'auto',
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

  String _getLanguageCode(String languageName) {
    switch (languageName.toLowerCase()) {
      case 'arabic':
        return 'ar';
      case 'bengali':
        return 'bn';
      case 'chinese (simplified)':
        return 'zh-CN';
      case 'czech':
        return 'cs';
      case 'danish':
        return 'da';
      case 'dutch':
        return 'nl';
      case 'finnish':
        return 'fi';
      case 'french':
        return 'fr';
      case 'german':
        return 'de';
      case 'greek':
        return 'el';
      case 'hebrew':
        return 'he';
      case 'hindi':
        return 'hi';
      case 'hungarian':
        return 'hu';
      case 'indonesian':
        return 'id';
      case 'italian':
        return 'it';
      case 'japanese':
        return 'ja';
      case 'korean':
        return 'ko';
      case 'malay':
        return 'ms';
      case 'malayalam':
        return 'ml';
      case 'marathi':
        return 'mr';
      case 'norwegian':
        return 'no';
      case 'persian':
        return 'fa';
      case 'polish':
        return 'pl';
      case 'portuguese':
        return 'pt';
      case 'romanian':
        return 'ro';
      case 'russian':
        return 'ru';
      case 'spanish':
        return 'es';
      case 'swedish':
        return 'sv';
      case 'tamil':
        return 'ta';
      case 'telugu':
        return 'te';
      case 'thai':
        return 'th';
      case 'turkish':
        return 'tr';
      case 'ukrainian':
        return 'uk';
      case 'urdu':
        return 'ur';
      case 'vietnamese':
        return 'vi';
      default:
        return 'en';
    }
  }

  void clearCache() {
    _translationCache.clear();
    notifyListeners();
  }
}
