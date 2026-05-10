import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../data/local/hive_service.dart';
import '../../shared/models/berkas_model.dart';
import '../../shared/models/category_model.dart';

/// Encrypted backup format: .bkse (BerkasKu Secure Export)
///
/// File layout (binary):
///   [4 bytes] magic = 0x42 0x4B 0x53 0x45 ("BKSE")
///   [1 byte]  version = 0x01
///   [16 bytes] random salt for PBKDF2
///   [32 bytes] HMAC-SHA256 of the encrypted payload (for integrity + PIN verification)
///   [N bytes]  encrypted payload = XOR-cipher(GZIP(JSON), derived_key)
///
/// Key derivation: PBKDF2-HMAC-SHA256 with 60,000 iterations, 32-byte output.
/// Stream cipher: SHA256-CTR (keystream = SHA256(key || counter), 32 bytes per block).
class BackupService {
  static const _magic = [0x42, 0x4B, 0x53, 0x45];
  static const _version = 0x01;
  static const _saltLength = 16;
  static const _keyLength = 32;

  // ── Export ────────────────────────────────────────────────────────────────

  /// Serialize all berkas + categories, compress, encrypt with [pin].
  /// Returns raw bytes to be saved as a .bkse file.
  static Future<Uint8List> exportBytes(String pin) async {
    final allBerkas = HiveService.getAllBerkas();
    final allCategories = HiveService.getAllCategories();

    final payload = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'berkas': allBerkas.map((b) => b.toMap()).toList(),
      'categories': allCategories.map((c) => c.toMap()).toList(),
    });

    final compressed =  GZipEncoder().encode(utf8.encode(payload))!;
    final salt = _randomBytes(_saltLength);

    // Derive key in background isolate (PBKDF2 is CPU-intensive)
    final key = await compute(_pbkdf2Compute, {
      'password': pin,
      'salt': salt.toList(),
      'keyLength': _keyLength,
    });

    final encrypted = _streamXor(Uint8List.fromList(compressed), Uint8List.fromList(key));
    final hmac = Hmac(sha256, key).convert(encrypted).bytes;

    final out = BytesBuilder();
    out.add(_magic);
    out.addByte(_version);
    out.add(salt);
    out.add(hmac);
    out.add(encrypted);
    return out.toBytes();
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Parse [bytes] from a .bkse file, verify PIN, restore all data.
  static Future<BackupResult> importBytes(Uint8List bytes, String pin) async {
    try {
      // Minimum size check
      if (bytes.length < _magic.length + 1 + _saltLength + 32 + 1) {
        return BackupResult.error('File terlalu kecil atau tidak valid');
      }

      // Validate magic
      for (var i = 0; i < _magic.length; i++) {
        if (bytes[i] != _magic[i]) {
          return BackupResult.error('Format file tidak dikenali. Pastikan file berekstensi .bkse');
        }
      }

      var offset = _magic.length;
      final version = bytes[offset++];
      if (version != _version) {
        return BackupResult.error('Versi backup tidak didukung (v$version)');
      }

      final salt = bytes.sublist(offset, offset + _saltLength);
      offset += _saltLength;

      final storedHmac = bytes.sublist(offset, offset + 32);
      offset += 32;

      final encrypted = bytes.sublist(offset);

      // Derive key
      final key = await compute(_pbkdf2Compute, {
        'password': pin,
        'salt': salt.toList(),
        'keyLength': _keyLength,
      });

      // Verify HMAC (also proves PIN is correct)
      final computedHmac = Hmac(sha256, key).convert(encrypted).bytes;
      if (!_constantTimeEquals(storedHmac, computedHmac)) {
        return BackupResult.error('PIN salah atau file telah dimodifikasi');
      }

      // Decrypt (XOR is symmetric)
      final compressed = _streamXor(encrypted, Uint8List.fromList(key));

      // Decompress
      final decompressed =  GZipDecoder().decodeBytes(compressed);
      final data = jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;

      // Restore categories first (berkas may reference them)
      final categoriesData = (data['categories'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final catMap in categoriesData) {
        await HiveService.saveCategory(CategoryModel.fromMap(catMap));
      }

      final berkasData = (data['berkas'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final bMap in berkasData) {
        await HiveService.saveBerkas(BerkasModel.fromMap(bMap));
      }

      return BackupResult.success(
        berkasCount: berkasData.length,
        categoryCount: categoriesData.length,
      );
    } on FormatException {
      return BackupResult.error('PIN salah atau file rusak');
    } catch (e) {
      return BackupResult.error('Gagal mengimpor: $e');
    }
  }

  // ── Crypto ────────────────────────────────────────────────────────────────

  /// SHA256-CTR stream cipher (symmetric: encrypt = decrypt).
  static Uint8List _streamXor(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    const blockSize = 32;
    var counter = 0;
    List<int> block = [];
    var blockPos = blockSize; // forces first block generation

    for (var i = 0; i < data.length; i++) {
      if (blockPos >= blockSize) {
        final counterBytes = Uint8List(8);
        for (var j = 0; j < 8; j++) {
          counterBytes[j] = (counter >> (j * 8)) & 0xFF;
        }
        final input = Uint8List(key.length + 8)
          ..setAll(0, key)
          ..setAll(key.length, counterBytes);
        block = sha256.convert(input).bytes;
        blockPos = 0;
        counter++;
      }
      result[i] = data[i] ^ block[blockPos++];
    }
    return result;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}

// ── PBKDF2 (top-level for compute()) ─────────────────────────────────────────

/// PBKDF2-HMAC-SHA256 with 60,000 iterations. Top-level so it runs in isolate.
List<int> _pbkdf2Compute(Map<String, dynamic> params) {
  final password = utf8.encode(params['password'] as String);
  final salt = (params['salt'] as List).cast<int>();
  const iterations = 60000;
  final keyLength = params['keyLength'] as int;

  final blocks = (keyLength / 32).ceil();
  final result = <int>[];

  for (var i = 1; i <= blocks; i++) {
    final saltWithIndex = Uint8List(salt.length + 4)
      ..setAll(0, salt)
      ..[salt.length] = (i >> 24) & 0xFF
      ..[salt.length + 1] = (i >> 16) & 0xFF
      ..[salt.length + 2] = (i >> 8) & 0xFF
      ..[salt.length + 3] = i & 0xFF;

    var u = Hmac(sha256, password).convert(saltWithIndex).bytes;
    final t = List<int>.from(u);

    for (var j = 1; j < iterations; j++) {
      u = Hmac(sha256, password).convert(u).bytes;
      for (var k = 0; k < 32; k++) {
        t[k] ^= u[k];
      }
    }
    result.addAll(t);
  }

  return result.sublist(0, keyLength);
}

// ── Result ────────────────────────────────────────────────────────────────────

class BackupResult {
  final bool isSuccess;
  final String? errorMessage;
  final int berkasCount;
  final int categoryCount;

  const BackupResult._({
    required this.isSuccess,
    this.errorMessage,
    this.berkasCount = 0,
    this.categoryCount = 0,
  });

  factory BackupResult.success({
    required int berkasCount,
    required int categoryCount,
  }) =>
      BackupResult._(isSuccess: true, berkasCount: berkasCount, categoryCount: categoryCount);

  factory BackupResult.error(String message) => BackupResult._(isSuccess: false, errorMessage: message);
}
