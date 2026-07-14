import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

/// Two-step forgot-password flow:
///  1. Enter email → a 6-digit OTP is emailed by the Cloud Function.
///  2. Enter the OTP + a new password → the password is reset.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { requestEmail, verifyOtp }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  _Step _step = _Step.requestEmail;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp(AuthController controller) async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final sent = await controller.requestPasswordOtp(_emailController.text.trim());
    if (!mounted) {
      return;
    }
    if (sent) {
      setState(() => _step = _Step.verifyOtp);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We emailed you a 6-digit reset code.')),
      );
    }
  }

  Future<void> _resetPassword(AuthController controller) async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final ok = await controller.resetPasswordWithOtp(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You can sign in now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Consumer<AuthController>(
              builder: (context, controller, _) {
                final isLoading = controller.isProcessing;
                final error = controller.errorMessage;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        _step == _Step.requestEmail
                            ? Icons.lock_reset_rounded
                            : Icons.mark_email_read_rounded,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _step == _Step.requestEmail
                            ? 'Forgot your password?'
                            : 'Enter the code',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _step == _Step.requestEmail
                            ? 'Enter your account email and we\'ll send you a 6-digit code.'
                            : 'We sent a 6-digit code to ${_emailController.text.trim()}. It expires in 10 minutes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_step == _Step.requestEmail)
                        _buildEmailStep(theme, controller, isLoading)
                      else
                        _buildResetStep(theme, controller, isLoading),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          error,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(ThemeData theme, AuthController controller, bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : () => _requestOtp(controller),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send code'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(ThemeData theme, AuthController controller, bool isLoading) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _otpController,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '6-digit code',
              hintText: '123456',
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().length != 6) {
                return 'Enter the 6-digit code';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            enabled: !isLoading,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter a new password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            enabled: !isLoading,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : () => _resetPassword(controller),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reset password'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : () => _requestOtp(controller),
            child: const Text('Resend code'),
          ),
        ],
      ),
    );
  }
}
