import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _api = ApiService();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.post(
        '${ApiConfig.authBase}/api/forgot-password',
        data: {'email': _emailController.text.trim()},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _emailSent = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to send reset email. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView(theme) : _buildFormView(theme),
        ),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.mark_email_read,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'If an account exists with that email, we\'ve sent password reset instructions.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Check your spam folder if you don\'t see it.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }

  Widget _buildFormView(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.lock_reset,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Forgot Password?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                       color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => _requestReset(),
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          FilledButton(
            onPressed: _isLoading ? null : _requestReset,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Reset Link', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),

          // Back to login
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}
