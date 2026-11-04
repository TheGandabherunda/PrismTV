import 'package:get/get.dart';
import '../views/auth/auth_controller.dart';
import '../views/auth/auth_view.dart';
import '../views/home/home_controller.dart';
import '../views/home/home_view.dart';
import '../views/player/player_controller.dart';
import '../views/player/player_view.dart';
import '../views/splash/splash_controller.dart';
import '../views/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put<SplashController>(SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: BindingsBuilder(() {
        Get.put<AuthController>(AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.put<HomeController>(HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const PlayerView(),
      binding: BindingsBuilder(() {
        Get.put<PlayerController>(PlayerController());
      }),
    ),
  ];
}

