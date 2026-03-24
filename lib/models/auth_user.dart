class AuthUser {
  final String id;
  final String username;
  final String role; // "Admin" | "Kasiyer"

  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
  });
}

