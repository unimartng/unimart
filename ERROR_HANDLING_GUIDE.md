# Error Handling & UX Best Practices Guide

## Overview
This guide documents the comprehensive error handling and user experience improvements implemented in the Unimart app.

## Key Improvements Made

### 1. Centralized Error Handling (`lib/utils/error_handler.dart`)

#### Features:
- **User-friendly error messages**: Converts technical errors to understandable messages
- **Consistent error display**: Standardized snackbars and dialogs
- **Error categorization**: Network, auth, permission, validation errors
- **Retry functionality**: Built-in retry mechanisms
- **Proper logging**: Debug information for developers

#### Usage:
```dart
// Show error as snackbar
ErrorHandler.showError(context, error);

// Show error as dialog with retry
ErrorHandler.showError(
  context, 
  error, 
  title: 'Error Title',
  onRetry: () => retryOperation(),
  showSnackBar: false,
);

// Show success message
ErrorHandler.showSuccess(context, 'Operation completed successfully');

// Show info message
ErrorHandler.showInfo(context, 'Please check your connection');
```

### 2. Loading State Management (`lib/utils/loading_manager.dart`)

#### Features:
- **Safe loading states**: Proper mounted checks
- **Loading overlays**: Full-screen loading indicators
- **Loading mixin**: Reusable loading state management
- **Error widgets**: Standardized error and empty states

#### Usage:
```dart
// Using the mixin
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with LoadingStateMixin {
  Future<void> loadData() async {
    await executeWithLoading(() async {
      // Your async operation
      return await someAsyncOperation();
    });
  }
}

// Using loading overlay
await LoadingManager.withLoading(
  context,
  () => someAsyncOperation(),
  loadingMessage: 'Loading data...',
);
```

### 3. Enhanced Supabase Service Error Handling

#### Improvements:
- **Proper exception throwing**: Instead of returning null/empty lists
- **Specific error messages**: Different errors for different scenarios
- **Error logging**: Debug information for troubleshooting
- **User-friendly error conversion**: Technical errors converted to user messages

#### Before:
```dart
Future<ProductModel?> getProductById(String productId) async {
  try {
    // ... operation
    return product;
  } catch (e) {
    return null; // Silent failure
  }
}
```

#### After:
```dart
Future<ProductModel?> getProductById(String productId) async {
  try {
    // ... operation
    return product;
  } catch (e) {
    print('Error getting product by ID: $e');
    if (e.toString().contains('No rows found')) {
      throw Exception('Product not found');
    }
    throw Exception('Failed to load product: ${e.toString()}');
  }
}
```

### 4. Form Validation Improvements

#### Centralized validation functions:
```dart
// Email validation
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

// Password validation
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

// Price validation
String? validatePrice(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a price';
  }
  final price = double.tryParse(value);
  if (price == null || price <= 0) {
    return 'Please enter a valid price';
  }
  return null;
}
```

## Best Practices Implemented

### 1. Mounted Checks
Always check if the widget is still mounted before calling setState:

```dart
if (mounted) {
  setState(() {
    // Update state
  });
}
```

### 2. Proper Error Boundaries
Wrap async operations in try-catch blocks:

```dart
Future<void> loadData() async {
  setState(() => _isLoading = true);
  try {
    final data = await someAsyncOperation();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }
}
```

### 3. Loading States
Always show loading indicators for async operations:

```dart
// In UI
if (_isLoading) {
  return const LoadingWidget(message: 'Loading...');
}
```

### 4. Empty States
Provide meaningful empty states:

```dart
if (_data.isEmpty) {
  return EmptyStateWidget(
    message: 'No products found',
    icon: Icons.inbox_outlined,
    onAction: () => refreshData(),
    actionLabel: 'Refresh',
  );
}
```

### 5. Error States
Show retry options for errors:

```dart
if (_hasError) {
  return ErrorWidget(
    message: 'Failed to load data',
    onRetry: () => loadData(),
  );
}
```

## Error Categories Handled

### 1. Network Errors
- Connection timeouts
- Network unavailable
- Server errors

### 2. Authentication Errors
- Invalid credentials
- Token expiration
- Account not found

### 3. Permission Errors
- Location permission denied
- Camera permission denied
- Storage permission denied

### 4. Validation Errors
- Invalid email format
- Weak password
- Required fields missing

### 5. File Upload Errors
- File too large
- Invalid file type
- Upload timeout

## User Experience Improvements

### 1. Haptic Feedback
Provide tactile feedback for important actions:

```dart
HapticFeedback.lightImpact(); // For light actions
HapticFeedback.mediumImpact(); // For medium actions
HapticFeedback.heavyImpact(); // For heavy actions
```

### 2. Consistent Messaging
- Success messages: Green background with check icon
- Error messages: Red background with error icon
- Info messages: Blue background with info icon

### 3. Retry Mechanisms
Always provide retry options for failed operations:

```dart
ErrorHandler.showError(
  context,
  error,
  onRetry: () => retryOperation(),
);
```

### 4. Loading Indicators
- Show loading spinners for async operations
- Provide loading messages for context
- Disable buttons during loading

### 5. Form Validation
- Real-time validation feedback
- Clear error messages
- Visual indicators for validation state

## Testing Error Scenarios

### 1. Network Disconnection
Test app behavior when network is unavailable:
- Show appropriate error messages
- Provide retry options
- Cache data when possible

### 2. Invalid Input
Test form validation:
- Empty required fields
- Invalid email formats
- Weak passwords
- Invalid file types

### 3. Server Errors
Test server error handling:
- 404 errors
- 500 errors
- Timeout errors
- Rate limiting

### 4. Permission Denials
Test permission handling:
- Location permission denied
- Camera permission denied
- Storage permission denied

## Monitoring and Logging

### 1. Error Logging
All errors are logged for debugging:

```dart
print('🚨 Error: $error');
if (error is Exception) {
  print('🚨 Exception: ${error.toString()}');
}
```

### 2. Performance Monitoring
Track loading times and error rates:
- API response times
- Error frequency
- User interaction patterns

### 3. User Feedback
Collect user feedback on error messages:
- Error message clarity
- Retry success rates
- User satisfaction scores

## Future Improvements

### 1. Offline Support
- Implement offline caching
- Queue operations for when online
- Show offline indicators

### 2. Advanced Error Recovery
- Automatic retry with exponential backoff
- Smart error categorization
- Predictive error prevention

### 3. Accessibility
- Screen reader support for error messages
- Keyboard navigation for error dialogs
- High contrast error indicators

### 4. Analytics Integration
- Error tracking with analytics
- User behavior analysis
- Performance monitoring

## Conclusion

The implemented error handling system provides:
- **Better user experience** with clear, actionable error messages
- **Improved reliability** with proper error boundaries and retry mechanisms
- **Easier debugging** with comprehensive error logging
- **Consistent behavior** across the entire application
- **Maintainable code** with centralized error handling utilities

This foundation ensures the app is robust, user-friendly, and maintainable for future development.
