import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_tv/data/models/auth_session.dart';
import 'package:prism_tv/data/models/channel_model.dart';

void main() {
  group('Cross-Platform Mobile Number Subscription Filter Tests', () {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Sessions setup
    final baseOnlySession = AuthSession(
      accessToken: 'dummy.jwt.token',
      ssoToken: 'sso_valid_token',
      uniqueId: 'uid123',
      crmid: 'crm123',
      mobileNumber: '+919876543210',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      packageInfo: [
        UserPlanInfo(
          planId: '1',
          businessType: 'jio',
          planType: '',
          subscriptionStart: nowSec - 100000,
          subscriptionEnd: nowSec + 10000000,
        ),
      ],
    );

    final premiumSession = AuthSession(
      accessToken: 'dummy.jwt.token',
      ssoToken: 'sso_valid_token',
      uniqueId: 'uid123',
      crmid: 'crm123',
      mobileNumber: '+919876543210',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      packageInfo: [
        UserPlanInfo(
          planId: '1',
          businessType: 'jio',
          planType: '',
          subscriptionStart: nowSec - 100000,
          subscriptionEnd: nowSec + 10000000,
        ),
        UserPlanInfo(
          planId: '1032479',
          businessType: 'premium',
          planType: 'live',
          subscriptionStart: nowSec - 100000,
          subscriptionEnd: nowSec + 5000000,
        ),
      ],
    );

    final expiredSession = AuthSession(
      accessToken: 'dummy.jwt.token',
      ssoToken: 'sso_valid_token',
      uniqueId: 'uid123',
      crmid: 'crm123',
      mobileNumber: '+919876543210',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      packageInfo: [
        UserPlanInfo(
          planId: '1',
          businessType: 'jio',
          planType: '',
          subscriptionStart: nowSec - 20000000,
          subscriptionEnd: nowSec - 1000, // Expired in past
        ),
      ],
    );

    // 2. Channel models
    final freeChannel = ChannelModel(
      channelId: 713,
      channelName: 'DD Chandana',
      logoUrl: '',
      categoryId: 1,
      categoryName: 'General',
      languageId: 13,
      languageName: 'Kannada',
      isHd: false,
      isCatchupAvailable: true,
      businessType: 'free',
      planType: 'free',
      packageIds: const ['1'],
      channelPrice: '0.00',
    );

    final standardJioChannel = ChannelModel(
      channelId: 143,
      channelName: 'CNBC TV18 Prime',
      logoUrl: '',
      categoryId: 16,
      categoryName: 'News',
      languageId: 6,
      languageName: 'English',
      isHd: true,
      isCatchupAvailable: true,
      businessType: 'jio',
      planType: 'premium',
      packageIds: const ['1', '6', '7', '23'],
      channelPrice: 'Rs 1.00',
    );

    final premiumChannel = ChannelModel(
      channelId: 144,
      channelName: 'Colors HD',
      logoUrl: '',
      categoryId: 5,
      categoryName: 'Entertainment',
      languageId: 1,
      languageName: 'Hindi',
      isHd: true,
      isCatchupAvailable: true,
      isPremium: true,
      businessType: 'premium',
      planType: 'premium',
      packageIds: const ['1', '6', '7', '23'],
      channelPrice: 'Rs 19.00',
    );

    test('Free channels are visible to all users (Guest, Base, Premium, Expired)', () {
      expect(freeChannel.isSubscribedFor(null), isTrue);
      expect(freeChannel.isSubscribedFor(expiredSession), isTrue);
      expect(freeChannel.isSubscribedFor(baseOnlySession), isTrue);
      expect(freeChannel.isSubscribedFor(premiumSession), isTrue);
    });

    test('Standard Jio channels are ONLY visible to users with active Jio base plan', () {
      expect(standardJioChannel.isSubscribedFor(null), isFalse);
      expect(standardJioChannel.isSubscribedFor(expiredSession), isFalse);
      expect(standardJioChannel.isSubscribedFor(baseOnlySession), isTrue);
      expect(standardJioChannel.isSubscribedFor(premiumSession), isTrue);
    });

    test('Premium paywall channels are STRICTLY visible ONLY to active Premium plan holders', () {
      expect(premiumChannel.isSubscribedFor(null), isFalse);
      expect(premiumChannel.isSubscribedFor(expiredSession), isFalse);
      expect(premiumChannel.isSubscribedFor(baseOnlySession), isFalse,
          reason: 'Standard Jio base number must NOT see premium channels');
      expect(premiumChannel.isSubscribedFor(premiumSession), isTrue,
          reason: 'Number with active premium live pack must see premium channels');
    });

    test('Restricted channel IDs are completely hidden even for premium subscribers', () {
      final restrictedIds = {144}; // Colors HD blocked
      expect(premiumChannel.isSubscribedFor(premiumSession, restrictedIds: restrictedIds), isFalse);
    });

    test('JWT Package extraction accurately decodes plan details offline', () {
      final inner = jsonEncode({
        'plandetails': {
          'PackageInfo': [
            {
              'planid': '1',
              'businessType': 'jio',
              'subscriptionstart': 1780000000,
              'subscriptionend': 1820000000,
            }
          ]
        }
      });
      final dummyPayload = jsonEncode({
        'data': {'extra': inner}
      });
      final base64Payload =
          'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode(dummyPayload)).replaceAll('=', '')}.signature';

      final extracted = AuthSession.extractPackagesFromJwt(base64Payload);
      expect(extracted.length, 1);
      expect(extracted[0].planId, '1');
      expect(extracted[0].businessType, 'jio');
      expect(extracted[0].isActive, isTrue);
    });
  });
}
