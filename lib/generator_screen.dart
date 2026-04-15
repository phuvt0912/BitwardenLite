import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'encryption_helper.dart';

class GeneratorContent extends StatefulWidget {
  @override
  _GeneratorContentState createState() => _GeneratorContentState();
}

class _GeneratorContentState extends State<GeneratorContent> {
  final TextEditingController _passController = TextEditingController();
  double _strength = 0;

  @override
  void initState() {
    super.initState();
    _generateNew(); // Tạo sẵn một mã khi vừa mở tab
  }

  void _generateNew() {
    setState(() {
      _passController.text = EncryptionHelper.generateStrongPassword();
      _updateStrength(_passController.text);
    });
  }

  void _updateStrength(String value) {
    setState(() {
      _strength = EncryptionHelper.checkStrength(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trình tạo mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Đánh giá mật khẩu của bạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _passController,
              onChanged: _updateStrength,
              style: TextStyle(fontSize: 20, letterSpacing: 1.2, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Mật khẩu",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _passController.text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã sao chép!")));
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Độ mạnh: ${(_strength * 100).toInt()}%"),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _strength,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                color: EncryptionHelper.getStrengthColor(_strength),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _generateNew,
                icon: Icon(Icons.refresh),
                label: Text("TẠO MẬT KHẨU NGẪU NHIÊN"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            SizedBox(height: 40),
            _buildGuideline(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideline() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tiêu chuẩn mật khẩu mạnh:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
          SizedBox(height: 10),
          Text("• Có ít nhất 12 ký tự"),
          Text("• Bao gồm chữ Hoa và chữ Thường"),
          Text("• Có ít nhất một chữ số"),
          Text("• Có ký tự đặc biệt (!@#\$%^&...)"),
        ],
      ),
    );
  }
}