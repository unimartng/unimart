import 'package:flutter/material.dart';

class LoadingManager {
  /// Safely set loading state with mounted check
  static void setLoading(
    BuildContext context,
    bool loading,
    VoidCallback setState,
  ) {
    if (context.mounted) {
      setState();
    }
  }

  /// Show loading overlay
  static void showLoadingOverlay(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading overlay
  static void hideLoadingOverlay(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Execute async operation with loading state
  static Future<T?> withLoading<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    T? defaultValue,
  }) async {
    if (!context.mounted) return defaultValue;

    showLoadingOverlay(context, message: loadingMessage);

    try {
      final result = await operation();
      if (context.mounted) {
        hideLoadingOverlay(context);
      }
      return result;
    } catch (error) {
      if (context.mounted) {
        hideLoadingOverlay(context);
      }
      rethrow;
    }
  }

  /// Execute async operation with loading state and error handling
  static Future<T?> withLoadingAndError<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? errorTitle,
    VoidCallback? onRetry,
    T? defaultValue,
  }) async {
    if (!context.mounted) return defaultValue;

    showLoadingOverlay(context, message: loadingMessage);

    try {
      final result = await operation();
      if (context.mounted) {
        hideLoadingOverlay(context);
      }
      return result;
    } catch (error) {
      if (context.mounted) {
        hideLoadingOverlay(context);
        // Import and use ErrorHandler here
        // ErrorHandler.showError(context, error, title: errorTitle, onRetry: onRetry);
      }
      return defaultValue;
    }
  }
}

/// Mixin for managing loading states in StatefulWidgets
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  Future<T?> executeWithLoading<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    T? defaultValue,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      return result;
    } catch (error) {
      if (mounted) {
        // Handle error here
        print('Error in executeWithLoading: $error');
      }
      return defaultValue;
    } finally {
      setLoading(false);
    }
  }
}

/// Widget that shows loading state
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingWidget({super.key, this.message, this.size = 40.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget that shows error state with retry option
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget that shows empty state
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
