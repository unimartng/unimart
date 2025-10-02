# Backend Setup Guide for Authentication Features

This guide outlines the backend setup required for the new authentication features: **Forgot Password**, **Change Password**, and **Delete Account**.

## 🔐 Supabase Authentication Setup

### 1. Email Templates Configuration

#### Password Reset Email Template
1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Email Templates**
3. Select **Reset Password** template
4. Customize the email template:

```html
<h2>Reset Your UniMart Password</h2>
<p>Hello,</p>
<p>You requested to reset your password for your UniMart account.</p>
<p>Click the button below to reset your password:</p>
<a href="{{ .ConfirmationURL }}" style="background-color: #0F5A40; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
  Reset Password
</a>
<p>If you didn't request this, you can safely ignore this email.</p>
<p>This link will expire in 24 hours.</p>
<p>Best regards,<br>The UniMart Team</p>
```

### 2. Email Provider Configuration

#### SMTP Settings (Recommended)
1. Go to **Authentication** → **Email Templates**
2. Click **Configure SMTP**
3. Add your SMTP credentials:
   - **Host**: Your SMTP server (e.g., `smtp.gmail.com`)
   - **Port**: 587 (TLS) or 465 (SSL)
   - **Username**: Your email address
   - **Password**: Your app password
   - **Sender Name**: UniMart
   - **Sender Email**: noreply@yourdomain.com

#### Alternative: Use Supabase's Built-in Email Service
- Supabase provides email service out of the box
- No additional configuration needed
- Limited to 100 emails/day on free tier

### 3. URL Configuration

#### Site URL Settings
1. Go to **Authentication** → **URL Configuration**
2. Set the following URLs:
   - **Site URL**: `https://your-app-domain.com`
   - **Redirect URLs**: 
     - `https://your-app-domain.com/auth/callback`
     - `https://ubwqruzgcgqfzgcpzaqd.supabase.co/auth/v1/callback`
     - `your-app-scheme://auth/callback` (for mobile apps)

## 🗄️ Database Setup

### 1. Row Level Security (RLS) Policies

Ensure your tables have proper RLS policies for user data deletion:

#### Users Table
```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy for users to manage their own data
CREATE POLICY "Users can manage their own data" ON users
  FOR ALL USING (auth.uid() = id);

-- Policy for user deletion
CREATE POLICY "Users can delete their own account" ON users
  FOR DELETE USING (auth.uid() = id);
```

#### Products Table
```sql
-- Policy for product deletion when user deletes account
CREATE POLICY "Delete products when user deletes account" ON products
  FOR DELETE USING (auth.uid() = user_id);
```

#### Reviews Table
```sql
-- Policy for review deletion when user deletes account
CREATE POLICY "Delete reviews when user deletes account" ON reviews
  FOR DELETE USING (auth.uid() = reviewer_id OR auth.uid() = reviewed_user_id);
```

#### Favorites Table
```sql
-- Policy for favorite deletion when user deletes account
CREATE POLICY "Delete favorites when user deletes account" ON favorites
  FOR DELETE USING (auth.uid() = user_id);
```

#### Messages Table
```sql
-- Policy for message deletion when user deletes account
CREATE POLICY "Delete messages when user deletes account" ON messages
  FOR DELETE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
```

#### Chats Table
```sql
-- Policy for chat deletion when user deletes account
CREATE POLICY "Delete chats when user deletes account" ON chats
  FOR DELETE USING (auth.uid() = user1_id OR auth.uid() = user2_id);
```

### 2. Database Functions for Account Deletion

Create a PostgreSQL function to handle complete account deletion:

