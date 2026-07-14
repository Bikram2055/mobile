/// App-wide configuration.
class AppConfig {
  AppConfig._();

  /// Base URL of the email backend (the `server/` project), e.g.
  /// `https://expense-tracker-email.onrender.com` — no trailing slash.
  ///
  /// Set it either by editing [_defaultEmailApiBaseUrl] below, or at build time
  /// with `--dart-define=EMAIL_API_BASE_URL=https://...` (which takes priority).
  /// While empty, the app runs fine but email features are disabled.
  static const String _defaultEmailApiBaseUrl = 'https://mobile-indol-omega.vercel.app';

  static const String emailApiBaseUrl = String.fromEnvironment(
    'EMAIL_API_BASE_URL',
    defaultValue: _defaultEmailApiBaseUrl,
  );

  static bool get hasEmailApi => emailApiBaseUrl.isNotEmpty;
}
