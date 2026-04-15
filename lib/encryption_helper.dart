import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';

class EncryptionHelper {

//Tạo khóa từ masterpassword
  static encrypt.Key _deriveKey(String masterPassword) {
    var bytes = utf8.encode(masterPassword);
    print("Bước 1 lấy khóa");
    var digest = sha256.convert(bytes);
    print("Bước 2: Khóa đã được băm bằng SHA-256.");
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }
static Map<String, String> encryptPassword(String plainText, String masterPassword) {
    if (masterPassword.isEmpty) return {'pw': plainText, 'iv': ''};
    
    final key = _deriveKey(masterPassword);
    final iv = encrypt.IV.fromLength(16); // Tạo IV ngẫu nhiên mỗi lần gọi
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    return {
      'pw': encrypted.base64,
      'iv': iv.base64, 
    };
  }

  static String decryptPassword(String encryptedBase64, String ivBase64, String masterPassword) {
    if (masterPassword.isEmpty) return "No Key";
    if (ivBase64.isEmpty) return "No IV";

    try {
      final key = _deriveKey(masterPassword);
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      return encrypter.decrypt64(encryptedBase64, iv: iv);
    } catch (e) {
      return "Lỗi giải mã";
    }
  }

  static String generateStrongPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    return List.generate(16, (index) => chars[Random().nextInt(chars.length)]).join();
  }

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