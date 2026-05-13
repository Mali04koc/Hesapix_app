class AuthUser {
  final String id;
  final String username;
  final String email;
  final String role; // "Admin" | "Kasiyer"

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });
}

