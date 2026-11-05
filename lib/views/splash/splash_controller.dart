import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final RxBool isReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  Future<void> initializeApp() async {
    final startTime = DateTime.now();

    if (_authRepo.isAuthenticated) {
      // Background session token refresh
      _authRepo.autoRefreshSession();
    }

    // Ensure the perimeter shimmer runs for at least ~1600ms so the loading beam is experienced
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 1600) {
      await Future.delayed(Duration(milliseconds: 1600 - elapsed));
    }

    isReady.value = true;
  }

  void onStarShineCompleted() {
    if (_authRepo.isAuthenticated) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      // Login is mandatory to access channels and watch
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}

