import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice tier tracks how far along the three-announcement sequence we are
/// for the current approaching turn instruction.
enum _VoiceTier {
  none,  // Not yet spoken for this turn
  early, // Spoken "In ~50m, turn right" (40–60m zone)
  near,  // Spoken "Turn right" (≤15m zone)
  now,   // Spoken "Turn now" (≤5m zone)
}

/// A cross-platform service that handles voice navigation instructions using flutter_tts.
class VoiceNavigationService {
  static final VoiceNavigationService _instance = VoiceNavigationService._internal();
  factory VoiceNavigationService() => _instance;
  VoiceNavigationService._internal() {
    _initTts();
  }

  late FlutterTts _flutterTts;
  bool _isVoiceEnabled = true;

  // Tier-based deduplication: tracks how far we've announced for the current turn
  _VoiceTier _lastSpokenTier = _VoiceTier.none;
  int _lastTrackedInstructionIndex = -1;

  bool get isVoiceEnabled => _isVoiceEnabled;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      if (onSpeechStateChanged != null) onSpeechStateChanged!();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      if (onSpeechStateChanged != null) onSpeechStateChanged!();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      if (onSpeechStateChanged != null) onSpeechStateChanged!();
    });

    // Configure TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for better clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    if (!kIsWeb) {
      // Mobile-specific config
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt
      );
    }
  }

  VoidCallback? onSpeechStateChanged;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isVoiceEnabled = prefs.getBool('voice_navigation_enabled') ?? true;
  }

  Future<void> toggleVoice() async {
    _isVoiceEnabled = !_isVoiceEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_navigation_enabled', _isVoiceEnabled);
    
    if (_isVoiceEnabled) {
      speak("Voice navigation enabled.");
    } else {
      stop();
    }
  }

  /// Speaks a simple text message immediately (bypasses tier tracking).
  void speak(String text) async {
    if (!_isVoiceEnabled) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error in TTS: $e');
    }
  }

  /// Stops any ongoing speech.
  void stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Google Maps–style 3-tier voice guidance.
  ///
  /// Tiers (in escalating order):
  ///   early → "In ~50 meters, turn right"  (triggered in the 40–60 m window)
  ///   near  → "Turn right"                  (triggered when ≤ 15 m)
  ///   now   → "Turn now"                    (triggered when ≤ 5 m)
  ///
  /// Each tier fires AT MOST ONCE per instruction index. Once spoken it never
  /// repeats unless the instruction advances (new turning point).
  void speakNavigationInstruction(
      String turnText, double distToTurn, int instructionIndex) {
    if (!_isVoiceEnabled) return;

    // Reset tier tracker when we move to a new instruction
    if (instructionIndex != _lastTrackedInstructionIndex) {
      _lastSpokenTier = _VoiceTier.none;
      _lastTrackedInstructionIndex = instructionIndex;
    }

    _VoiceTier targetTier = _VoiceTier.none;
    String speechText = '';

    if (distToTurn <= 5.0) {
      // Tier 3: "Turn now"
      targetTier = _VoiceTier.now;
      speechText = 'Turn now';
    } else if (distToTurn <= 15.0) {
      // Tier 2: bare turn action — "Turn right"
      targetTier = _VoiceTier.near;
      speechText = turnText;
    } else if (distToTurn > 40.0 && distToTurn <= 60.0) {
      // Tier 1: early warning — "In 50 meters, turn right"
      targetTier = _VoiceTier.early;
      speechText =
          'In ${distToTurn.round()} meters, ${turnText.toLowerCase()}';
    }

    // Only speak if we have escalated to a higher tier than last time
    if (targetTier != _VoiceTier.none &&
        targetTier.index > _lastSpokenTier.index) {
      _lastSpokenTier = targetTier;
      speak(speechText);
    }
  }

  /// Resets all voice tracking state (call on navigation start / reroute).
  void resetLastSpoken() {
    _lastSpokenTier = _VoiceTier.none;
    _lastTrackedInstructionIndex = -1;
  }
}
