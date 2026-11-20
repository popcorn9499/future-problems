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

**GET profile** returns `userId`, `firstName`, `lastName`, `age`, `gender`, `description`, and `avatarColor`.

**PATCH profile** updates only the fields supplied in the JSON body. Supported fields are `firstName`, `lastName`, `age`, `pronouns`, `description`, and `avatarColor`. For example:

```json
{
  "firstName": "Logan",
  "pronouns": "she/her",
  "avatarColor": "#8F00FF"
}
```

The response contains the same profile fields as GET. The API currently returns the stored `pronouns` value under the response field name `gender`.

Omitted fields remain unchanged. Supplied string fields must not be blank, and `age` cannot be explicitly set to `null`.

| Status | Meaning |
| --- | --- |
| `400 Bad Request` | A supplied string field is blank, or `age` is explicitly `null` |
| `401 Unauthorized` | Authentication is missing or the authenticated user cannot be found |

### Auth

Handles email verification as well as registering the user

Passwords are hashed using Spring Security's password encoder.
