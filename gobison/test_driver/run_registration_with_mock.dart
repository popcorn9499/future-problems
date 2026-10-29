import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final target = args.isEmpty
      ? 'integration_test/auth_registration_response_test.dart'
      : args.first;

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

  final responseCodes = <String, int>{
    'duplicate@myumanitoba.ca': 409,
    'servererror@myumanitoba.ca': 500,
  };

  server.listen((request) async {
    final response = request.response;
    final origin = request.headers.value('Origin');

    if (origin != null) {
      response.headers.set('Access-Control-Allow-Origin', origin);
      response.headers.set('Access-Control-Allow-Credentials', 'true');
      response.headers.set('Vary', 'Origin');
    }

    response.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    response.headers.set(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization',
    );
    response.headers.contentType = ContentType.json;

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/api/v1/auth/login') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (data['email'] == 'integrationtest@myumanitoba.ca' &&
            data['password'] == 'TestPass123') {
          response.cookies.add(
            Cookie('JSESSIONID', 'integration-test-session')
              ..httpOnly = true
              ..path = '/',
          );

          response.statusCode = HttpStatus.ok;
          response.write(
            jsonEncode({
              'user': {
                'userId': 'integration-user',
                'firstName': 'Test',
                'lastName': 'User',
                'email': 'integrationtest@myumanitoba.ca',
                'verified': false,
              },
            }),
          );
        } else {
          response.statusCode = HttpStatus.unauthorized;
          response.write(jsonEncode({'message': 'Invalid credentials'}));
        }
      } catch (_) {
        response.statusCode = HttpStatus.badRequest;
        response.write(jsonEncode({'message': 'Invalid request'}));
      }
    } else if (request.method == 'POST' &&
        request.uri.path == '/api/v1/auth/register') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        response.statusCode =
            responseCodes[data['email']] ?? HttpStatus.badRequest;
        response.write(jsonEncode({'message': 'Mock registration response'}));
      } catch (_) {
        response.statusCode = HttpStatus.badRequest;
        response.write(jsonEncode({'message': 'Invalid request'}));
      }
    } else if (request.method == 'POST' &&
        request.uri.path == '/api/v1/auth/verify-email') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final code = data['code'];

        final hasSessionCookie = request.cookies.any(
          (cookie) =>
              cookie.name == 'JSESSIONID' &&
              cookie.value == 'integration-test-session',
        );

        if (!hasSessionCookie) {
          response.statusCode = HttpStatus.unauthorized;
          response.write(jsonEncode({'message': 'Invalid authentication'}));
        } else if (code is! String || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
          response.statusCode = HttpStatus.badRequest;
          response.write(jsonEncode({'message': 'Invalid code format'}));
        } else if (code == '123456') {
          response.statusCode = HttpStatus.ok;
          response.write(jsonEncode({'universityVerified': true}));
        } else if (code == '900000') {
          response.statusCode = HttpStatus.internalServerError;
          response.write(jsonEncode({'message': 'Mock server error'}));
        } else {
          response.statusCode = HttpStatus.unprocessableEntity;
          response.write(
            jsonEncode({'message': 'Incorrect verification code'}),
          );
        }
      } catch (_) {
        response.statusCode = HttpStatus.badRequest;
        response.write(jsonEncode({'message': 'Invalid request'}));
      }
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write(jsonEncode({'message': 'Unknown endpoint'}));
    }

    await response.close();
  });

  stdout.writeln('Mock backend started at http://localhost:8080');

  try {
    final process = await Process.start(
      'flutter',
      [
        'drive',
        '--dart-define=API_BASE_URL=http://localhost:8080',
        '--driver=test_driver/integration_test.dart',
        '--target=$target',
        '-d',
        'web-server',
        '--browser-name=chrome',
        '--driver-port=4444',
        if (Platform.environment.containsKey('CHROME_EXECUTABLE'))
          "--chrome-binary=${Platform.environment['CHROME_EXECUTABLE']}",
        Platform.environment['CI'] == 'true' ? '--headless' : '--no-headless',
      ],
      runInShell: Platform.isWindows,
      mode: ProcessStartMode.inheritStdio,
    );

    exitCode = await process.exitCode;
  } finally {
    await server.close(force: true);
    stdout.writeln('Mock backend stopped.');
  }
}
