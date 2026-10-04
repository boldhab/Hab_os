// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation: directly navigates the browser window.
void navigateToUrl(String url) {
  html.window.location.href = url;
}
