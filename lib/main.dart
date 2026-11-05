import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/constants/app_colors.dart';
import 'core/services/app_update_service.dart';
import 'core/storage/hive_service.dart';
import 'data/providers/jio_live_source.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/channel_repository.dart';
import 'views/player/player_controller.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Override Flutter error widget to prevent grey error boxes across web/release UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[FLUTTER_ERROR] ${details.exception}');
    return const SizedBox.shrink();
  };

  // Smart TV Fullscreen / Leanback flags
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Local Hive Persistence
  await HiveService.init();

  // Dependency Injection (GetX)
  final jioSource = JioLiveSource();
  Get.put<JioLiveSource>(jioSource, permanent: true);
  Get.put<AuthRepository>(AuthRepository(jioSource), permanent: true);
  Get.put<ChannelRepository>(ChannelRepository(jioSource), permanent: true);
  Get.put<PlayerController>(PlayerController(), permanent: true);
  Get.put<AppUpdateService>(AppUpdateService(), permanent: true);

  runApp(const PrismTvApp());
}

class PrismTvApp extends StatelessWidget {
  const PrismTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PrismTV',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.lightBackground,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.lightSurface,
        ),
        focusColor: AppColors.focusedBorder,
        hoverColor: AppColors.primaryGlow,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        focusColor: AppColors.focusedBorder,
        hoverColor: AppColors.focusedBackground,
      ),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
