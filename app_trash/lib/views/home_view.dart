import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_trash/views/history_view.dart';
import '../../services/api_service.dart';
import '../../models/prediction_model.dart';
import '../views/login_screen.dart';
import 'package:app_trash/views/profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ApiService _apiService = ApiService();
  final User? currentUser = FirebaseAuth.instance.currentUser; // Thông tin từ Firebase Auth

  File? _image;
  PredictionModel? _result;
  bool _isLoading = false;
  String _selectedModel = 'efficientnetv2b1';

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phân loại rác AI"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              accountName: Text(currentUser?.displayName ?? "Người dùng AI"),
              accountEmail: Text(currentUser?.email ?? "Chưa có email"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage("${currentUser!.photoURL!}?v=${DateTime.now().millisecondsSinceEpoch}")
                    : null,
                child: currentUser?.photoURL == null
                    ? Text(
                  currentUser?.email?[0].toUpperCase() ?? "U",
                  style: const TextStyle(fontSize: 30, color: Colors.green),
                )
                    : null,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Thông tin tài khoản'),
                onTap: () async {
                  Navigator.pop(context); // Đóng drawer trước

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileView()),
                  );
                  if (result == true) {
                    setState(() {
                      });
                  }
                },
            ),

            ListTile(
              leading: const Icon(Icons.history, color: Colors.green),
              title: const Text('Lịch sử sử dụng'),
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryView()),);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Chọn mô hình AI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'efficientnetv2b1', child: Text('efficientnetv2b1')),
                DropdownMenuItem(value: 'mobilenetv2_plus', child: Text('mobilenetv2_plus')),
                DropdownMenuItem(value: 'effica2custom(2)hybird', child: Text('EfficientNet Hybrid (Custom)')),
              ],
              onChanged: (value) => setState(() => _selectedModel = value!),
            ),

            const SizedBox(height: 25),
            GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) setState(() => _image = File(picked.path));
              },
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_image!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 60, color: Colors.green[300]),
                    const SizedBox(height: 10),
                    const Text("Chạm để chọn ảnh", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _image == null || _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  final res = await _apiService.predictImage(_image!, _selectedModel);
                  setState(() { _result = res; _isLoading = false; });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text("PHÂN TÍCH ẢNH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            if (_result != null)
              Container(
                margin: const EdgeInsets.only(top: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Text(_result!.label.toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 10),
                    Text("Độ tin cậy: ${_result!.confidence.toStringAsFixed(2)}%", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}