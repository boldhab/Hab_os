/// Stub implementation for non-web platforms.
/// This file is never actually imported on web — the conditional import
/// in google_auth_launcher.dart selects google_auth_launcher_web.dart instead.
void navigateToUrl(String url) {
  throw UnsupportedError('navigateToUrl is only supported on web.');
}
