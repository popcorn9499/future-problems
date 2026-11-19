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

This module of our backend server allows for creating conversations via `/api/v1/conversation`
As well as retreiving conversations, all messages, sending and marking messages read via `/api/v1/conversations`.
Given our users do not have  a id associated with them we opted to use email as the id as email shouldn't change given the structure of our application.

| Method | Path | Request | Successful response |
| --- | --- | --- | --- |
| POST | `/api/v1/conversation` | JSON body: `{"participantId":"user@example.com"}` | `201 Created` with `conversationId`, `participants`, and `createdAt` |
| GET | `/api/v1/conversations` | — | `200 OK` with a `conversations` array of conversation summaries |
| GET | `/api/v1/conversations/{conversationId}/messages` | Optional query parameters: `limit` (default `50`) and `before` (message ID cursor) | `200 OK` with `conversationId`, `messages`, and pagination info (`limit`, `hasMore`, `nextCursor`) |
| POST | `/api/v1/conversations/{conversationId}/messages` | JSON body: `{"content":"Hello"}` | `201 Created` with the created message |
| PATCH | `/api/v1/conversations/{conversationId}/read` | — | `200 OK` with `conversationId`, `markedAsRead`, `messageIds`, and `readAt` |

All requests with a body use JSON as it is simple and everything has a parser for JSON. 

For reading conversations which is a PATCH method we take the convo id as part of the url 
are really take nothing else as that combined with our authentication is all we really need to know who's messages to mark read.

As for creating a conversation we use POST we just ask for the other participant id and log it in our backend. 
Returning JSON to tell us the convo id participants and what time it was made at. This is sent in UTC time `yyyy-MM-dd'T'HH:mm:ss'Z'`

GET conversations gets any conversations we don't need any request body as it is self-explanatory. However for the return body we use JSON and format it with a list of the conversations. the participant and the avatar color they chose.  

As for making a conversation we use POST with a url parameter conversationId in the path to allow us
to keep track of what chat this is for and to send the message JSON with just the content inside.

For getting the messages we use pagination with the GET method allowing us to get the last x messages as well as within the response JSON telling us 
if we can keep reading as well as the next message id to start reading from next time.


