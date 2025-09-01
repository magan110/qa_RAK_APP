class AuthService {
  static Future<bool> login(String userId, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // TODO: Replace with actual API call
    // For now, accept any non-empty credentials
    return userId.isNotEmpty && password.isNotEmpty;
  }

  static Future<bool> loginWithOtp(String mobile, String otp) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // TODO: Replace with actual API call
    return mobile.isNotEmpty && otp.isNotEmpty;
  }

  static Future<bool> sendOtp(String mobile) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // TODO: Replace with actual API call
    return mobile.isNotEmpty;
  }

  static Future<void> logout() async {
    // TODO: Clear stored tokens/session data
    await Future.delayed(const Duration(milliseconds: 500));
  }
}