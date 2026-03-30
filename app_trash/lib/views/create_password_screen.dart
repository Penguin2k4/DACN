import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/config.dart';
import 'package:app_trash/views/home_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final User firebaseUser;

  const CreatePasswordScreen({super.key, required this.firebaseUser});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailVerified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = widget.firebaseUser.emailVerified;
    if (!_isEmailVerified) {
      _sendVerificationEmail();
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await widget.firebaseUser.sendEmailVerification();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi email xác thực. Vui lòng kiểm tra hộp thư!")),
        );
      }
    } catch (e) {
      print("Lỗi gửi mail: $e");
    }
  }

  Future<void> _checkEmailVerified() async {
    await widget.firebaseUser.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      setState(() {
        _isEmailVerified = true;
      });
      _timer?.cancel();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xác thực thành công! Hãy tạo mật khẩu ngay.")),
        );
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (!_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng xác thực email trước!")));
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu không khớp!")));
      return;
    }
    if (_passController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu phải trên 6 ký tự")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String password = _passController.text.trim();

      await widget.firebaseUser.updatePassword(password);

      final url = Uri.parse(Config.syncUserUrl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firebase_uid": widget.firebaseUser.uid,
          "email": widget.firebaseUser.email,
          "full_name": widget.firebaseUser.displayName ?? "User Google",
          "password": password
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (c) => const HomeScreen()),
                (route) => false,
          );
        }
      } else {
        throw Exception("Lỗi Server SQL: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thiết lập tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_isEmailVerified) ...[
              const Icon(Icons.mark_email_unread, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Xác thực Email",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Chúng tôi đã gửi liên kết đến ${widget.firebaseUser.email}.\nVui lòng bấm vào liên kết để tiếp tục.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text("Đang chờ xác thực...", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              TextButton.icon(
                onPressed: _sendVerificationEmail,
                icon: const Icon(Icons.refresh),
                label: const Text("Gửi lại email"),
              )
            ]
            else ...[
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 10),
              const Text("Email đã được xác thực!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              const Text("Vui lòng tạo mật khẩu để hoàn tất đăng ký."),
              const SizedBox(height: 20),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mật khẩu mới", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Nhập lại mật khẩu", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeRegistration,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("HOÀN TẤT & ĐĂNG NHẬP"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
