import 'package:flutter_test/flutter_test.dart';
import 'package:prism_tv/data/models/auth_session.dart';
import 'package:prism_tv/data/models/category_model.dart';
import 'package:prism_tv/data/models/channel_model.dart';
import 'package:prism_tv/data/models/epg_program_model.dart';
import 'package:prism_tv/data/models/language_model.dart';
import 'package:prism_tv/data/models/quality_option.dart';

void main() {
  group('PrismTV Core Models & Architecture Tests', () {
    test('ChannelModel properly parses JSON and categorizes', () {
      final json = {
        'channel_id': 757,
        'channel_name': 'Colors Kannada HD',
        'logoUrl': 'colors_kannada.png',
        'channelCategoryId': 5,
        'channelLanguageId': 13,
        'isHD': true,
      };

      final channel = ChannelModel.fromJson(json);

      expect(channel.channelId, 757);
      expect(channel.channelName, 'Colors Kannada HD');
      expect(channel.isHd, true);
      expect(channel.categoryName, 'Entertainment');
      expect(channel.languageName, 'Kannada');
      expect(channel.fullLogoUrl, contains('colors_kannada.png'));
    });

    test('AuthSession creates and validates active credentials', () {
      final session = AuthSession(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        ssoToken: 'test_token',
        uniqueId: 'test_user',
        crmid: 'test_crm',
        mobileNumber: '+919876543210',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(session.isValid, true);
      expect(session.accessToken, 'test_access_token');
      expect(session.ssoToken, 'test_token');
      expect(session.uniqueId, 'test_user');
      expect(session.mobileNumber, '+919876543210');

      final json = session.toJson();
      final restored = AuthSession.fromJson(json);
      expect(restored.accessToken, 'test_access_token');
      expect(restored.ssoToken, 'test_token');
      expect(restored.isValid, true);
    });

    test('EpgProgramModel calculates progress and status properly', () {
      final now = DateTime.now();
      final program = EpgProgramModel(
        showName: 'Maja Talkies',
        description: 'Kannada comedy talk show',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 30)),
      );

      expect(program.isNowPlaying, true);
      expect(program.progress, greaterThan(0.0));
      expect(program.progress, lessThanOrEqualTo(1.0));
    });

    test('Default category and language lists contain required entries', () {
      final categories = CategoryModel.defaultCategories;
      final languages = LanguageModel.defaultLanguages;

      expect(languages.any((l) => l.id == 'kannada'), isTrue);
      expect(languages.any((l) => l.id == 'hindi'), isTrue);
      expect(languages.any((l) => l.id == 'english'), isTrue);

      expect(categories.any((c) => c.id == 'entertainment'), isTrue);
      expect(categories.any((c) => c.id == 'sports'), isTrue);
      expect(categories.any((c) => c.id == 'movies'), isTrue);
    });

    test('QualityOption includes Auto, 1080p, 720p, 480p, 360p, and 240p', () {
      final options = QualityOption.defaultOptions;

      expect(options.any((o) => o.id == 'auto'), isTrue);
      expect(options.any((o) => o.id == '1080p' && o.targetHeight == 1080), isTrue);
      expect(options.any((o) => o.id == '720p' && o.targetHeight == 720), isTrue);
      expect(options.any((o) => o.id == '480p' && o.targetHeight == 480), isTrue);
      expect(options.any((o) => o.id == '360p' && o.targetHeight == 360), isTrue);
      expect(options.any((o) => o.id == '240p' && o.targetHeight == 240), isTrue);
    });
  });
}
