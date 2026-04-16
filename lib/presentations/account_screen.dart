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

  void _showChangeMasterPasswordDialog() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: Không tìm thấy người dùng!")));
      return;
    }
    else{
      try {
        if(!user.emailVerified) {
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng xác nhận email trước khi đổi mật khẩu!")));
          return;
        }
      }
      catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        return;
      }
    } 
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

  Future<void> _updateAllPasswords(String newMaster) async {
    setState(() => _isUpdating = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final collection = FirebaseFirestore.instance.collection('users').doc(uid).collection('passwords');
      final snapshot = await collection.get();

      final String? oldMaster = Session.masterPassword;
      await FirebaseAuth.instance.currentUser!.updatePassword(newMaster);
      Session.masterPassword = newMaster;

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        String decrypted = EncryptionHelper.decryptPassword(
          doc['password'], 
          doc['iv'], 
          oldMaster!
        );

        Map<String, String> reEncryptedData = EncryptionHelper.encryptPassword(decrypted, Session.masterPassword!);
        
        batch.update(doc.reference, {
          'password': reEncryptedData['pw'],
          'iv': reEncryptedData['iv'],
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit(); 
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