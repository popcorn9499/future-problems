# Backend Documentation

## Installation Instructions

Requirements

- Java 21+
- Postgres

Setup

- Setup local.properties use [local.properties.example](../backend/local.properties.example) as a template
- run 'java -jar backend.jar'

### Local.properties Configuration

`SUPABASE_DB_URL` should be the url to the postgres database.
`SUPABASE_DB_USERNAME` should be the postgres user that can access the database.
`SUPABASE_DB_PASSWORD` should be the postgres password.
`MAIL_PASSWORD` should be the password for the mail account

## Testing

run tests via `./mvnw clean test` or `.\mvnw clean test` depending on if you run the superior Linux or Windows(cough cough more like Windblows)

## Postmap
Has the draft of our api docs [https://moreaboutrebekah-4859954.docs.buildwithfern.com/gobison-api](https://moreaboutrebekah-4859954.docs.buildwithfern.com/gobison-api)

## Core Features

### User

handles all the database information regarding the User.
This includes

- Email address
- First and Last name
- Verified status
- Password Hashing

### Auth

Handles email verification as well as registering the user

the hashed password is hashed using spring frameworks crypto password encoder function.

# Live Chat

The Live Chat API supports creating conversations, listing a user's conversations, retrieving and sending messages, and marking incoming messages as read. All endpoints require an authenticated user. User email addresses are used as participant IDs.

| Method | Path | Request | Successful response |
| --- | --- | --- | --- |
| POST | `/api/v1/conversation` | JSON body: `{"participantId":"user@example.com"}` | `201 Created` with `conversationId`, `participants`, and `createdAt` |
| GET | `/api/v1/conversations` | — | `200 OK` with a `conversations` array |
| GET | `/api/v1/conversations/{conversationId}/messages` | Optional query parameters: `limit` (default `50`) and `before` (message ID cursor) | `200 OK` with `conversationId`, `messages`, and `pagination` |
| POST | `/api/v1/conversations/{conversationId}/messages` | JSON body: `{"content":"Hello"}` | `201 Created` with the created message |
| PATCH | `/api/v1/conversations/{conversationId}/read` | — | `200 OK` with `conversationId`, `markedAsRead`, `messageIds`, and `readAt` |

### Request and response details

- **Create a conversation** (`POST /api/v1/conversation`): `participantId` must be a non-empty email address. The response includes the conversation ID, participant email addresses, and creation timestamp.
- **List conversations** (`GET /api/v1/conversations`): each item in `conversations` includes `conversationId`, `participant` (`userId`, `firstName`, `lastName`, `avatarColor`), `lastMessage`, `lastMessageAt`, and `unreadCount`.
- **Get messages** (`GET /api/v1/conversations/{conversationId}/messages`): `limit` must be at least `1`. The optional `before` cursor is a message ID; when provided, the response contains messages older than that message. Each message includes `messageId`, `senderId`, `content`, `sentAt`, and `readAt`. Pagination contains the requested `limit`, `hasMore`, and `nextCursor`; use `nextCursor` as the `before` value to request an older page.
- **Send a message** (`POST /api/v1/conversations/{conversationId}/messages`): `content` must not be blank. The response includes `messageId`, `conversationId`, `senderId`, `content`, `sentAt`, and `readAt`.
- **Mark messages as read** (`PATCH /api/v1/conversations/{conversationId}/read`): the conversation ID in the path identifies which conversation to update. The authenticated user determines whose incoming unread messages are marked. The response includes the number and IDs of messages updated, along with `readAt`.

Timestamps are serialized as ISO 8601 UTC timestamps (for example, `2026-11-10T14:30:00Z`). The serialized value may include fractional seconds.

All request bodies use JSON. The `conversationId` in message and read routes is a path parameter, not a request-body field.

### Error responses

| Status | Meaning |
| --- | --- |
| `400 Bad Request` | Invalid participant email, blank message content, or a message limit below `1` |
| `401 Unauthorized` | Authentication is missing or the authenticated user cannot be found |
| `403 Forbidden` | The authenticated user is not a participant in the conversation |
| `404 Not Found` | The conversation, message cursor, or requested participant does not exist |
| `409 Conflict` | A conversation already exists between the participants |
| `500 Internal Server Error` | A persistence or transaction failure occurred |

Mapped application errors return an empty response body.
