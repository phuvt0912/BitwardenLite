import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../session.dart';
import 'vault_screen.dart';
import 'login_screen.dart';
import '../helper/encryption_helper.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double strength = EncryptionHelper.checkStrength(_passwordController.text);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(25),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("ĐĂNG KÝ MASTER", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
          SizedBox(height: 15),
          TextField(
            controller: _passwordController,
            obscureText: true,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(labelText: "Master Password", border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: strength,
            color: EncryptionHelper.getStrengthColor(strength),
            backgroundColor: Colors.grey[200],
          ),
          Text("Độ mạnh mật khẩu", style: TextStyle(fontSize: 12)),
          SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                );
                Session.masterPassword = _passwordController.text.trim();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VaultScreen()));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            child: Text("ĐĂNG KÝ"),
          )),
          TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen())), child: Text("Đã có tài khoản? Đăng nhập"))
        ]),
      ),
    );
  }
}