import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final RxDouble logoScale = 0.8.obs;
  final RxDouble logoOpacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _startAnimationAndNavigate();
  }

  Future<void> _startAnimationAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 100));
    logoScale.value = 1.0;
    logoOpacity.value = 1.0;

    await Future.delayed(const Duration(milliseconds: 1500));

    if (_authRepo.isAuthenticated) {
      // Background session token refresh
      _authRepo.autoRefreshSession();
      Get.offAllNamed(AppRoutes.home);
    } else {
      // If not logged in, go straight to home with demo/preview access
      Get.offAllNamed(AppRoutes.home);
    }
  }
}

