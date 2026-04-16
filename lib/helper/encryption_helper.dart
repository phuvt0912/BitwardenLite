import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';

class EncryptionHelper {

//Tạo khóa từ masterpassword
  static encrypt.Key _deriveKey(String masterPassword) {
    var bytes = utf8.encode(masterPassword); //Chuyển thành dạng bytes
    var digest = sha256.convert(bytes); //Băm mã bytes trên thành 32 bytes để làm khóa
    return encrypt.Key(Uint8List.fromList(digest.bytes)); //Đổi thành dạng Key của thư viện để tiện cho việc mã hóa và giải mã
  }

  //Hàm mã hóa
static Map<String, String> encryptPassword(String plainText, String masterPassword) {
    if (masterPassword.isEmpty) return {'pw': plainText, 'iv': ''};
    
    final key = _deriveKey(masterPassword);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    return {
      'pw': encrypted.base64,
      'iv': iv.base64, 
    };
  }

//Hàm giải mã
  static String decryptPassword(String encryptedBase64, String ivBase64, String masterPassword) {
    if (masterPassword.isEmpty) return "No Key";
    if (ivBase64.isEmpty) return "No IV";

    try {
      final key = _deriveKey(masterPassword);
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key)); //Tạo đối tượng encrypter với thuật toán AES với khóa đã tạo ở trên (Advanced Encryption Standard)
      
      return encrypter.decrypt64(encryptedBase64, iv: iv); // Giải mã đối tượng encrypter trên với chuỗi bị mã hóa và IV bị mã hóa được truyền vào. Kết quả trả về là chuỗi gốc chính là mật khẩu 
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