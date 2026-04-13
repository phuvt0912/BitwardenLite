import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'encryption_helper.dart';
import 'session.dart';
import 'login_screen.dart';

class VaultScreen extends StatefulWidget {
  @override
  _VaultScreenState createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String searchQuery = "";

  void _copy(BuildContext context, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Két Sắt"),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Session.masterPassword = null;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false);
          })
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Tìm theo tên ứng dụng...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('passwords').orderBy('serviceName').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          var docs = snapshot.data!.docs.where((d) => 
            d['serviceName'].toString().toLowerCase().contains(searchQuery)).toList();

          return ListView.builder(
            itemCount: docs.length,
            padding: EdgeInsets.all(10),
            itemBuilder: (context, i) {
              var doc = docs[i];
              return Card(
                child: ListTile(
                  onTap: () => _showFormDialog(context, doc: doc),
                  title: Text(doc['serviceName'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(doc['username']),
                  trailing: Wrap(
                    children: [
                      IconButton(icon: Icon(Icons.person_outline), onPressed: () => _copy(context, doc['username'], "Đã copy User")),
                      IconButton(icon: Icon(Icons.copy), onPressed: () {
                        String p = EncryptionHelper.decryptPassword(doc['password'], Session.masterPassword ?? "");
                        _copy(context, p, "Đã copy Mật khẩu");
                      }),
                      IconButton(icon: Icon(Icons.delete_outline, color: Colors.red), onPressed: () => doc.reference.delete()),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showFormDialog(context), child: Icon(Icons.add)),
    );
  }

void _showFormDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final sC = TextEditingController(text: doc != null ? doc['serviceName'] : "");
    final uC = TextEditingController(text: doc != null ? doc['username'] : "");
    final pC = TextEditingController(text: doc != null ? EncryptionHelper.decryptPassword(doc['password'], Session.masterPassword ?? "") : "");
    
    // Biến để quản lý việc ẩn/hiện mật khẩu trong Dialog
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double strength = EncryptionHelper.checkStrength(pC.text);
          return AlertDialog(
            title: Text(doc == null ? "Thêm mới" : "Chỉnh sửa"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  TextField(controller: sC, decoration: InputDecoration(labelText: "Tên ứng dụng")),
                  TextField(controller: uC, decoration: InputDecoration(labelText: "Tên đăng nhập")),
                  TextField(
                    controller: pC,
                    obscureText: isObscured, // Ẩn mật khẩu tại đây
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min, // Giữ các icon nằm gọn bên phải
                        children: [
                          // Nút Copy mật khẩu nhanh
                          IconButton(
                            icon: Icon(Icons.copy, size: 20),
                            onPressed: () {
                              if (pC.text.isNotEmpty) {
                                _copy(context, pC.text, "Đã copy mật khẩu mới!");
                              }
                            },
                          ),
                          // Nút ẩn/hiện mật khẩu
                          IconButton(
                            icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off, size: 20),
                            onPressed: () => setState(() => isObscured = !isObscured),
                          ),
                          // Nút Generate mật khẩu
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.green, size: 20),
                            onPressed: () => setState(() {
                              pC.text = EncryptionHelper.generateStrongPassword();
                              isObscured = true; // Hiện mật khẩu vừa tạo để user thấy
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: strength, 
                    color: EncryptionHelper.getStrengthColor(strength),
                    backgroundColor: Colors.grey[200],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Độ mạnh: ${(strength * 100).toInt()}%", style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
              ElevatedButton(
                onPressed: () {
                  if (sC.text.isEmpty || uC.text.isEmpty || pC.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nhập đủ 3 dòng!")));
                    return;
                  }
                  String enc = EncryptionHelper.encryptPassword(pC.text, Session.masterPassword ?? "");
                  var data = {'serviceName': sC.text, 'username': uC.text, 'password': enc};
                  doc == null 
                    ? FirebaseFirestore.instance.collection('users').doc(uid).collection('passwords').add(data)
                    : doc.reference.update(data);
                  Navigator.pop(context);
                },
                child: Text("LƯU"),
              )
            ],
          );
        },
      ),
    );
  }
}