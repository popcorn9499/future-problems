# Backend Documentation

## Installation Instructions.


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


# Testing

run tests via `./mvnw clean test` or `.\mvnw clean test` depending on if you run the superior Linux or Windows(cough cough more like Windblows)


# Core Features
## User
handles all the database information regarding the User. 
This includes
- Email address
- First and Last name
- Verified status
- Password Hashing

## Auth
Handles email verification as well as registering the user

the hashed password is hashed using spring frameworks crypto password encoder function.


