import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_trash/views/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String apiUrl = "https://ebulliently-basal-larry.ngrok-free.dev/predict/";
  File? _image;
  String? _resultLabel;
  String? _confidence;
  String _selectedModel = 'efficientnetv2b1';
  bool _isLoading = false;
  final picker = ImagePicker();
  bool _isEmailVerified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> _checkEmailVerification() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) return;
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _isEmailVerified = user?.emailVerified ?? false;
        });
      }
      print("Kiểm tra xác thực: ${user?.emailVerified}");
      if (_isEmailVerified) {
        _timer?.cancel();
      }

    } catch (e) {
      print("Lỗi khi reload user: $e");
    }
  }
  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _resultLabel = null;
        _confidence = null;
      }
    });
  }

  Future uploadImage() async {
    if (_image == null) return;
    setState(() { _isLoading = true; _resultLabel = "Đang tinh toan"; });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      request.fields['model_name'] = _selectedModel;

      print("Đang gửi đến: $apiUrl");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          _resultLabel = jsonResponse['label'];
          double conf = (jsonResponse['confidence'] is double) ? jsonResponse['confidence'] * 100 : 0.0;
          _confidence = "${conf.toStringAsFixed(2)}%";
        });
      } else {
        setState(() { _resultLabel = "Lỗi Server (${response.statusCode})"; });
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() { _resultLabel = "Lỗi kết nối! Kiểm tra lại Ngrok."; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (!_isEmailVerified) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 100, color: Colors.orange),
                const SizedBox(height: 30),
                const Text(
                  'Vui lòng xác thực Email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Chúng tôi đã gửi một liên kết xác nhận đến email của bạn. Vui lòng kiểm tra hộp thư (cả mục Spam) và bấm vào link đó.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Hiện vòng xoay loading
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator())
                      );

                      await _checkEmailVerification();
                      if (mounted) Navigator.pop(context);

                      if (!_isEmailVerified) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Hệ thống chưa nhận được xác thực. Vui lòng đợi vài giây!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5
                    ),
                    child: const Text("TÔI ĐÃ XÁC THỰC XONG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    try {
                      await user?.sendEmailVerification();
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đã gửi lại email xác thực!"))
                        );
                      }
                    } catch (e) {
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Gửi quá nhanh! Vui lòng đợi chút."))
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Gửi lại link xác nhận'),
                ),

                const Spacer(),

                // Nút Đăng xuất
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Đăng xuất / Dùng tài khoản khác', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân loại rác AI', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Chọn Mô hình AI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  items: ['efficientnetv2b1', 'mobilenetv2_plus', 'effica2custom(2)hybird']
                      .map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _selectedModel = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: getImage,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 70, color: Colors.green[200]),
                    const SizedBox(height: 10),
                    Text('Chạm để chọn ảnh', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: (_image != null && !_isLoading) ? uploadImage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                icon: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isLoading ? 'ĐANG XỬ LÝ...' : 'PHÂN TÍCH ẢNH',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Kết quả trả về
            if (_resultLabel != null)
              Container(
                margin: const EdgeInsets.only(top: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _resultLabel!.contains("Lỗi") ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: _resultLabel!.contains("Lỗi") ? Colors.red.shade200 : Colors.green.shade200,
                      width: 2
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _resultLabel!.contains("Lỗi") ? "CẢNH BÁO" : "KẾT QUẢ",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _resultLabel!.contains("Lỗi") ? Colors.red : Colors.green
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _resultLabel!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _resultLabel!.contains("Lỗi") ? Colors.red[800] : Colors.green[800],
                      ),
                    ),
                    if (_confidence != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text(
                          "Độ tin cậy: $_confidence",
                          style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic, fontSize: 14),
                        ),
                      ),
                    ]
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}