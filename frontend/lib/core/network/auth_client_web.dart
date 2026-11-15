import 'package:http/browser_client.dart';

BrowserClient createAuthClient() => BrowserClient()..withCredentials = true;
