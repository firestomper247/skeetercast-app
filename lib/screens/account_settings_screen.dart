import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile data
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;
  String? _success;

  // Edit mode
  bool _isEditing = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  // Password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Delete account
  final _deletePasswordController = TextEditingController();
  final _deleteConfirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    _deleteConfirmController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profile = await authService.getProfile();

      if (profile != null) {
        setState(() {
          _profile = profile;
          _usernameController.text = profile['username'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _error = null;
      _success = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.updateProfile(
        username: _usernameController.text,
        email: _emailController.text,
      );

      if (result['success'] == true) {
        setState(() {
          _success = result['email_changed'] == true
              ? 'Profile updated. Please verify your new email.'
              : 'Profile updated successfully';
          _isEditing = false;
        });
        _loadProfile();
      } else {
        setState(() => _error = result['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      setState(() => _error = 'Error updating profile: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _error = null;
      _success = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (result['success'] == true) {
        setState(() {
          _success = 'Password changed successfully';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        setState(() => _error = result['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      setState(() => _error = 'Error changing password: $e');
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _error = null;
      _success = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.resendVerification();

      if (result['success'] == true) {
        setState(() => _success = 'Verification email sent! Check your inbox.');
      } else {
        setState(() => _error = result['message'] ?? 'Failed to send verification email');
      }
    } catch (e) {
      setState(() => _error = 'Error sending verification email: $e');
    }
  }

  Future<void> _deleteAccount() async {
    if (_deleteConfirmController.text != 'DELETE') {
      setState(() => _error = 'Please type DELETE to confirm');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you ABSOLUTELY SURE you want to delete your account? '
          'This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.deleteAccount(
        password: _deletePasswordController.text,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(() => _error = result['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      setState(() => _error = 'Error deleting account: $e');
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.warning), text: 'Danger'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(theme),
                _buildSecurityTab(theme),
                _buildDangerTab(theme),
              ],
            ),
    );
  }

  Widget _buildProfileTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Messages
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          if (_success != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                ],
              ),
            ),

          // Email verification banner
          if (_profile != null && _profile!['email_verified'] != true)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Email not verified')),
                  TextButton(
                    onPressed: _resendVerification,
                    child: const Text('Resend'),
                  ),
                ],
              ),
            ),

          // Account info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile?['username'] ?? 'User',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _profile?['email'] ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isEditing ? Icons.close : Icons.edit),
                        onPressed: () => setState(() => _isEditing = !_isEditing),
                      ),
                    ],
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _updateProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Account details
          Text(
            'Account Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildInfoRow(
                  theme,
                  'Account Type',
                  _formatTier(_profile?['tier']),
                  icon: Icons.star,
                  valueColor: _isPremium(_profile?['tier']) ? Colors.amber : null,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  theme,
                  'Member Since',
                  _formatDate(_profile?['created_at']),
                  icon: Icons.calendar_today,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  theme,
                  'Account Age',
                  '${_profile?['account_age_days'] ?? 0} days',
                  icon: Icons.access_time,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  theme,
                  'Email Verified',
                  _profile?['email_verified'] == true ? 'Yes' : 'No',
                  icon: Icons.verified,
                  valueColor: _profile?['email_verified'] == true ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Messages
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          if (_success != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                ],
              ),
            ),

          Text(
            'Change Password',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isChangingPassword ? null : _changePassword,
                      child: _isChangingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Password Requirements',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirement(theme, 'At least 8 characters'),
          _buildRequirement(theme, 'Mix of letters and numbers recommended'),
        ],
      ),
    );
  }

  Widget _buildDangerTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Danger Zone',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Once you delete your account, there is no going back. '
                  'All your data, saved cities, fishing spots, and subscription will be permanently deleted.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),

          Text(
            'Delete Account',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _deletePasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Your Password',
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'Enter your password to confirm',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deleteConfirmController,
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE to confirm',
                      prefixIcon: Icon(Icons.warning),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _isDeleting ? null : _deleteAccount,
                      child: _isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Delete My Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value, {IconData? icon, Color? valueColor}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: theme.colorScheme.primary) : null,
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      ),
    );
  }

  Widget _buildRequirement(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatTier(String? tier) {
    if (tier == null) return 'Free';
    switch (tier.toLowerCase()) {
      case 'plus':
        return 'Plus';
      case 'premium':
        return 'Premium';
      case 'pro':
        return 'Pro';
      case 'admin':
        return 'Admin';
      default:
        return 'Free';
    }
  }

  bool _isPremium(String? tier) {
    if (tier == null) return false;
    return ['plus', 'premium', 'pro', 'admin'].contains(tier.toLowerCase());
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
