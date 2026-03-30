import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/config.dart';
import '../models/prediction_model.dart';

class ApiService {
  Future<PredictionModel?> predictImage(File imageFile, String modelName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(Config.predictUrl));

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? token = await user.getIdToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      request.fields['model_name'] = modelName;

      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return PredictionModel.fromJson(jsonResponse);
      } else {
        print("Lỗi server: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return null;
    }
  }

  Future<List<dynamic>> getPredictionHistory(String email) async {
    try {
      String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final response = await http.get(
        Uri.parse("${Config.baseUrl}/predict/history"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        print("User chưa có trong SQL Server");
        return [];
      } else {
        print("Lỗi Server: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return [];
    }
  }

  Future<bool> updateProfile(String username, File? avatarFile) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      print("🚀 Đang gửi update tới: ${Config.updateUserUrl}");

      var request = http.MultipartRequest('POST', Uri.parse(Config.updateUserUrl));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['username'] = username;

      if (avatarFile != null) {
        print("📸 Có file ảnh: ${avatarFile.path}");
        request.files.add(await http.MultipartFile.fromPath('avatar', avatarFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📩 Kết quả Server: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Lỗi kết nối ApiService: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> updateProfileWithResult(String username, File? avatarFile) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final uri = Uri.parse("${Config.baseUrl}/user/update");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['username'] = username;

      if (avatarFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Lỗi Server Profile: ${response.statusCode} - ${response.body}");
        return {
          "success": false,
          "message": "Server trả về lỗi: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("❌ Lỗi kết nối ApiService: $e");
      return {
        "success": false,
        "message": "Không thể kết nối tới Server"
      };
    }
  }
}
