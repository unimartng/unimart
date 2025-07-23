# 🗄️ Supabase Setup Guide for Unimart

This guide will walk you through setting up Supabase for the Unimart campus marketplace app.

## 📋 Prerequisites

- Supabase account (free tier works fine)
- Basic understanding of SQL
- Access to Supabase dashboard

## 🚀 Step-by-Step Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - **Name**: `unimart`
   - **Database Password**: Generate a strong password
   - **Region**: Choose closest to your users
6. Click "Create new project"
7. Wait for the project to be created (2-3 minutes)

### Step 2: Get Your API Keys

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (e.g., `https://your-project.supabase.co`)
   - **Anon public key** (starts with `eyJ...`)

3. Update your `lib/main.dart` file:
```dart
await Supabase.initialize(
  url: 'YOUR_PROJECT_URL',
  anonKey: 'YOUR_ANON_KEY',
);
```

### Step 3: Set Up Database Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy and paste the entire content from `supabase_setup.sql`
4. Click "Run" to execute the script
5. Verify all tables are created in **Table Editor**

### Step 4: Configure Authentication

1. Go to **Authentication** → **Settings**
2. Configure the following:

#### Email Auth
- ✅ Enable "Enable email confirmations"
- ✅ Enable "Enable email change confirmations"
- ✅ Enable "Enable secure email change"

#### Google OAuth
1. Go to **Authentication** → **Providers**
2. Click on **Google**
3. Enable Google provider
4. Add your Google OAuth credentials:
   - **Client ID**: From Google Cloud Console
   - **Client Secret**: From Google Cloud Console
5. Add authorized redirect URLs:
   - `https://your-project.supabase.co/auth/v1/callback`
   - `io.supabase.unimart://login-callback/`

### Step 5: Set Up Storage Buckets

1. Go to **Storage** in your Supabase dashboard
2. Create the following buckets:

#### Images Bucket (for product photos)
- **Name**: `images`
- **Public bucket**: ✅ Yes
- **File size limit**: 10MB
- **Allowed MIME types**: `image/*`

#### Avatars Bucket (for profile pictures)
- **Name**: `avatars`
- **Public bucket**: ✅ Yes
- **File size limit**: 5MB
- **Allowed MIME types**: `image/*`

### Step 6: Configure Row Level Security (RLS)

The SQL script already sets up RLS policies, but verify they're working:

1. Go to **Authentication** → **Policies**
2. Check that all tables have RLS enabled
3. Verify policies are created for each table

### Step 7: Set Up Real-time Subscriptions

1. Go to **Database** → **Replication**
2. Enable real-time for the following tables:
   - ✅ `messages`
   - ✅ `chats`
   - ✅ `notifications`
   - ✅ `products`

### Step 8: Configure Email Templates

1. Go to **Authentication** → **Email Templates**
2. Customize the following templates:
   - **Confirm signup**
   - **Magic Link**
   - **Change email address**
   - **Reset password**

Example template for "Confirm signup":
```html
<h2>Welcome to Unimart!</h2>
<p>Hi {{ .Email }},</p>
<p>Welcome to your campus marketplace! Please confirm your email address by clicking the link below:</p>
<a href="{{ .ConfirmationURL }}">Confirm Email</a>
<p>Best regards,<br>The Unimart Team</p>
```

### Step 9: Test the Setup

1. **Test Authentication**:
   - Try signing up with email
   - Test Google OAuth (if configured)
   - Verify email confirmation works

2. **Test Database**:
   - Go to **Table Editor**
   - Try inserting a test user
   - Verify RLS policies work

3. **Test Storage**:
   - Try uploading an image to the `images` bucket
   - Verify public access works

## 🔧 Advanced Configuration

### Custom Functions

The setup script includes several PostgreSQL functions:
- `update_user_rating()`: Updates user ratings when reviews are added
- `update_chat_last_message()`: Updates chat timestamps
- `create_message_notification()`: Creates notifications for new messages

### Indexes for Performance

The script creates indexes on frequently queried columns:
- User campus and email
- Product category, campus, price
- Message timestamps
- Chat participants

### Triggers

Automatic triggers are set up for:
- Updating `updated_at` timestamps
- Updating user ratings
- Creating notifications

## 🛠️ Troubleshooting

### Common Issues

1. **RLS Policy Errors**
   - Make sure you're authenticated
   - Check that policies match your user ID
   - Verify table relationships

2. **Storage Upload Failures**
   - Check bucket permissions
   - Verify file size limits
   - Check MIME type restrictions

3. **Real-time Not Working**
   - Enable real-time for specific tables
   - Check subscription setup in Flutter code
   - Verify network connectivity

4. **Authentication Issues**
   - Check redirect URLs
   - Verify email templates
   - Test with different providers

### Debug Commands

```sql
-- Check if user exists
SELECT * FROM auth.users WHERE email = 'test@example.com';

-- Check user profile
SELECT * FROM public.users WHERE id = 'user-uuid';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Check storage buckets
SELECT * FROM storage.buckets;
```

## 📊 Monitoring

### Database Monitoring
1. Go to **Database** → **Logs**
2. Monitor query performance
3. Check for slow queries

### Authentication Monitoring
1. Go to **Authentication** → **Users**
2. Monitor sign-ups and logins
3. Check for failed attempts

### Storage Monitoring
1. Go to **Storage** → **Buckets**
2. Monitor file uploads
3. Check storage usage

## 🔒 Security Best Practices

1. **Never expose service role key** in client code
2. **Use RLS policies** for all data access
3. **Validate input** on both client and server
4. **Monitor logs** regularly
5. **Keep dependencies updated**

## 📱 Next Steps

After setting up Supabase:

1. **Test the Flutter app** with real data
2. **Implement remaining features**:
   - Product detail screens
   - Chat functionality
   - Profile management
3. **Add monitoring** and analytics
4. **Set up backups** and disaster recovery
5. **Scale** as your user base grows

## 🆘 Support

If you encounter issues:

1. Check the [Supabase documentation](https://supabase.com/docs)
2. Visit the [Supabase community](https://github.com/supabase/supabase/discussions)
3. Check the [Flutter Supabase package](https://pub.dev/packages/supabase_flutter)

---

**Your Unimart app is now ready to connect to Supabase! 🎉** 