import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  // STT API Key
  String get sttApiKey => AppConfig.sttApiKey;
  
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastWords = '';

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission first
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('Microphone permission not granted');
        // Try to check if it's permanently denied
        if (status.isPermanentlyDenied) {
          print('Microphone permission permanently denied');
        }
        return false;
      }

      // Check if speech recognition is available on device
      final available = await _speech.initialize(
        onStatus: (status) {
          print('Speech recognition status: $status');
        },
        onError: (error) {
          print('Speech recognition error: $error');
        },
      );

      if (!available) {
        print('Speech recognition not available on this device');
        return false;
      }

      _isInitialized = true;
      
      // Initialize TTS
      try {
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
      } catch (e) {
        print('TTS initialization error: $e');
        // TTS failure shouldn't prevent speech recognition
      }

      return true;
    } catch (e) {
      print('Error initializing voice service: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function(String)? onError,
  }) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          // Check permissions again
          final permissionStatus = await Permission.microphone.status;
          if (!permissionStatus.isGranted) {
            onError?.call('Microphone permission is required for voice input. Please grant permission in app settings.');
          } else {
            onError?.call('Speech recognition is not available on this device. Please check your device settings.');
          }
          return;
        }
      }

      // Check microphone permission again before starting
      final permissionStatus = await Permission.microphone.status;
      if (!permissionStatus.isGranted) {
        // Try requesting again
        final newStatus = await Permission.microphone.request();
        if (!newStatus.isGranted) {
          _isListening = false;
          onError?.call('Microphone permission is required. Please grant permission in app settings.');
          return;
        }
      }

      if (_isListening) {
        await stopListening();
      }

      _isListening = true;
      _lastWords = '';

      final available = await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            // Final result - call onResult callback
            onResult(result.recognizedWords);
            _isListening = false;
          } else {
            // Partial result - update text in real-time
            if (onPartialResult != null && result.recognizedWords.isNotEmpty) {
              onPartialResult(result.recognizedWords);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        cancelOnError: false, // Don't cancel on error, let it continue
        partialResults: true,
      );

      if (!available) {
        _isListening = false;
        onError?.call('Unable to start listening. Please check your microphone and try again.');
      }
    } catch (e) {
      _isListening = false;
      print('Error starting speech recognition: $e');
      onError?.call('Error starting voice recognition: ${e.toString()}');
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}

