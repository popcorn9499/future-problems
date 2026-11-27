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

Handles user account and profile information, including:

- Email address
- First and last name
- Verified status
- Password hashing

#### Profile endpoints

Both profile endpoints require an authenticated user. The profile is selected from the current user's session; no user ID is passed in the URL or request body.

| Method | Path | Request | Successful response |
| --- | --- | --- | --- |
| GET | `/api/v1/users/me/profile` | — | `200 OK` with the current user's profile |
| PATCH | `/api/v1/users/me/profile` | JSON body with one or more profile fields | `200 OK` with the updated profile |

**GET profile** returns `userId`, `firstName`, `lastName`, `age`, `dateOfBirth`, `gender`, `description`, and `avatarColor`. `age` is calculated from `dateOfBirth` when one is set; otherwise, it may contain a legacy age value.

**PATCH profile** updates only the fields supplied in the JSON body. Supported fields are `firstName`, `lastName`, `dateOfBirth`, `age` (legacy), `pronouns`, `description`, and `avatarColor`. `dateOfBirth` uses `YYYY-MM-DD`; send `null` to clear it. For example:

```json
{
  "firstName": "Logan",
  "dateOfBirth": "2001-05-12",
  "pronouns": "she/her",
  "avatarColor": "#8F00FF"
}
```

The response contains the same profile fields as GET. The API currently returns the stored `pronouns` value under the response field name `gender`. Date of birth is returned only by the authenticated user's own profile endpoint; clients should display the calculated age rather than the full date.

Omitted fields remain unchanged. Supplied string fields must not be blank. `dateOfBirth` must indicate an age of at least 15 years. The legacy `age` field cannot be explicitly set to `null`.

| Status | Meaning |
| --- | --- |
| `400 Bad Request` | A supplied string field is blank, the date of birth indicates an age under 15, or legacy `age` is explicitly `null` |
| `401 Unauthorized` | Authentication is missing or the authenticated user cannot be found |

### Auth

Handles email verification as well as registering the user

Passwords are hashed using Spring Security's password encoder.

## Live Chat

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

### Ride management

The dashboard uses the following endpoints under `/api/v1/rides`.
Send the session cookie of the verified user who posted the ride.
Use the UUID of a single leg for `{id}`, including for round trips.

| Method | Path | Successful response |
| --- | --- | --- |
| GET | `/requests/{id}` | Details of the selected request leg |
| GET | `/offers/{id}` | Details of the selected offer leg, including seats and driver preference |
| PATCH | `/requests/{id}` | Updated one-way request |
| PATCH | `/requests/{id}/round-trip` | Array containing the updated arrival and departure legs |
| PATCH | `/offers/{id}` | Updated offer. A round trip includes `arrivalId` and `departureId` |
| DELETE | `/requests/{id}` or `/offers/{id}` | `204 No Content` |

For PATCH, send the full edit form as JSON. Include `city`, `streetAddress`,
a nonempty `daysOfWeek` list (for example, `["MONDAY"]`), and the times in
`HH:mm` format. A one-way ride takes its direction's time. A round trip takes
both `arrivalTime` and `departureTime`, with departure later than arrival.
The optional `description` can be cleared. Offers also require an integer
`passengerNum` from 1 to 9 and a boolean `askingForDrivers`.
New schedules use Monday through Friday. An edit can keep or remove weekend
days already saved on a leg. Each leg needs at least one day.

Cancelled rides and rides with another participant return `409` on edit.
An invalid address returns `422 INVALID_ADDRESS`. A temporary geocoding
failure returns `503 GEOCODING_UNAVAILABLE`.

When another participant has joined, DELETE returns `409` with
`{"code":"CONFIRMATION_REQUIRED"}`. After the owner confirms, repeat DELETE
with `?confirmParticipants=true`. Cancellation sets the status to `CANCELLED`
on all legs and preserves the ride and membership records.
