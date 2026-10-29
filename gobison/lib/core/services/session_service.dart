import '../../features/auth/auth_service.dart';
import '../models/user.dart';
import '../models/user_profile.dart';

class SessionData {
  final String? accessToken;
  final User user;
  final UserProfile profile;

  const SessionData({
    this.accessToken,
    required this.user,
    required this.profile,
  });
}

class SessionService {
  SessionService({AuthService? authService}) : _authService = authService ?? AuthService();

  final AuthService _authService;
  static String? _accessToken;
  static User? _currentUser;
  static UserProfile? _currentProfile;

  // Toggle this to false when switching to your real backend
  static const bool useMock = false;

  // In-memory cache for mock updates so changes reflect immediately
  static User? _mockUser;
  static UserProfile? _mockProfile;

  /// Loads the current session from mock state or the authenticated backend.
  Future<SessionData?> loadCurrentSession() async {
    if (useMock) {
      // Simulate slight network lag
      await Future.delayed(const Duration(milliseconds: 300));

      // Fallback to default mock data if nothing has been modified yet
      _mockUser ??= User(
        id: 'usr_123',
        firstName: 'Rebekah',
        lastName: 'Soneye',
        email: 'rebekah77777@myumanitoba.ca',
        verified: false,
      );

      _mockProfile ??= const UserProfile(
        userId: 'usr_123',
        firstName: 'Rebekah',
        lastName: 'Soneye',
        age: 22,
        gender: 'Female',
        description: 'My car is quite messy, but I\'ll get you to campus safe!',
      );

      return SessionData(
        accessToken: 'mock-jwt-token',
        user: _mockUser!,
        profile: _mockProfile!,
      );
    } else {
      final data = await _authService.currentUser();
      if (data == null) {
        await clearSession();
        return null;
      }
      final user = User(
        id: data['userId'] as String,
        firstName: data['firstName'] as String,
        lastName: data['lastName'] as String?,
        email: data['email'] as String,
        verified: data['verified'] as bool,
      );
      if (_currentUser?.id != user.id) _currentProfile = null;
      _currentUser = user;
      _currentProfile ??= UserProfile(
        userId: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
      );
      return SessionData(user: user, profile: _currentProfile!);
    }
  }

  static String? get accessToken => _accessToken;

  /// The cached session, without refreshing it from the backend.
  static SessionData? get cachedSession {
    final user = _currentUser;
    if (user == null) return null;
    return SessionData(
      accessToken: _accessToken,
      user: user,
      profile: _currentProfile ?? UserProfile(
        userId: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
      ),
    );
  }

  static Future<void> saveSession({
    String? accessToken,
    required User user,
    required UserProfile profile,
  }) async {
    _accessToken = accessToken;
    _currentUser = user;
    _currentProfile = profile;
  }

  static Future<void> saveAccessToken({required String accessToken}) async {
    _accessToken = accessToken;
  }

  static Future<void> saveUser({required User user}) async {
    _currentUser = user;
    _currentProfile = null;
  }

  static Future<void> clearSession() async {
    _accessToken = null;
    _currentUser = null;
    _currentProfile = null;
  }

  static Future<void> setVerification({required bool isVerified}) async {
    final tempUser = User(
      id: _currentUser!.id,
      firstName: _currentUser!.firstName,
      lastName: _currentUser!.lastName,
      email: _currentUser!.email,
      verified: isVerified,
    );
    SessionService.saveUser(user: tempUser);
  }
}


