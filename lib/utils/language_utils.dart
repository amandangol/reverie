class LanguageUtils {
  static final List<Map<String, String>> allLanguages = [
    {'name': 'Afrikaans', 'code': 'af', 'flag': '🇿🇦'},
    {'name': 'Albanian', 'code': 'sq', 'flag': '🇦🇱'},
    {'name': 'Amharic', 'code': 'am', 'flag': '🇪🇹'},
    {'name': 'Arabic', 'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'Armenian', 'code': 'hy', 'flag': '🇦🇲'},
    {'name': 'Azerbaijani', 'code': 'az', 'flag': '🇦🇿'},
    {'name': 'Basque', 'code': 'eu', 'flag': '🇪🇸'},
    {'name': 'Belarusian', 'code': 'be', 'flag': '🇧🇾'},
    {'name': 'Bengali', 'code': 'bn', 'flag': '🇧🇩'},
    {'name': 'Bosnian', 'code': 'bs', 'flag': '🇧🇦'},
    {'name': 'Bulgarian', 'code': 'bg', 'flag': '🇧🇬'},
    {'name': 'Catalan', 'code': 'ca', 'flag': '🇪🇸'},
    {'name': 'Cebuano', 'code': 'ceb', 'flag': '🇵🇭'},
    {'name': 'Chinese (Simplified)', 'code': 'zh-CN', 'flag': '🇨🇳'},
    {'name': 'Chinese (Traditional)', 'code': 'zh-TW', 'flag': '🇹🇼'},
    {'name': 'Corsican', 'code': 'co', 'flag': '🇫🇷'},
    {'name': 'Croatian', 'code': 'hr', 'flag': '🇭🇷'},
    {'name': 'Czech', 'code': 'cs', 'flag': '🇨🇿'},
    {'name': 'Danish', 'code': 'da', 'flag': '🇩🇰'},
    {'name': 'Dutch', 'code': 'nl', 'flag': '🇳🇱'},
    {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
    {'name': 'Esperanto', 'code': 'eo', 'flag': '🌍'},
    {'name': 'Estonian', 'code': 'et', 'flag': '🇪🇪'},
    {'name': 'Filipino', 'code': 'tl', 'flag': '🇵🇭'},
    {'name': 'Finnish', 'code': 'fi', 'flag': '🇫🇮'},
    {'name': 'French', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'Frisian', 'code': 'fy', 'flag': '🇳🇱'},
    {'name': 'Galician', 'code': 'gl', 'flag': '🇪🇸'},
    {'name': 'Georgian', 'code': 'ka', 'flag': '🇬🇪'},
    {'name': 'German', 'code': 'de', 'flag': '🇩🇪'},
    {'name': 'Greek', 'code': 'el', 'flag': '🇬🇷'},
    {'name': 'Gujarati', 'code': 'gu', 'flag': '🇮🇳'},
    {'name': 'Haitian Creole', 'code': 'ht', 'flag': '🇭🇹'},
    {'name': 'Hausa', 'code': 'ha', 'flag': '🇳🇬'},
    {'name': 'Hawaiian', 'code': 'haw', 'flag': '🇺🇸'},
    {'name': 'Hebrew', 'code': 'he', 'flag': '🇮🇱'},
    {'name': 'Hindi', 'code': 'hi', 'flag': '🇮🇳'},
    {'name': 'Hmong', 'code': 'hmn', 'flag': '🇱🇦'},
    {'name': 'Hungarian', 'code': 'hu', 'flag': '🇭🇺'},
    {'name': 'Icelandic', 'code': 'is', 'flag': '🇮🇸'},
    {'name': 'Igbo', 'code': 'ig', 'flag': '🇳🇬'},
    {'name': 'Indonesian', 'code': 'id', 'flag': '🇮🇩'},
    {'name': 'Irish', 'code': 'ga', 'flag': '🇮🇪'},
    {'name': 'Italian', 'code': 'it', 'flag': '🇮🇹'},
    {'name': 'Japanese', 'code': 'ja', 'flag': '🇯🇵'},
    {'name': 'Javanese', 'code': 'jw', 'flag': '🇮🇩'},
    {'name': 'Kannada', 'code': 'kn', 'flag': '🇮🇳'},
    {'name': 'Kazakh', 'code': 'kk', 'flag': '🇰🇿'},
    {'name': 'Khmer', 'code': 'km', 'flag': '🇰🇭'},
    {'name': 'Kinyarwanda', 'code': 'rw', 'flag': '🇷🇼'},
    {'name': 'Korean', 'code': 'ko', 'flag': '🇰🇷'},
    {'name': 'Kurdish', 'code': 'ku', 'flag': '🇹🇷'},
    {'name': 'Kyrgyz', 'code': 'ky', 'flag': '🇰🇬'},
    {'name': 'Lao', 'code': 'lo', 'flag': '🇱🇦'},
    {'name': 'Latin', 'code': 'la', 'flag': '🇻🇦'},
    {'name': 'Latvian', 'code': 'lv', 'flag': '🇱🇻'},
    {'name': 'Lithuanian', 'code': 'lt', 'flag': '🇱🇹'},
    {'name': 'Luxembourgish', 'code': 'lb', 'flag': '🇱🇺'},
    {'name': 'Macedonian', 'code': 'mk', 'flag': '🇲🇰'},
    {'name': 'Malagasy', 'code': 'mg', 'flag': '🇲🇬'},
    {'name': 'Malay', 'code': 'ms', 'flag': '🇲🇾'},
    {'name': 'Malayalam', 'code': 'ml', 'flag': '🇮🇳'},
    {'name': 'Maltese', 'code': 'mt', 'flag': '🇲🇹'},
    {'name': 'Maori', 'code': 'mi', 'flag': '🇳🇿'},
    {'name': 'Marathi', 'code': 'mr', 'flag': '🇮🇳'},
    {'name': 'Mongolian', 'code': 'mn', 'flag': '🇲🇳'},
    {'name': 'Myanmar', 'code': 'my', 'flag': '🇲🇲'},
    {'name': 'Nepali', 'code': 'ne', 'flag': '🇳🇵'},
    {'name': 'Norwegian', 'code': 'no', 'flag': '🇳🇴'},
    {'name': 'Odia', 'code': 'or', 'flag': '🇮🇳'},
    {'name': 'Pashto', 'code': 'ps', 'flag': '🇦🇫'},
    {'name': 'Persian', 'code': 'fa', 'flag': '🇮🇷'},
    {'name': 'Polish', 'code': 'pl', 'flag': '🇵🇱'},
    {'name': 'Portuguese', 'code': 'pt', 'flag': '🇵🇹'},
    {'name': 'Punjabi', 'code': 'pa', 'flag': '🇮🇳'},
    {'name': 'Romanian', 'code': 'ro', 'flag': '🇷🇴'},
    {'name': 'Russian', 'code': 'ru', 'flag': '🇷🇺'},
    {'name': 'Samoan', 'code': 'sm', 'flag': '🇼🇸'},
    {'name': 'Scots Gaelic', 'code': 'gd', 'flag': '🏴󠁧󠁢󠁳󠁣󠁴󠁿'},
    {'name': 'Serbian', 'code': 'sr', 'flag': '🇷🇸'},
    {'name': 'Sesotho', 'code': 'st', 'flag': '🇱🇸'},
    {'name': 'Shona', 'code': 'sn', 'flag': '🇿🇼'},
    {'name': 'Sindhi', 'code': 'sd', 'flag': '🇵🇰'},
    {'name': 'Sinhala', 'code': 'si', 'flag': '🇱🇰'},
    {'name': 'Slovak', 'code': 'sk', 'flag': '🇸🇰'},
    {'name': 'Slovenian', 'code': 'sl', 'flag': '🇸🇮'},
    {'name': 'Somali', 'code': 'so', 'flag': '🇸🇴'},
    {'name': 'Spanish', 'code': 'es', 'flag': '🇪🇸'},
    {'name': 'Sundanese', 'code': 'su', 'flag': '🇮🇩'},
    {'name': 'Swahili', 'code': 'sw', 'flag': '🇰🇪'},
    {'name': 'Swedish', 'code': 'sv', 'flag': '🇸🇪'},
    {'name': 'Tajik', 'code': 'tg', 'flag': '🇹🇯'},
    {'name': 'Tamil', 'code': 'ta', 'flag': '🇮🇳'},
    {'name': 'Tatar', 'code': 'tt', 'flag': '🇷🇺'},
    {'name': 'Telugu', 'code': 'te', 'flag': '🇮🇳'},
    {'name': 'Thai', 'code': 'th', 'flag': '🇹🇭'},
    {'name': 'Tibetan', 'code': 'bo', 'flag': '🇨🇳'},
    {'name': 'Tigrinya', 'code': 'ti', 'flag': '🇪🇷'},
    {'name': 'Turkish', 'code': 'tr', 'flag': '🇹🇷'},
    {'name': 'Turkmen', 'code': 'tk', 'flag': '🇹🇲'},
    {'name': 'Ukrainian', 'code': 'uk', 'flag': '🇺🇦'},
    {'name': 'Urdu', 'code': 'ur', 'flag': '🇵🇰'},
    {'name': 'Uyghur', 'code': 'ug', 'flag': '🇨🇳'},
    {'name': 'Uzbek', 'code': 'uz', 'flag': '🇺🇿'},
    {'name': 'Vietnamese', 'code': 'vi', 'flag': '🇻🇳'},
    {'name': 'Welsh', 'code': 'cy', 'flag': '🏴󠁧󠁢󠁷󠁬󠁳󠁿'},
    {'name': 'Xhosa', 'code': 'xh', 'flag': '🇿🇦'},
    {'name': 'Yiddish', 'code': 'yi', 'flag': '🇮🇱'},
    {'name': 'Yoruba', 'code': 'yo', 'flag': '🇳🇬'},
    {'name': 'Zulu', 'code': 'zu', 'flag': '🇿🇦'},
  ];

  static String getLanguageCode(String languageName) {
    final language = allLanguages.firstWhere(
      (lang) => lang['name']!.toLowerCase() == languageName.toLowerCase(),
      orElse: () => {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    );
    return language['code']!;
  }

  static String getLanguageFlag(String languageName) {
    final language = allLanguages.firstWhere(
      (lang) => lang['name']!.toLowerCase() == languageName.toLowerCase(),
      orElse: () => {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    );
    return language['flag']!;
  }

  static List<Map<String, String>> filterLanguages(String query) {
    if (query.isEmpty) {
      return List.from(allLanguages);
    }
    return allLanguages
        .where((language) =>
            language['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
