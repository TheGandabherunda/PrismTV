import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/constants/app_colors.dart';
import 'core/storage/hive_service.dart';
import 'data/providers/jio_live_source.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/channel_repository.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Smart TV Fullscreen / Leanback flags
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Local Hive Persistence
  await HiveService.init();

  // Dependency Injection (GetX)
  final jioSource = JioLiveSource();
  Get.put<JioLiveSource>(jioSource, permanent: true);
  Get.put<AuthRepository>(AuthRepository(jioSource), permanent: true);
  Get.put<ChannelRepository>(ChannelRepository(jioSource), permanent: true);

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
      theme: ThemeData.dark().copyWith(
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
