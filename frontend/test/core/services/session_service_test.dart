import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/core/services/session_service.dart';
import 'package:gobison/features/auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(SessionService.clearSession);
  tearDown(SessionService.clearSession);

  const user = User(
    id: 'ada',
    firstName: 'Ada',
    email: 'ada@example.com',
    verified: true,
  );
  const profile = UserProfile(userId: 'ada', firstName: 'Ada');

  test('logout clears the cached session after server success', () async {
    var requestCount = 0;
    final service = SessionService(
      authService: AuthService(
        client: MockClient((request) async {
          requestCount++;
          expect(request.url.path, '/api/v1/auth/logout');
          return http.Response('', 204);
        }),
      ),
    );
    await SessionService.saveSession(
      user: user,
      profile: profile,
      accessToken: 'token',
    );

    await service.logout();

    expect(requestCount, 1);
    expect(SessionService.cachedSession, isNull);
    expect(SessionService.accessToken, isNull);
  });

  test(
    'logout preserves the cached session if the server request fails',
    () async {
      final service = SessionService(
        authService: AuthService(
          client: MockClient((_) async => http.Response('', 500)),
        ),
      );
      await SessionService.saveSession(
        user: user,
        profile: profile,
        accessToken: 'token',
      );

      await expectLater(service.logout(), throwsException);

      expect(SessionService.cachedSession!.user, user);
      expect(SessionService.accessToken, 'token');
    },
  );
}
