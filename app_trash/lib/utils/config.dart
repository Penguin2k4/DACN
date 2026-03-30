class Config {
  static const String baseUrl = "https://ebulliently-basal-larry.ngrok-free.dev";
  static const String predictUrl = "$baseUrl/predict/";
  static const String checkUserUrl = "$baseUrl/auth/check-status"; // Kiểm tra User cũ/mới
  static const String syncUserUrl = "$baseUrl/auth/sync";
  static const String updateUserUrl = "$baseUrl/user/update";
}