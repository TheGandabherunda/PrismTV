import 'package:flutter_test/flutter_test.dart';
import 'package:prism_tv/data/models/auth_session.dart';
import 'package:prism_tv/data/models/category_model.dart';
import 'package:prism_tv/data/models/channel_model.dart';
import 'package:prism_tv/data/models/epg_program_model.dart';

void main() {
  group('PrismTV Core Models & Architecture Tests', () {
    test('ChannelModel properly parses JSON and categorizes', () {
      final json = {
        'channel_id': 105,
        'channel_name': 'Colors Kannada HD',
        'logoUrl': 'colors_kannada.png',
        'channelCategoryId': 1,
        'channelLanguageId': 13,
        'isHD': true,
      };

      final channel = ChannelModel.fromJson(json);

      expect(channel.channelId, 105);
      expect(channel.channelName, 'Colors Kannada HD');
      expect(channel.isHd, true);
      expect(channel.categoryName, 'Entertainment');
      expect(channel.languageName, 'Kannada');
      expect(channel.fullLogoUrl, contains('colors_kannada.png'));
    });

    test('AuthSession demo session creates valid non-expired credentials', () {
      final demo = AuthSession.demo();

      expect(demo.isDemo, true);
      expect(demo.isValid, true);
      expect(demo.ssoToken.isNotEmpty, true);
      expect(demo.uniqueId, 'prism_demo_user');
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

    test('Default category list contains Kannada, Entertainment, Sports, and Movies', () {
      final categories = CategoryModel.defaultCategories;

      expect(categories.any((c) => c.id == 'kannada'), isTrue);
      expect(categories.any((c) => c.id == 'entertainment'), isTrue);
      expect(categories.any((c) => c.id == 'sports'), isTrue);
      expect(categories.any((c) => c.id == 'movies'), isTrue);
    });
  });
}
