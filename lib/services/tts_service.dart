import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class TTSService {
  TTSService._privateConstructor();
  static final TTSService _instance = TTSService._privateConstructor();
  factory TTSService() => _instance;

  final FlutterTts _tts = FlutterTts();
  final MethodChannel _methodChannel = const MethodChannel('flutter_tts');
  int _seq = 0; // sequence token to cancel previous speak calls
  bool _isPlaying = false;
  Completer<void>? _stopCompleter;
  int? _activeSeq;
  int? _lastRequestedSeq;

  Future<void> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.75);
      await _tts.setPitch(1.0);

      // Ensure the plugin notifies us when playback starts/stops so we can
      // reliably interrupt and wait for stop to complete.
      _tts.setStartHandler(() {
        _isPlaying = true;
        // debug: notify start
        // ignore: avoid_print
        print('[TTS] start seq=${_activeSeq ?? _lastRequestedSeq}');
      });
      _tts.setCompletionHandler(() {
        _isPlaying = false;
        _stopCompleter?.complete();
        // ignore: avoid_print
        print('[TTS] complete seq=${_activeSeq ?? _lastRequestedSeq}');
        _stopCompleter = null;
        _activeSeq = null;
      });
      _tts.setCancelHandler(() {
        _isPlaying = false;
        _stopCompleter?.complete();
        // ignore: avoid_print
        print('[TTS] cancel seq=${_activeSeq ?? _lastRequestedSeq}');
        _stopCompleter = null;
        _activeSeq = null;
      });
      _tts.setErrorHandler((msg) {
        _isPlaying = false;
        _stopCompleter?.complete();
        _stopCompleter = null;
        // ignore: avoid_print
        print('[TTS] error: $msg');
      });
      // Prefer awaiting completion on some platforms when speak is called
      try {
        // Do NOT await speak completion by default; making speak return
        // immediately allows calling stop() to interrupt playback.
        await _tts.awaitSpeakCompletion(false);
      } catch (_) {}

      // Try to enable queue mode that flushes previous utterances if
      // supported by the native plugin; this helps ensure that new
      // speak requests interrupt queued requests on some platforms.
      try {
        await _methodChannel.invokeMethod('setQueueMode', 1);
        // ignore: avoid_print
        print('[TTS] setQueueMode(1) invoked');
      } catch (e) {
        // plugin may not implement setQueueMode on all platforms/versions
        // ignore and continue.
        // ignore: avoid_print
        print('[TTS] setQueueMode call failed: $e');
      }
    } catch (_) {
      // Swallow init errors; speak() will still attempt to work.
    }
  }

  /// Request the engine to stop and wait up to [timeoutMs] for it to stop.
  /// Returns once the engine is no longer playing or [timeoutMs] passed.
  Future<void> _stopAndWait({int timeoutMs = 250}) async {
    try {
      _stopCompleter = Completer<void>();
      // ignore: avoid_print
      print('[TTS] requesting stop, timeout=${timeoutMs}ms');
      await _tts.stop();
      final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));

      while (DateTime.now().isBefore(deadline)) {
        if (!_isPlaying) break;
        if (_stopCompleter!.isCompleted) break;
        await Future.delayed(const Duration(milliseconds: 20));
      }
    } catch (_) {
      // ignore
    } finally {
      _stopCompleter = null;
    }
  }

  /// Speak `text`.
  ///
  /// If [waitForStop] is true, the method will attempt to stop current
  /// playback and wait briefly for the engine to signal that playback has
  /// stopped before starting the next utterance. If false (default), the
  /// engine will be asked to stop and the new utterance will be started
  /// immediately to provide a more responsive "interrupt and play next"
  /// experience when the user clicks repeatedly.
  Future<void> speak(String text, {bool waitForStop = false}) async {
    if (text.trim().isEmpty) return;
    try {
      // Increment sequence token for this speak request. Any previous
      // speak attempt that hasn't reached the actual speak() call yet
      // will see the token mismatch and abort.
      final int my = ++_seq;
      _lastRequestedSeq = my;
      // ignore: avoid_print
      print(
          '[TTS] speak requested seq=$my waitForStop=$waitForStop text=${text.replaceAll('\n', ' ')}');

      if (waitForStop) {
        // Legacy/safer behavior: wait briefly for engine to stop.
        try {
          final int timeoutMs = Platform.isWindows ? 700 : 250;
          await _stopAndWait(timeoutMs: timeoutMs);
        } catch (_) {
          // ignore stop errors
        } finally {
          _stopCompleter = null;
        }
        // If another speak was requested meanwhile, abort this one.
        if (my != _seq) return;
        _activeSeq = my;
        await _tts.speak(text);
      } else {
        // More responsive behavior: request stop and immediately start
        // the new utterance, avoiding waits that can make the UI feel
        // sluggish when the user taps multiple items quickly.
        try {
          // Request stop and wait a short time to allow the engine to
          // react — this increases the chance the stop actually interrupts
          // ongoing playback across various OSes without adding
          // noticable latency.
          await _stopAndWait(timeoutMs: Platform.isWindows ? 200 : 150);
        } catch (_) {}

        // If another speak was requested meanwhile, abort this one.
        if (my != _seq) return;
        _activeSeq = my;
        await _tts.speak(text);
      }
    } catch (_) {
      // ignore speak errors for now
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
