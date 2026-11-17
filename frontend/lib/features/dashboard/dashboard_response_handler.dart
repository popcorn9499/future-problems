class DashboardResponseHandler {
  static String handleLoadError(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 429:
        return 'Too many requests. Please try again in a moment.';
      case 500:
        return 'It\'s not you, it\'s us. Please try again later.';
      default:
        return 'Unable to load your rides. Please try again later.';
    }
  }
}