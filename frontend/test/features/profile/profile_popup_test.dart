import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/ride_agreement.dart';
import 'package:gobison/features/profile/presentation/profile_popup.dart';
import 'package:gobison/features/profile/profile_service.dart';
import 'package:gobison/features/messages/messaging_service.dart';
import 'package:gobison/features/messages/presentation/chat_page.dart';

void main() {
  const member = AgreementMember(
    id: 'ada@myumanitoba.ca',
    firstName: 'Ada',
    lastName: 'Lovelace',
  );

  Future<void> openPopup(
  WidgetTester tester,
  http.Client client, {
  Size size = const Size(1000, 800),
  String currentUserId = 'current-user@myumanitoba.ca',
  http.Client? messagingClient,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showProfilePopup(
                context,
                member: member,
                currentUserId: currentUserId,
                service: ProfileService(client: client),
                messagingService: MessagingService(
                  client: messagingClient ?? MockClient((_) async {
                    return http.Response('', 500);
                  }),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pump();
}

  testWidgets('shows the name and a spinner while loading', (tester) async {
    final completer = Completer<http.Response>();
    await openPopup(tester, MockClient((_) => completer.future));

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(http.Response('{"firstName":"Ada"}', 200));
    await tester.pumpAndSettle();
  });

  testWidgets('loads the profile by email and shows its details', (
    tester,
  ) async {
    late Uri requested;
    await openPopup(
      tester,
      MockClient((request) async {
        requested = request.url;
        return http.Response(
          '{"firstName":"Ada","lastName":"Lovelace","age":36,'
          '"pronouns":"she/her","description":"Likes maths",'
          '"avatarColor":"#E9DFD2"}',
          200,
        );
      }),
    );
    await tester.pumpAndSettle();

    expect(requested.path, endsWith('/users/ada%40myumanitoba.ca/profile'));
    expect(find.text('she/her'), findsOneWidget);
    expect(find.text('Age 36'), findsOneWidget);
    expect(find.text('Likes maths'), findsOneWidget);
  });

  testWidgets('says so when the user has no details', (tester) async {
    await openPopup(
      tester,
      MockClient((_) async => http.Response('{"firstName":"Ada"}', 200)),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining("hasn't added any profile details"),
      findsOneWidget,
    );
  });

  testWidgets('shows a retry button when loading fails, then recovers', (
    tester,
  ) async {
    var calls = 0;
    await openPopup(
      tester,
      MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('boom', 500)
            : http.Response('{"firstName":"Ada","pronouns":"she/her"}', 200);
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load this profile."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('she/her'), findsOneWidget);
  });

  testWidgets('a deleted or missing user shows no retry button', (
    tester,
  ) async {
    await openPopup(tester, MockClient((_) async => http.Response('', 404)));
    await tester.pumpAndSettle();

    expect(find.text('This profile is no longer available.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('Close dismisses the popup', (tester) async {
    await openPopup(
      tester,
      MockClient((_) async => http.Response('{"firstName":"Ada"}', 200)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Close'), findsNothing);
  });

  testWidgets('opens as a dialog on a wide screen', (tester) async {
    await openPopup(
      tester,
      MockClient((_) async => http.Response('{"firstName":"Ada"}', 200)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('opens as a bottom sheet on a phone-sized screen', (
    tester,
  ) async {
    await openPopup(
      tester,
      MockClient((_) async => http.Response('{"firstName":"Ada"}', 200)),
      size: const Size(400, 800),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('shows a message button when viewing another user', (
  tester,
) async {
    await openPopup(
      tester,
      MockClient(
        (_) async => http.Response('{"firstName":"Ada"}', 200),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('Message opens a chat with the selected user', (
  tester,
) async {
  final requests = <http.Request>[];

  final messagingClient = MockClient((request) async {
    requests.add(request);

    if (request.method == 'POST' &&
        request.url.path.endsWith('/api/v1/conversation')) {
      return http.Response(
        '{"conversationId":"conversation-123"}',
        201,
      );
    }

    if (request.method == 'GET' &&
        request.url.path.endsWith('/api/v1/conversations')) {
      return http.Response(
        jsonEncode({
          'conversations': [
            {
              'conversationId': 'conversation-123',
              'participant': {
                'userId': 'ada@myumanitoba.ca',
                'firstName': 'Ada',
                'lastName': 'Lovelace',
              },
              'lastMessage': '',
              'lastMessageAt': null,
              'unreadCount': 0,
            },
          ],
        }),
        200,
      );
    }

    if (request.url.path.endsWith('/messages')) {
      return http.Response('{"messages":[]}', 200);
    }

    if (request.method == 'PATCH') {
      return http.Response('{}', 200);
    }

    return http.Response('Not found', 404);
  });

  await openPopup(
    tester,
    MockClient(
      (_) async => http.Response('{"firstName":"Ada"}', 200),
    ),
    messagingClient: messagingClient,
  );

  await tester.pumpAndSettle();

  await tester.tap(find.text('Message'));
  await tester.pumpAndSettle();

  // Verify the conversation creation request.
  final createRequest = requests.firstWhere(
    (request) =>
        request.method == 'POST' &&
        request.url.path.endsWith('/api/v1/conversation'),
  );

  expect(
    jsonDecode(createRequest.body)['participantId'],
    'ada@myumanitoba.ca',
  );

  // Verify the conversation was retrieved from the inbox.
  expect(
    requests.any(
      (request) =>
          request.url.path.endsWith('/api/v1/conversations'),
    ),
    isTrue,
  );

  // verify navigation to the correct chat
  expect(find.byType(ChatPage), findsOneWidget);
  expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('does not show Message when viewing your own profile', (
  tester,
) async {
  await openPopup(
    tester,
    MockClient(
      (_) async => http.Response('{"firstName":"Ada"}', 200),
    ),
    currentUserId: 'ada@myumanitoba.ca',
  );

  await tester.pumpAndSettle();

  expect(find.text('Message'), findsNothing);
});

testWidgets('shows an error when messaging fails and allows retry', (
  tester,
) async {
  var calls = 0;

  final messagingClient = MockClient((request) async {
    if (request.method == 'POST') {
      calls++;

      if (calls == 1) {
        return http.Response('Server error', 500);
      }

      return http.Response(
        '{"conversationId":"conversation-123"}',
        201,
      );
    }

    if (request.url.path.endsWith('/api/v1/conversations')) {
      return http.Response(
        jsonEncode({
          'conversations': [
            {
              'conversationId': 'conversation-123',
              'participant': {
                'userId': 'ada@myumanitoba.ca',
                'firstName': 'Ada',
                'lastName': 'Lovelace',
              },
              'lastMessage': '',
              'lastMessageAt': null,
              'unreadCount': 0,
            },
          ],
        }),
        200,
      );
    }

    if (request.url.path.endsWith('/messages')) {
      return http.Response('{"messages":[]}', 200);
    }

    if (request.method == 'PATCH') {
      return http.Response('{}', 200);
    }

    return http.Response('Not found', 404);
  });

  await openPopup(
    tester,
    MockClient(
      (_) async => http.Response('{"firstName":"Ada"}', 200),
    ),
    messagingClient: messagingClient,
  );

  await tester.pumpAndSettle();

  await tester.tap(find.text('Message'));
  await tester.pumpAndSettle();

  expect(
    find.text('Could not open the chat. Try again.'),
    findsOneWidget,
  );

  // Retry opening the conversation.
  await tester.tap(find.text('Message'));
  await tester.pumpAndSettle();

  expect(calls, 2);
  expect(find.byType(ChatPage), findsOneWidget);
});
}