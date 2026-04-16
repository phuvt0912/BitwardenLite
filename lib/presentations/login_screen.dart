import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../session.dart';
import 'vault_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Session.masterPassword = _passwordController.text.trim();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VaultScreen()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đăng nhập thất bại!")));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(25),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.blue),
          SizedBox(height: 20),
          Text("BITWARDEN LITE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
          SizedBox(height: 15),
          TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Master Password", border: OutlineInputBorder()), obscureText: true),
          SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _handleLogin, child: Text("ĐĂNG NHẬP"))),
          TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegisterScreen())), 
                     child: Text("Chưa có tài khoản? Đăng ký ngay"))
        ]),
      ),
    );
  }
}