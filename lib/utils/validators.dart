class Validators {
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@nitc.ac.in') || 
           lower.endsWith('@gmail.com');
  }

  static bool isStrongPassword(String password) {
    return password.length >= 6;
  }
}
