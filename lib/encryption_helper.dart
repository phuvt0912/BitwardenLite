import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';

class EncryptionHelper {
  static final _iv = encrypt.IV.fromLength(16);

  static encrypt.Key _deriveKey(String masterPassword) {
    var bytes = utf8.encode(masterPassword);
    var digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  static String encryptPassword(String plainText, String masterPassword) {
    if (masterPassword.isEmpty) return plainText;
    final key = _deriveKey(masterPassword);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(plainText, iv: _iv).base64;
  }

  static String decryptPassword(String encryptedBase64, String masterPassword) {
    if (masterPassword.isEmpty) return "No Key";
    try {
      final key = _deriveKey(masterPassword);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      return "Lỗi giải mã";
    }
  }

  static String generateStrongPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    return List.generate(16, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // Đánh giá độ mạnh mật khẩu (0.0 -> 1.0)
  static double checkStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0;
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    return strength;
  }

  static Color getStrengthColor(double strength) {
    if (strength <= 0.4) return Colors.red;
    if (strength <= 0.7) return Colors.orange;
    return Colors.green;
  }
}