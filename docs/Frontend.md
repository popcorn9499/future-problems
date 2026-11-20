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
   cd frontend
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

   alternatively, something like the following, where the port is defined as an allowed origin in application.properties:

   ```bash
   flutter run -d edge --web-port=64636
   ```

  Note: Currently, the frontend has been tested to run properly on web only

For local development, run the backend on port 8080 and keep Flutter on port
3000 as shown above; the backend allows this browser origin. Authentication uses
an HTTP-only session cookie, not a bearer token. Configure the backend database
and SMTP credentials before registering. If verification email delivery fails,
the account remains saved; log in to retry sending a code. Unverified users go
to verification, and verified users go to the home screen. On startup, including
reloads and new tabs, the app checks the existing session which restores the user without another login, or brings the user to the login screen.

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

Handles user registration, login, logout, account deletion, and authentication-related interactions with the backend.

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
- Allows users to log out of their account.
- Clears the user's authenticated session upon logout.

#### Account Management
- Allows users to delete their accounts.
- Supports submitting account deletion requests.
- Handles account deletion responses and errors.
- Provides appropriate feedback to users following an account deletion attempt.

### User Profile

Handles displaying and editing the authenticated user's profile information.

#### View Profile
- Retrieves the current user's profile from the backend.
- Displays available profile information.

#### Edit Profile
- Allows users to update their first name, last name, age, pronouns, and description.
- Validates profile input before submitting changes.
- Sends updates to the backend using the profile API.
- Submits only fields that have changed.
- Handles API errors and displays appropriate feedback.

#### Profile Customization
- Allows users to customize their profile avatar color.

### Ride Requests and Ride Offers

Allows users to create and submit ride requests and ride offers through the application.

#### Create Ride Request
- Allows users to request a ride from a specified location to their destination, such as their residence to campus.
- Collects the required ride details.
- Supports submitting ride requests through the backend API.

#### Create Ride Offer
- Allows users to offer rides to other users, such as offering to drop passengers off at home.
- Collects the required ride offer details.
- Supports submitting ride offers through the backend API.

### Messaging

Provides a messaging interface for users to communicate with one another regarding rides and agreements.

- Displays conversations and messages between users.
- Supports viewing messages exchanged between the authenticated user and another user.
- Integrates with the messaging interface and backend messaging functionality.
- Supports test data for displaying messages during development.
- Displays actual conversations when connected to the appropriate backend data.

### Dashboard

Provides an overview of the user's ride listings and ride agreements.

#### My Listings
- Displays ride requests and ride offers created by the authenticated user.
- Allows users to view their previously posted listings.
- Displays relevant listing information.

#### My Agreements
- Displays rides that the user has agreed to participate in.
- Shows relevant ride details and information about the listing creator.
- Displays passenger information associated with the ride where applicable.
- Provides details about the ride request or ride offer, including the creator and other relevant participants.

### Application UI

- Provides a centralized application interface and navigation structure.
- Supports navigation between the application's main features.
- Provides a consistent user experience across application pages.
