/// Encrypted persistence for the auth token pair.
///
/// Backed by `flutter_secure_storage` — iOS Keychain; on Android (10.x) values
/// are AES-encrypted with a Keystore-wrapped key, always. Deliberately NOT
/// `shared_preferences`, which is plaintext and would leave a refresh token
/// readable on a rooted device.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Reads/writes the token pair, and caches it in memory so the auth
/// interceptor doesn't hit the platform channel on every request.
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'skiflux.auth.access';
  static const _refreshKey = 'skiflux.auth.refresh';

  AuthTokens? _cached;

  /// True once [read] has run, so a genuinely-absent session is distinguishable
  /// from one that simply hasn't been loaded yet.
  bool _loaded = false;

  /// Synchronous view of the current tokens, for the interceptor's hot path.
  /// Null before the first [read] as well as when signed out.
  AuthTokens? get cached => _cached;

  Future<AuthTokens?> read() async {
    if (_loaded) return _cached;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    _loaded = true;
    if (access == null || refresh == null) return _cached = null;
    return _cached = AuthTokens(access: access, refresh: refresh);
  }

  Future<void> write(AuthTokens tokens) async {
    _cached = tokens;
    _loaded = true;
    await _storage.write(key: _accessKey, value: tokens.access);
    await _storage.write(key: _refreshKey, value: tokens.refresh);
  }

  /// Sign-out, and the terminal state of a failed refresh.
  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  /// Cheap gate for the profile auth check (Tier 1 #39) — presence only, no
  /// validity claim. A stored token can still be expired or blacklisted.
  Future<bool> hasSession() async => await read() != null;
}

/// flutter_secure_storage 10.x encrypts unconditionally on Android (AES via
/// Keystore-wrapped keys) — the old EncryptedSharedPreferences opt-in is gone,
/// so the default [AndroidOptions] here already means encrypted at rest.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ),
);

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(secureStorageProvider)),
);
