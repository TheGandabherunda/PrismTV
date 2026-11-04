class AuthSession {
  final String ssoToken;
  final String uniqueId;
  final String crmid;
  final String? mobileNumber;
  final String? subscriberId;
  final DateTime? expiresAt;

  AuthSession({
    required this.ssoToken,
    required this.uniqueId,
    required this.crmid,
    this.mobileNumber,
    this.subscriberId,
    this.expiresAt,
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
    };
  }
}
