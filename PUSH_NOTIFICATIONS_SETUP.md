# Push Notifications Setup Guide for Unimart

This guide will help you set up push notifications for your Unimart Flutter app using Firebase Cloud Messaging (FCM) and Supabase.

## 📋 Prerequisites

- Flutter project with Supabase integration
- Firebase project
- Supabase project with Edge Functions enabled
- Android Studio / Xcode for platform-specific configuration

## 🔥 Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `unimart-notifications`
4. Enable Google Analytics (optional)
5. Create project

### 2. Add Android App

1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.unimart` (or your actual package name)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### 3. Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.example.unimart` (or your actual bundle ID)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### 4. Get Server Key

1. In Firebase Console, go to Project Settings → Cloud Messaging
2. Copy the "Server key" (you'll need this for Supabase functions)

## 🗄️ Supabase Setup

### 1. Database Setup

Run the SQL script in your Supabase SQL editor:

```sql
-- Run the contents of notification_setup.sql
```

### 2. Environment Variables

Add these environment variables to your Supabase project:

1. Go to Supabase Dashboard → Settings → Edge Functions
2. Add environment variables:
   - `FCM_SERVER_KEY`: Your Firebase server key from step 4 above

### 3. Deploy Edge Functions

Deploy the notification functions to Supabase:

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy functions
supabase functions deploy send-notification
supabase functions deploy send-bulk-notification
supabase functions deploy send-campus-notification
```

## 📱 Flutter Configuration

### 1. Update Firebase Configuration

Update `firebase_options.dart` with your actual Firebase configuration:

```dart
// Replace the placeholder values with your actual Firebase config
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

### 2. Android Configuration

#### Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

#### Update `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### Update `android/app/build.gradle` (add at the top):

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. iOS Configuration

#### Update `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

#### Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 🚀 Usage

### 1. Initialize Notifications

The notification system is automatically initialized when the app starts. The `NotificationProvider` handles all the setup.

### 2. Send Notifications

#### From your Flutter app:

```dart
// Send notification to specific user
await SupabaseService.instance.sendNotificationToUser(
  userId: 'user-id',
  title: 'New Message',
  body: 'You have a new message from John',
  data: {
    'type': 'new_message',
    'chat_id': 'chat-123',
  },
);

// Send notification to multiple users
await SupabaseService.instance.sendNotificationToUsers(
  userIds: ['user1', 'user2', 'user3'],
  title: 'Campus Update',
  body: 'Important announcement for all students',
);

// Send notification to campus
await SupabaseService.instance.sendNotificationToCampus(
  campus: 'MIT',
  title: 'Campus Event',
  body: 'Join us for the tech fair tomorrow!',
);
```

#### From Supabase Edge Functions:

```typescript
// Call the function directly
const { data, error } = await supabase.functions.invoke('send-notification', {
  body: {
    user_id: 'user-id',
    title: 'Notification Title',
    body: 'Notification body text',
    data: { type: 'custom_type' }
  }
});
```

### 3. Handle Notifications

The app automatically handles different notification types:

- **new_message**: Navigate to chat screen
- **product_update**: Navigate to product detail
- **new_favorite**: Navigate to favorites
- **campus_announcement**: Show campus updates

### 4. User Settings

Users can manage their notification preferences in the Settings screen:

- Push Notifications (master toggle)
- Message Notifications
- Product Notifications
- Favorite Notifications
- Marketing Notifications

## 🧪 Testing

### 1. Test Notifications

1. Open the app and go to Settings → Push notification
2. Click "Send Test Notification"
3. Check if you receive the notification

### 2. Test Different Scenarios

- App in foreground
- App in background
- App completely closed
- Different notification types

### 3. Debug Issues

Check the console logs for:
- FCM token generation
- Permission status
- Notification delivery status

## 🔧 Troubleshooting

### Common Issues

1. **Notifications not received**:
   - Check FCM token is generated
   - Verify Firebase configuration
   - Check notification permissions

2. **Android notifications not showing**:
   - Verify `google-services.json` is in correct location
   - Check Android manifest permissions
   - Ensure notification channel is created

3. **iOS notifications not working**:
   - Verify `GoogleService-Info.plist` is in correct location
   - Check iOS capabilities in Xcode
   - Ensure APNs certificates are configured

4. **Supabase functions failing**:
   - Check environment variables
   - Verify FCM server key
   - Check function logs in Supabase dashboard

### Debug Commands

```bash
# Check FCM token
flutter logs | grep "FCM Token"

# Check notification permissions
flutter logs | grep "Permission"

# Check Supabase function logs
supabase functions logs send-notification
```

## 📊 Monitoring

### Firebase Console
- Monitor notification delivery rates
- Check for failed notifications
- View analytics

### Supabase Dashboard
- Monitor Edge Function executions
- Check database for stored notifications
- View function logs

## 🔒 Security Considerations

1. **FCM Server Key**: Keep it secure in Supabase environment variables
2. **User Tokens**: Stored securely with RLS policies
3. **Notification Data**: Validate all input data
4. **Rate Limiting**: Implement rate limiting for notification sending

## 📈 Performance Optimization

1. **Batch Notifications**: Use bulk notification function for multiple users
2. **Topic Subscriptions**: Use FCM topics for campus-wide notifications
3. **Database Indexing**: Ensure proper indexes on notification tables
4. **Caching**: Cache FCM tokens to reduce database queries

## 🎯 Next Steps

1. **Rich Notifications**: Add images and action buttons
2. **Scheduled Notifications**: Implement notification scheduling
3. **Notification Analytics**: Track notification engagement
4. **A/B Testing**: Test different notification formats
5. **Localization**: Support multiple languages

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Firebase and Supabase documentation
3. Check the app logs for error messages
4. Verify all configuration steps are completed

---

**🎉 Congratulations! Your push notification system is now ready to use!**
