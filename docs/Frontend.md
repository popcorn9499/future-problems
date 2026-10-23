# Flutter Frontend Documentation

## Installation Instructions

### Requirements

- Flutter SDK 3.47.7
- Dart SDK (included with Flutter)
- A running GoBison backend for API-dependent features

### Setup

1. Install the Flutter SDK by following the [official Flutter installation guide](https://docs.flutter.dev/get-started/install).

2. Verify that Flutter is installed and configured correctly:
   ```bash
   flutter doctor
   ```

3. Navigate to the frontend project directory:
   ```bash
   cd gobison
   ```
4. Install the project dependencies:
   ```bash
   flutter pub get
   ```
5. Ensure the backend is running. See backend.md

6. Run the application:
   ```bash
   flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080
   ```

  Note: Currently, the frontend has been tested to run properly on web only

For local development, run the backend on port 8080 and keep Flutter on port
3000 as shown above; the backend allows this browser origin. Authentication uses
an HTTP-only session cookie, not a bearer token. Configure the backend database
and SMTP credentials before registering. If verification email delivery fails,
the account remains saved; log in to retry sending a code. Unverified users go
to verification, and verified users go to the home screen. Refreshing the page
requires logging in again because frontend session restoration is not implemented.

## Configuration

The frontend communicates with the GoBison backend through HTTP API requests.

The API base URL is configured in `ApiConfig`. It determines the backend address used by the frontend for authentication and profile-related requests.

Ensure the configured URL matches the environment in which the application is running.

- **Local development:** The frontend should communicate with the locally running backend.
- **Production:** The deployed frontend should communicate with the production backend.

The frontend requires a running and accessible backend for features that depend on API requests.

## Testing

Run the Flutter test suite from the frontend project directory:

```bash
flutter test
```

To run a specific test file:

```bash
flutter test test/path/to/your_test.dart
```

## Project Structure

The frontend is organized into separate components to keep UI code, application logic, and API communication manageable.

- **Pages:** Application screens and user interface.
- **Controllers:** Manage application state, coordinate workflows, and handle loading states and errors.
- **Services:** Handle communication with the backend API.
- **Models:** Represent application data received from or sent to the backend.
- **Validators:** Validate user input against predefined rules.
- **Core:** Contains shared configuration, theme definitions, colors, and reusable widgets.
- **Tests:** Contain automated Flutter tests.


## Core Features

### Authentication

Handles user registration, login, and authentication-related interactions with the backend.

#### Registration

- Allows users to create an account.
- Collects the required registration information.
- Validates user input before submitting registration requests.
- Integrates with the backend registration API.
- Supports university email address requirements.

#### Login

- Allows registered users to log in.
- Validates login form input.
- Sends authentication requests to the backend.
- Handles authentication errors and displays appropriate feedback.

#### Session Management

- Checks for an existing authenticated session.
- Determines whether the user should be directed to the home page or login page.
- Supports session-based navigation.

### User Profile

Handles displaying and editing the authenticated user's profile information.

#### View Profile

- Retrieves the current user's profile from the backend.
- Displays available profile information.

#### Edit Profile

- Allows users to update their first name, last name, age, gender, and description.
- Validates profile input before submitting changes.
- Sends updates to the backend using the profile API.
- Submits only fields that have changed.
- Handles API errors and displays appropriate feedback.

### Application UI

- Provides a centralized application theme and color configuration.
- Uses reusable UI components, including the GoBison logo.
- Provides login, registration, and profile-related screens.
