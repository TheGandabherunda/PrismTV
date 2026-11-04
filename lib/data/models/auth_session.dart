class AuthSession {
  final String ssoToken;
  final String uniqueId;
  final String crmid;
  final String? mobileNumber;
  final String? subscriberId;
  final DateTime? expiresAt;
  final bool isDemo;

  AuthSession({
    required this.ssoToken,
    required this.uniqueId,
    required this.crmid,
    this.mobileNumber,
    this.subscriberId,
    this.expiresAt,
    this.isDemo = false,
  });

  bool get isValid => ssoToken.isNotEmpty && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      ssoToken: json['ssoToken'] ?? '',
      uniqueId: json['uniqueId'] ?? '',
      crmid: json['crmid'] ?? '',
      mobileNumber: json['mobileNumber'],
      subscriberId: json['subscriberId'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isDemo: json['isDemo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssoToken': ssoToken,
      'uniqueId': uniqueId,
      'crmid': crmid,
      'mobileNumber': mobileNumber,
      'subscriberId': subscriberId,
      'expiresAt': expiresAt?.toIso8601String(),
      'isDemo': isDemo,
    };
  }

  factory AuthSession.demo() {
    return AuthSession(
      ssoToken: 'demo_token_prism_tv',
      uniqueId: 'prism_demo_user',
      crmid: 'prism_demo_crmid',
      mobileNumber: '+91 98765 43210',
      isDemo: true,
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
  }
}

