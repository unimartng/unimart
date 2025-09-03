import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_model.dart';
import 'supabase_service.dart';
import '../utils/error_handler.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = true; // Start with true for initial load
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Remove duplicate loading state - use only _isLoading
  bool get loading => _isLoading;

  // Constructor to initialize auth state
  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    print('🔄 AuthProvider: Initializing auth state');
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        print('👤 AuthProvider: Found existing user session');
        _currentUser = await SupabaseService.instance.getUserProfile(user.id);
      } else {
        print('❌ AuthProvider: No existing user session');
        _currentUser = null;
      }
    } catch (e) {
      print('🚨 AuthProvider: Error initializing auth: $e');
      setError(e.toString());
      _currentUser = null;
    } finally {
      _isLoading = false; // CRITICAL: Always set to false
      print(
        '✅ AuthProvider: Auth initialization complete, loading: $_isLoading',
      );
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    print('🔄 AuthProvider: Setting loading to $loading');
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    print('🚨 AuthProvider: Setting error: $error');
    _error = error;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      print('🧹 AuthProvider: Clearing error');
      _error = null;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String campus,
    required BuildContext context,
  }) async {
    print('📝 AuthProvider: Starting sign up');

    try {
      final response = await SupabaseService.instance.signUp(
        email: email,
        password: password,
        name: name,
        campus: campus,
      );

      if (response.user != null) {
        print('✅ AuthProvider: Sign up successful');
        _currentUser = await SupabaseService.instance.getUserProfile(
          response.user!.id,
        );
        if (context.mounted) {
          context.go('/');
        }
        notifyListeners();
      }
    } catch (e) {
      print('🚨 AuthProvider: Sign up error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    print('🔐 AuthProvider: Starting sign in');

    try {
      final resp = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );
      if (resp.user != null) {
        print('✅ AuthProvider: Sign in successful');
        _currentUser = await SupabaseService.instance.getUserProfile(
          resp.user!.id,
        );
        if (context.mounted) {
          context.go('/');
        }
        notifyListeners();
      } else {
        setError('Login failed: No user returned.');
      }
    } catch (e) {
      print('🚨 AuthProvider: Sign in error: $e');
      final errorMessage = _getAuthErrorMessage(e);
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    print('🔍 AuthProvider: Starting Google sign in');

    try {
      await SupabaseService.instance.signInWithGoogle();
      // After Google sign in, you might need to reload user data
      await loadCurrentUser();
    } catch (e) {
      print('🚨 AuthProvider: Google sign in error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut(BuildContext context) async {
    print('🚪 AuthProvider: Starting sign out');

    try {
      await SupabaseService.instance.signOut();
      _currentUser = null;
      print('✅ AuthProvider: Sign out successful');
      notifyListeners();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      print('🚨 AuthProvider: Sign out error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadCurrentUser() async {
    print('🔄 AuthProvider: Loading current user');

    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        print('👤 AuthProvider: Found current user');
        _currentUser = await SupabaseService.instance.getUserProfile(user.id);
        notifyListeners();
      } else {
        print('❌ AuthProvider: No current user found');
        _currentUser = null;
      }
    } catch (e) {
      print('🚨 AuthProvider: Load user error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    print('📝 AuthProvider: Updating profile');

    try {
      if (_currentUser != null) {
        await SupabaseService.instance.updateUserProfile(
          _currentUser!.id,
          updates,
        );
        _currentUser = await SupabaseService.instance.getUserProfile(
          _currentUser!.id,
        );
        print('✅ AuthProvider: Profile updated');
        notifyListeners();
      }
    } catch (e) {
      print('🚨 AuthProvider: Update profile error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  String? getCurrentUserEmail() {
    final session = SupabaseService.instance.client.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  /// Send password reset email
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    print('🔄 AuthProvider: Starting password reset');
    setLoading(true);
    clearError();

    try {
      await SupabaseService.instance.resetPassword(email);
      print('✅ AuthProvider: Password reset email sent');
      if (context.mounted) {
        ErrorHandler.showSuccess(
          context,
          'Password reset email sent! Please check your inbox.',
        );
      }
    } catch (e) {
      print('🚨 AuthProvider: Password reset error: $e');
      final errorMessage = _getAuthErrorMessage(e);
      setError(errorMessage);
      if (context.mounted) {
        ErrorHandler.showError(context, e, title: 'Password Reset Error');
      }
    } finally {
      setLoading(false);
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    print('🔄 AuthProvider: Starting password change');
    setLoading(true);
    clearError();

    try {
      await SupabaseService.instance.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      print('✅ AuthProvider: Password changed successfully');
      if (context.mounted) {
        ErrorHandler.showSuccess(
          context,
          'Password changed successfully!',
        );
      }
    } catch (e) {
      print('🚨 AuthProvider: Password change error: $e');
      final errorMessage = _getAuthErrorMessage(e);
      setError(errorMessage);
      if (context.mounted) {
        ErrorHandler.showError(context, e, title: 'Password Change Error');
      }
    } finally {
      setLoading(false);
    }
  }

  /// Delete user account
  Future<void> deleteAccount({
    required String password,
    required BuildContext context,
  }) async {
    print('🔄 AuthProvider: Starting account deletion');
    setLoading(true);
    clearError();

    try {
      await SupabaseService.instance.deleteUserAccount(password: password);
      print('✅ AuthProvider: Account deleted successfully');
      _currentUser = null;
      notifyListeners();
      
      if (context.mounted) {
        ErrorHandler.showSuccess(
          context,
          'Account deleted successfully. We\'re sorry to see you go!',
        );
        context.go('/login');
      }
    } catch (e) {
      print('🚨 AuthProvider: Account deletion error: $e');
      final errorMessage = _getAuthErrorMessage(e);
      setError(errorMessage);
      if (context.mounted) {
        ErrorHandler.showError(context, e, title: 'Account Deletion Error');
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> refreshCurrentUser() async {
    print('🔄 AuthProvider: Refreshing current user');

    try {
      final userId = currentUser?.id;
      if (userId != null) {
        final updatedUser = await SupabaseService.instance.getUserProfile(
          userId,
        );
        if (updatedUser != null) {
          _currentUser = updatedUser;
          print('✅ AuthProvider: User refreshed');
          notifyListeners();
        }
      }
    } catch (e) {
      print('🚨 AuthProvider: Refresh user error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Convert auth errors to user-friendly messages
  String _getAuthErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid email or password')) {
      return 'Invalid email or password. Please check your credentials.';
    }

    if (errorString.contains('email already in use')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    }

    if (errorString.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (errorString.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }

    return 'Authentication failed. Please try again.';
  }
}
