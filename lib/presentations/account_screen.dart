import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../helper/encryption_helper.dart';
import 'login_screen.dart';

class AccountContent extends StatefulWidget {
  @override
  _AccountContentState createState() => _AccountContentState();
}

class _AccountContentState extends State<AccountContent> {
  bool _isUpdating = false;

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Session.masterPassword = null;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false);
  }

  void _showChangeMasterPasswordDialog() {
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Đổi mật khẩu Master"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldC, obscureText: true, decoration: InputDecoration(labelText: "Mật khẩu Master cũ")),
            TextField(controller: newC, obscureText: true, decoration: InputDecoration(labelText: "Mật khẩu Master mới")),
            TextField(controller: confirmC, obscureText: true, decoration: InputDecoration(labelText: "Xác nhận mật khẩu mới")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (oldC.text != Session.masterPassword) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mật khẩu cũ không đúng!")));
                return;
              }
              if (newC.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mật khẩu mới quá ngắn!")));
                return;
              }
              if (newC.text != confirmC.text) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xác nhận mật khẩu không khớp!")));
                return;
              }
              Navigator.pop(context);
              _updateAllPasswords(newC.text);
            },
            child: Text("CẬP NHẬT"),
          )
        ],
      ),
    );
  }

  /// Hàm quan trọng: Giải mã toàn bộ bằng Master Password cũ và mã hóa lại bằng Master Password mới
  Future<void> _updateAllPasswords(String newMaster) async {
    setState(() => _isUpdating = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final collection = FirebaseFirestore.instance.collection('users').doc(uid).collection('passwords');
      final snapshot = await collection.get();

      // Sử dụng WriteBatch để cập nhật nhiều tài liệu cùng lúc một cách hiệu quả
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (var doc in snapshot.docs) {
        // 1. Giải mã mật khẩu cũ (Sử dụng hàm decrypt mới nhận IV từ Firestore)
        String decrypted = EncryptionHelper.decryptPassword(
          doc['password'], 
          doc['iv'], 
          Session.masterPassword!
        );

        // 2. Mã hóa lại với Master Password mới (Hàm này tự tạo IV ngẫu nhiên mới)
        Map<String, String> reEncryptedData = EncryptionHelper.encryptPassword(decrypted, newMaster);
        
        // 3. Cập nhật đồng thời cả password mới và iv mới vào batch
        batch.update(doc.reference, {
          'password': reEncryptedData['pw'],
          'iv': reEncryptedData['iv'],
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit(); // Gửi toàn bộ thay đổi lên Firebase
      
      // Quan trọng: Cập nhật đồng bộ cả mật khẩu đăng nhập của Firebase Authentication
      await FirebaseAuth.instance.currentUser!.updatePassword(newMaster);

      Session.masterPassword = newMaster; // Cập nhật Session để ứng dụng tiếp tục hoạt động

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã cập nhật toàn bộ dữ liệu với mật khẩu mới!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Tài khoản")),
      body: _isUpdating 
      ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(), 
            SizedBox(height: 15), 
            Text("Đang mã hóa lại dữ liệu...", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Vui lòng không tắt ứng dụng", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ))
      : Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(radius: 40, backgroundColor: Colors.blue.shade100, child: Icon(Icons.person, size: 40, color: Colors.blue)),
            SizedBox(height: 10),
            Text(user?.email ?? "", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.vpn_key, color: Colors.blue),
                    title: Text("Đổi mật khẩu Master"),
                    subtitle: Text("Cập nhật lại toàn bộ két sắt"),
                    trailing: Icon(Icons.chevron_right),
                    onTap: _showChangeMasterPasswordDialog,
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                    onTap: () => _signOut(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}