```sql
-- Function to delete user account and all associated data
CREATE OR REPLACE FUNCTION delete_user_account(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete user's products
  DELETE FROM products WHERE user_id = user_id;
  
  -- Delete user's reviews (both as reviewer and reviewed)
  DELETE FROM reviews WHERE reviewer_id = user_id OR reviewed_user_id = user_id;
  
  -- Delete user's favorites
  DELETE FROM favorites WHERE user_id = user_id;
  
  -- Delete user's messages (both sent and received)
  DELETE FROM messages WHERE sender_id = user_id OR receiver_id = user_id;
  
  -- Delete user's chats
  DELETE FROM chats WHERE user1_id = user_id OR user2_id = user_id;
  
  -- Delete user profile
  DELETE FROM users WHERE id = user_id;
  
  -- Note: The auth.users table deletion requires admin privileges
  -- This will be handled by a separate admin process or webhook
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;
```

## 🔧 Backend Functions (Optional but Recommended)

### 1. Edge Functions for Account Deletion

Create a Supabase Edge Function for complete account deletion:

```typescript
// supabase/functions/delete-account/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id } = await req.json()

    // Verify the request is from an authenticated user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user || user.id !== user_id) {
      throw new Error('Unauthorized')
    }

    // Delete user data
    await supabaseClient.rpc('delete_user_account', { user_id })

    // Delete the auth user (requires service role)
    const { error: deleteError } = await supabaseClient.auth.admin.deleteUser(user_id)
    
    if (deleteError) {
      throw deleteError
    }

    return new Response(
      JSON.stringify({ message: 'Account deleted successfully' }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})
```

### 2. Deploy the Edge Function

```bash
# Navigate to your project directory
cd your-project

# Deploy the function
supabase functions deploy delete-account
```

## 🔒 Security Considerations

### 1. Password Requirements
- Minimum 6 characters (as implemented)
- Consider adding complexity requirements
- Implement password strength validation

### 2. Rate Limiting
- Implement rate limiting for password reset requests
- Limit failed login attempts
- Add CAPTCHA for multiple failed attempts

### 3. Session Management
- Implement proper session timeout
- Clear all sessions on password change
- Log security events

## 📧 Email Configuration Best Practices

### 1. Email Templates
- Use consistent branding
- Include clear call-to-action buttons
- Provide fallback text for email clients
- Test across different email clients

### 2. Email Delivery
- Use a reliable email service provider
- Monitor email delivery rates
- Set up email authentication (SPF, DKIM, DMARC)
- Implement email queue for high volume

## 🧪 Testing Checklist

### 1. Password Reset Flow
- [ ] User can request password reset
- [ ] Email is sent with reset link
- [ ] Reset link works correctly
- [ ] User can set new password
- [ ] Old password no longer works
- [ ] User is logged in after reset

### 2. Change Password Flow
- [ ] User can change password with current password
- [ ] Validation works correctly
- [ ] New password is saved
- [ ] User is notified of success
- [ ] Old password no longer works

### 3. Delete Account Flow
- [ ] User can initiate account deletion
- [ ] Confirmation dialogs work
- [ ] All user data is deleted
- [ ] User is logged out
- [ ] User cannot access protected routes

## 🚀 Deployment Checklist

### 1. Environment Variables
```bash
# Add to your .env file
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 2. Email Configuration
- [ ] SMTP settings configured
- [ ] Email templates customized
- [ ] Test emails sent successfully
- [ ] Email delivery monitored

### 3. Security Review
- [ ] RLS policies implemented
- [ ] Rate limiting configured
- [ ] Error handling implemented
- [ ] Logging enabled

## 📞 Support and Monitoring

### 1. Error Monitoring
- Set up error tracking (e.g., Sentry)
- Monitor authentication failures
- Track email delivery issues

### 2. User Support
- Provide clear error messages
- Create support documentation
- Set up support email/chat

### 3. Analytics
- Track authentication flows
- Monitor user engagement
- Analyze security events

## 🔄 Maintenance

### 1. Regular Updates
- Keep Supabase SDK updated
- Monitor security advisories
- Update email templates as needed

### 2. Backup Strategy
- Regular database backups
- Email template backups
- Configuration backups

This setup ensures a secure, reliable, and user-friendly authentication system for your UniMart application.
