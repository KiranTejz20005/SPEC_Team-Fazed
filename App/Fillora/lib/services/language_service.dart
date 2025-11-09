import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('hi', 'IN'), // Hindi
    Locale('ta', 'IN'), // Tamil
    Locale('te', 'IN'), // Telugu
    Locale('bn', 'BD'), // Bengali
    Locale('mr', 'IN'), // Marathi
    Locale('gu', 'IN'), // Gujarati
    Locale('kn', 'IN'), // Kannada
    Locale('ml', 'IN'), // Malayalam
    Locale('pa', 'IN'), // Punjabi
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'bn': 'বাংলা',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'pa': 'ਪੰਜਾਬੀ',
  };

  Locale _currentLocale = const Locale('en', 'US');

  Locale get currentLocale => _currentLocale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('locale') ?? 'en';
    _currentLocale = Locale(localeCode);
    Intl.defaultLocale = localeCode;
  }

  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    Intl.defaultLocale = locale.languageCode;
  }

  String getLanguageName(String code) {
    return languageNames[code] ?? code;
  }

  // Translation helper (in a real app, you'd use a proper i18n package)
  String translate(String key, {Map<String, String>? params}) {
    // This is a placeholder - in production, use proper translation files
    final translations = _getTranslations();
    String text = translations[_currentLocale.languageCode]?[key] ?? key;
    
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{{$key}}', value);
      });
    }
    
    return text;
  }

  Map<String, Map<String, String>> _getTranslations() {
    return {
      'en': {
        'app_name': 'Fillora.in',
        'dashboard': 'Dashboard',
        'my_forms': 'My Forms',
        'templates': 'Templates',
        'history': 'History',
        'settings': 'Settings',
        'start_new_form': 'Start New Form',
        'upload_documents': 'Upload Documents',
        'review_finalize': 'Review & Finalize',
        'submit': 'Submit',
        'download_pdf': 'Download PDF',
        'edit_form': 'Edit Form',
        'save': 'Save',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'search': 'Search',
        'filter': 'Filter',
        'all': 'All',
        'completed': 'Completed',
        'in_progress': 'In Progress',
        'draft': 'Draft',
        'language': 'Language',
        'theme': 'Theme',
      },
      'hi': {
        'app_name': 'Fillora.in',
        'dashboard': 'डैशबोर्ड',
        'my_forms': 'मेरे फॉर्म',
        'templates': 'टेम्प्लेट',
        'history': 'इतिहास',
        'settings': 'सेटिंग्स',
        'start_new_form': 'नया फॉर्म शुरू करें',
        'upload_documents': 'दस्तावेज़ अपलोड करें',
        'review_finalize': 'समीक्षा और अंतिम रूप दें',
        'submit': 'सबमिट करें',
        'download_pdf': 'PDF डाउनलोड करें',
        'edit_form': 'फॉर्म संपादित करें',
        'save': 'सहेजें',
        'cancel': 'रद्द करें',
        'delete': 'हटाएं',
        'search': 'खोजें',
        'filter': 'फ़िल्टर',
        'all': 'सभी',
        'completed': 'पूर्ण',
        'in_progress': 'प्रगति में',
        'draft': 'ड्राफ्ट',
        'language': 'भाषा',
        'theme': 'थीम',
      },
    };
  }
}

