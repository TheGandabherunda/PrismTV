import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents an active or historical subscription plan on the Jio subscriber account
class UserPlanInfo {
  final String planId;
  final String businessType;
  final String planType;
  final int subscriptionStart;
  final int subscriptionEnd;
  final String notes;

  UserPlanInfo({
    required this.planId,
    required this.businessType,
    required this.planType,
    required this.subscriptionStart,
    required this.subscriptionEnd,
    this.notes = '',
  });

  /// Check whether this subscription plan is currently valid and active
  bool get isActive {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // If no end date specified or end date is in the future
    final isAfterStart = subscriptionStart <= 0 || subscriptionStart <= nowSec;
    final isBeforeEnd = subscriptionEnd <= 0 || subscriptionEnd >= nowSec;
    return isAfterStart && isBeforeEnd;
  }

  DateTime? get startDate =>
      subscriptionStart > 0 ? DateTime.fromMillisecondsSinceEpoch(subscriptionStart * 1000) : null;

  DateTime? get endDate =>
      subscriptionEnd > 0 ? DateTime.fromMillisecondsSinceEpoch(subscriptionEnd * 1000) : null;

  String get formattedExpiry {
    final d = endDate;
    if (d == null) return 'Active';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  factory UserPlanInfo.fromJson(Map<String, dynamic> json) {
    return UserPlanInfo(
      planId: json['planid']?.toString() ?? json['planId']?.toString() ?? '',
      businessType: json['businessType']?.toString().toLowerCase().trim() ?? '',
      planType: json['plantype']?.toString().toLowerCase().trim() ?? '',
      subscriptionStart: int.tryParse(json['subscriptionstart']?.toString() ?? '0') ?? 0,
      subscriptionEnd: int.tryParse(json['subscriptionend']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planid': planId,
      'businessType': businessType,
      'plantype': planType,
      'subscriptionstart': subscriptionStart,
      'subscriptionend': subscriptionEnd,
      'notes': notes,
    };
  }
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final String ssoToken;
  final String uniqueId;
  final String crmid;
  final String? mobileNumber;
  final String? subscriberId;
  final DateTime? expiresAt;
  final List<UserPlanInfo> packageInfo;

  AuthSession({
    required this.accessToken,
    this.refreshToken = '',
    required this.ssoToken,
    required this.uniqueId,
    required this.crmid,
    this.mobileNumber,
    this.subscriberId,
    this.expiresAt,
    List<UserPlanInfo>? packageInfo,
  }) : packageInfo = packageInfo ?? extractPackagesFromJwt(accessToken);

  bool get isValid =>
      accessToken.isNotEmpty &&
      ssoToken.isNotEmpty &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  /// List of currently active subscription plans on this Jio mobile number
  List<UserPlanInfo> get activePlans => packageInfo.where((p) => p.isActive).toList();

  /// Does this mobile number hold an active standard Jio base plan?
  bool get hasActiveJioBase {
    if (packageInfo.isEmpty) {
      // If no explicit PackageInfo array in token but token is valid, default to active base
      return isValid;
    }
    return activePlans.any((p) =>
        p.businessType == 'jio' ||
        p.planId == '1' ||
        p.businessType.contains('jio') ||
        p.businessType.isEmpty);
  }

  /// Does this mobile number hold an active JioTV Premium / Live plan?
  bool get hasActivePremium {
    return activePlans.any((p) =>
        p.businessType == 'premium' ||
        p.planType == 'live' ||
        p.planId == '1032479' ||
        p.businessType.contains('prem'));
  }

  /// Set of all active plan IDs associated with this mobile number
  Set<String> get activePlanIds => activePlans.map((p) => p.planId).toSet();

  /// Extracts subscriber package information directly from the JWT payload without network calls
  static List<UserPlanInfo> extractPackagesFromJwt(String jwt) {
    if (jwt.isEmpty) return [];
    try {
      final parts = jwt.split('.');
      if (parts.length >= 2) {
        String payload = parts[1];
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        final decoded = utf8.decode(base64Url.decode(payload));
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? {};
        Map<String, dynamic>? planDetails;
        final extraRaw = data['extra'];
        if (extraRaw is String && extraRaw.isNotEmpty) {
          try {
            final extraJson = jsonDecode(extraRaw) as Map<String, dynamic>? ?? {};
            planDetails = extraJson['plandetails'] as Map<String, dynamic>?;
          } catch (_) {}
        } else if (extraRaw is Map<String, dynamic>) {
          planDetails = extraRaw['plandetails'] as Map<String, dynamic>?;
        }

        planDetails ??= (data['plandetails'] as Map<String, dynamic>?) ?? (json['plandetails'] as Map<String, dynamic>?);

        if (planDetails != null) {
          final pkgList = (planDetails['PackageInfo'] ?? planDetails['packageInfo']) as List<dynamic>? ?? [];
          return pkgList
              .map((e) => UserPlanInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AuthSession] Error parsing subscriber PackageInfo from JWT: $e');
    }
    return [];
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    DateTime? exp;
    final rawExp = json['expiresAt'];
    if (rawExp is DateTime) {
      exp = rawExp;
    } else if (rawExp != null) {
      exp = DateTime.tryParse(rawExp.toString());
    }

    final token = json['accessToken'] ?? json['authToken'] ?? '';
    List<UserPlanInfo>? plans;
    if (json['packageInfo'] is List) {
      plans = (json['packageInfo'] as List)
          .map((e) => UserPlanInfo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (plans == null || plans.isEmpty) {
      plans = extractPackagesFromJwt(token);
    }

    return AuthSession(
      accessToken: token,
      refreshToken: json['refreshToken'] ?? '',
      ssoToken: json['ssoToken'] ?? '',
      uniqueId: json['uniqueId'] ?? '',
      crmid: json['crmid'] ?? '',
      mobileNumber: json['mobileNumber'],
      subscriberId: json['subscriberId'] ?? json['crmid'],
      expiresAt: exp,
      packageInfo: plans,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'ssoToken': ssoToken,
      'uniqueId': uniqueId,
      'crmid': crmid,
      'mobileNumber': mobileNumber,
      'subscriberId': subscriberId,
      'expiresAt': expiresAt?.toIso8601String(),
      'packageInfo': packageInfo.map((p) => p.toJson()).toList(),
    };
  }
}
