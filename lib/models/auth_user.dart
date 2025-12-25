class AuthUser {
  final int id;
  final String email;
  final String nombre;
  final String role;
  final String? foto;
  final bool? emailVerified;
  final DateTime? lastLogin;
  final DateTime createdAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.nombre,
    required this.role,
    this.foto,
    this.emailVerified,
    this.lastLogin,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      role: json['role'] as String,
      foto: json['foto'] as String?,
      emailVerified: json['emailVerified'] as bool?,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'role': role,
      'foto': foto,
      'emailVerified': emailVerified,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isProfesor => role == 'PROFESOR' || role == 'ADMIN';
  bool get isPadre => role == 'PADRE';
  bool get isAdmin => role == 'ADMIN';
}
