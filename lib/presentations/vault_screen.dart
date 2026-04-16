import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../helper/encryption_helper.dart';
import '../session.dart';
import 'generator_screen.dart';
import 'account_screen.dart';

class VaultScreen extends StatefulWidget {
  @override
  _VaultScreenState createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    AccountContent(),   
    GeneratorContent(), 
    VaultContent(),     
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Tạo mã'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Két sắt'),
        ],
      ),
    );
  }
}

class VaultContent extends StatefulWidget {
  @override
  _VaultContentState createState() => _VaultContentState();
}

class _VaultContentState extends State<VaultContent> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String searchQuery = "";

  void _copy(BuildContext context, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: Duration(seconds: 1))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Két Sắt"),
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
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('passwords')
            .orderBy('serviceName')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi tải dữ liệu"));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          var docs = snapshot.data!.docs.where((d) => 
            d['serviceName'].toString().toLowerCase().contains(searchQuery)).toList();

          if (docs.isEmpty) return Center(child: Text("Không có mật khẩu nào"));

          return ListView.builder(
            itemCount: docs.length,
            padding: EdgeInsets.all(10),
            itemBuilder: (context, i) {
              var doc = docs[i];
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  onTap: () => _showFormDialog(context, doc: doc),
                  leading: CircleAvatar(child: Text(doc['serviceName'][0].toUpperCase())),
                  title: Text(doc['serviceName'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(doc['username']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        IconButton(
                        icon: Icon(Icons.person, size: 20), 
                        onPressed: () {
                          String username = doc['username'];
                          _copy(context, username, "Đã copy Tên đăng nhập");
                        }
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 20), 
                        onPressed: () {
                          String p = EncryptionHelper.decryptPassword(
                            doc['password'], 
                            doc['iv'], 
                            Session.masterPassword ?? ""
                          );
                          _copy(context, p, "Đã copy Mật khẩu");
                        }
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red, size: 20), 
                        onPressed: () => _confirmDelete(context, doc)
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context), 
        child: Icon(Icons.add)
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa mật khẩu cho ${doc['serviceName']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          TextButton(
            onPressed: () {
              doc.reference.delete();
              Navigator.pop(context);
            }, 
            child: Text("Xóa", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final sC = TextEditingController(text: doc != null ? doc['serviceName'] : "");
    final uC = TextEditingController(text: doc != null ? doc['username'] : "");
    
    String initialPass = "";
    if (doc != null) {
      initialPass = EncryptionHelper.decryptPassword(
        doc['password'], 
        doc['iv'], 
        Session.masterPassword ?? ""
      );
    }
    final pC = TextEditingController(text: initialPass);
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
                    obscureText: isObscured,
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off), 
                            onPressed: () => setState(() => isObscured = !isObscured)),
                          IconButton(icon: Icon(Icons.refresh, color: Colors.green), 
                            onPressed: () => setState(() { 
                              pC.text = EncryptionHelper.generateStrongPassword(); 
                              isObscured = false; 
                            })),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(value: strength, color: EncryptionHelper.getStrengthColor(strength)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
              ElevatedButton(
                onPressed: () async {
                  if (sC.text.isEmpty || pC.text.isEmpty) return;
                  final encryptedData = EncryptionHelper.encryptPassword(
                    pC.text.trim(), 
                    Session.masterPassword ?? ""
                  );

                  var data = {
                    'serviceName': sC.text.trim(), 
                    'username': uC.text.trim(), 
                    'password': encryptedData['pw'],
                    'iv': encryptedData['iv'],      
                    'updatedAt': Timestamp.now(),
                  };

                  if (doc == null) {
                    await FirebaseFirestore.instance
                        .collection('users').doc(uid)
                        .collection('passwords').add(data);
                  } else {
                    await doc.reference.update(data);
                  }
                  Navigator.pop(context);
                }, 
                child: Text("LƯU")
              )
            ],
          );
        }
      )
    );
  }
}