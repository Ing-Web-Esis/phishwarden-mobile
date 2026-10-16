class LinkRequest {
  const LinkRequest({required this.companyCode, required this.email});
  final String companyCode;
  final String email;
}

// Resultado del ingreso móvil. No es un token de autenticación.
class LinkResult {
  const LinkResult({
    required this.companyCode,
    required this.email,
    required this.isDemo,
    this.userId,
    this.companyName,
  });
  final String companyCode;
  final String email;
  final bool isDemo;
  final String? userId;
  final String? companyName;
}
