/// Persists the last signed-in email for the biometric "Welcome back" frame.
///
/// Not a secret — plain [SharedPreferences]. Auth tokens stay in the keychain.
/// Under `flutter test` (`FLUTTER_TEST=true`) uses in-memory only so the
/// platform channel is never awaited (it hangs without a mock).
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'skiflux.last_signed_in_email';

bool get _useMemoryOnly {
  if (kIsWeb) return false;
  return Platform.environment['FLUTTER_TEST'] == 'true';
}

class SessionEmailStore {
  String? _memory;

  Future<void> write(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    _memory = trimmed;
    if (_useMemoryOnly) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, trimmed);
    } catch (_) {}
  }

  Future<String?> read() async {
    if (_useMemoryOnly) {
      final mem = _memory;
      if (mem == null || mem.isEmpty) return null;
      return mem;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key);
      if (value != null && value.trim().isNotEmpty) {
        _memory = value.trim();
        return _memory;
      }
    } catch (_) {}
    final mem = _memory;
    if (mem == null || mem.isEmpty) return null;
    return mem;
  }

  Future<void> clear() async {
    _memory = null;
    if (_useMemoryOnly) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

final sessionEmailStoreProvider = Provider<SessionEmailStore>(
  (_) => SessionEmailStore(),
);
