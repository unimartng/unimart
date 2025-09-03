import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorHandler {
  static const String _defaultErrorMessage =
      'Something went wrong. Please try again.';
  static const String _networkErrorMessage =
      'Network error. Please check your connection.';
  static const String _authErrorMessage =
      'Authentication failed. Please log in again.';
  static const String _permissionErrorMessage =
      'Permission denied. Please check app settings.';
  static const String _validationErrorMessage =
      'Please check your input and try again.';

  /// Handle and display errors consistently across the app
  static void showError(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    final message = _getUserFriendlyMessage(error);

    if (showSnackBar) {
      _showErrorSnackBar(context, message, onRetry);
    } else {
      _showErrorDialog(context, title ?? 'Error', message, onRetry);
    }

    // Log error for debugging
    _logError(error);
  }

  /// Show error as a snackbar
  static void _showErrorSnackBar(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  ) {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show error as a dialog
  static void _showErrorDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback? onRetry,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Convert technical errors to user-friendly messages
  static String _getUserFriendlyMessage(dynamic error) {
    if (error == null) return _defaultErrorMessage;

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return _networkErrorMessage;
    }

    // Authentication errors
    if (errorString.contains('auth') ||
        errorString.contains('login') ||
        errorString.contains('unauthorized') ||
        errorString.contains('token')) {
      return _authErrorMessage;
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('access')) {
      return _permissionErrorMessage;
    }

    // Validation errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return _validationErrorMessage;
    }

    // Specific error messages
    if (errorString.contains('email already in use')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    }

    if (errorString.contains('invalid email or password')) {
      return 'Invalid email or password. Please check your credentials.';
    }

    if (errorString.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (errorString.contains('file too large')) {
      return 'File is too large. Please choose a smaller image.';
    }

    if (errorString.contains('not found')) {
      return 'The requested item was not found.';
    }

    // Default fallback
    return _defaultErrorMessage;
  }

  /// Log errors for debugging
  static void _logError(dynamic error) {
    print('🚨 Error: $error');
    if (error is Exception) {
      print('🚨 Exception: ${error.toString()}');
    }
  }

  /// Handle async operations with proper error handling
  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    required BuildContext context,
    String? errorTitle,
    VoidCallback? onRetry,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (error) {
      if (context.mounted) {
        showError(context, error, title: errorTitle, onRetry: onRetry);
      }
      return defaultValue;
    }
  }

  /// Validate form fields with user-friendly messages
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a price';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Please enter a valid price';
    }
    return null;
  }

  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Show info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }
}
