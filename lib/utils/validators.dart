bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
  return emailRegex.hasMatch(email.trim());
}
