enum UserRole { admin, jemaat }

UserRole parseRole(String? value) {
  if (value == 'admin') {
    return UserRole.admin;
  }
  return UserRole.jemaat;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.user,
  });

  final String token;
  final UserRole role;
  final Map<String, dynamic> user;
}

class ApiError implements Exception {
  const ApiError({
    required this.message,
    this.errorCode,
    this.traceId,
    this.statusCode,
  });

  final String message;
  final String? errorCode;
  final String? traceId;
  final int? statusCode;

  @override
  String toString() => message;
}
