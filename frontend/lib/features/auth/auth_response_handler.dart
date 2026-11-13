class AuthResponseHandler {
  static String handleLoginError(int statusCode) {
    switch (statusCode) {
      case 503:
        return 'Unable to send verification email. Please log in again to retry.';
      case 400:
        return 'Please enter a valid email and password.';
      case 401:
        return 'Invalid email or password.';
      case 429:
        return 'Too many login attempts. Please try again later.';
      case 500:
        return 'It\'s not you, it\'s us. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }

  static String handleRegistrationError(int statusCode) {
    switch (statusCode) {
      case 503:
        return 'Your account was saved, but the verification email failed. Please log in to retry.';
      case 400:
        return 'Please check your information and try again.';
      case 409:
        return 'An account with this email already exists.';
      case 429:
        return 'Too many registration attempts. Please try again later.';
      case 500:
        return 'It\'s not you, it\'s us. Please try again later.';
      default:
        return 'Unable to register. Please try again later.';
    }
  }

  static String handleVerificationError(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Verification code is missing or malformed.';
      case 401:
        return 'User is not authenticated or the authentication token is invalid.';
      case 409:
        return 'The user\'s university email has already been verified.';
      case 422:
        return 'The verification code is incorrect.';
      case 500:
      default:
        return 'Unexpected server failure.';
    }
  }
}
