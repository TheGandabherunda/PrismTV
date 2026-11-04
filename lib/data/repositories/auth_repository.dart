import '../../core/storage/hive_service.dart';
import '../models/auth_session.dart';
import '../providers/jio_live_source.dart';

class AuthRepository {
  final JioLiveSource _jioSource;

  AuthRepository(this._jioSource);

  AuthSession? getCurrentSession() {
    return HiveService.getSavedSession();
  }

  bool get isAuthenticated {
    final session = getCurrentSession();
    return session != null && session.isValid;
  }

  Future<bool> requestOtp(String phoneNumber) {
    return _jioSource.sendOtp(phoneNumber);
  }

  Future<AuthSession?> loginWithOtp(String phoneNumber, String otp) {
    return _jioSource.verifyOtp(phoneNumber, otp);
  }

  Future<void> loginAsDemo() async {
    final demoSession = AuthSession.demo();
    await HiveService.saveSession(demoSession);
  }

  Future<void> logout() async {
    await HiveService.clearSession();
  }

  Future<AuthSession?> autoRefreshSession() async {
    final session = getCurrentSession();
    if (session != null) {
      return _jioSource.refreshSession(session);
    }
    return null;
  }
}

