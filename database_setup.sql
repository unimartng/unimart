-- =====================================================
-- UniMart Database Setup for Authentication Features
-- =====================================================

-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- USERS TABLE POLICIES
-- =====================================================

-- Policy for users to read their own profile
CREATE POLICY "Users can read their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Policy for users to update their own profile
CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Policy for users to insert their own profile
CREATE POLICY "Users can insert their own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy for users to delete their own account
CREATE POLICY "Users can delete their own account" ON users
  FOR DELETE USING (auth.uid() = id);

-- Policy for users to read other users' profiles (for public info)
CREATE POLICY "Users can read other users' public profiles" ON users
  FOR SELECT USING (true);

-- =====================================================
-- PRODUCTS TABLE POLICIES
-- =====================================================

-- Policy for users to read all products
CREATE POLICY "Users can read all products" ON products
  FOR SELECT USING (true);

-- Policy for users to create their own products
CREATE POLICY "Users can create their own products" ON products
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for users to update their own products
CREATE POLICY "Users can update their own products" ON products
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy for users to delete their own products
CREATE POLICY "Users can delete their own products" ON products
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- REVIEWS TABLE POLICIES
-- =====================================================

-- Policy for users to read all reviews
CREATE POLICY "Users can read all reviews" ON reviews
  FOR SELECT USING (true);

-- Policy for users to create reviews
CREATE POLICY "Users can create reviews" ON reviews
  FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Policy for users to update their own reviews
CREATE POLICY "Users can update their own reviews" ON reviews
  FOR UPDATE USING (auth.uid() = reviewer_id);

-- Policy for users to delete their own reviews
CREATE POLICY "Users can delete their own reviews" ON reviews
  FOR DELETE USING (auth.uid() = reviewer_id);

-- Policy for deleting reviews when user deletes account (as reviewer)
CREATE POLICY "Delete reviews when user deletes account as reviewer" ON reviews
  FOR DELETE USING (auth.uid() = reviewer_id);

-- Policy for deleting reviews when user deletes account (as reviewed)
CREATE POLICY "Delete reviews when user deletes account as reviewed" ON reviews
  FOR DELETE USING (auth.uid() = reviewed_user_id);

-- =====================================================
-- FAVORITES TABLE POLICIES
-- =====================================================

-- Policy for users to read their own favorites
CREATE POLICY "Users can read their own favorites" ON favorites
  FOR SELECT USING (auth.uid() = user_id);

-- Policy for users to create their own favorites
CREATE POLICY "Users can create their own favorites" ON favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for users to delete their own favorites
CREATE POLICY "Users can delete their own favorites" ON favorites
  FOR DELETE USING (auth.uid() = user_id);

-- Policy for deleting favorites when user deletes account
CREATE POLICY "Delete favorites when user deletes account" ON favorites
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- MESSAGES TABLE POLICIES
-- =====================================================

-- Policy for users to read messages in their chats
CREATE POLICY "Users can read messages in their chats" ON messages
  FOR SELECT USING (
    auth.uid() = sender_id OR 
    auth.uid() = receiver_id
  );

-- Policy for users to create messages
CREATE POLICY "Users can create messages" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Policy for users to update their own messages
CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- Policy for users to delete their own messages
CREATE POLICY "Users can delete their own messages" ON messages
  FOR DELETE USING (auth.uid() = sender_id);

-- Policy for deleting messages when user deletes account (as sender)
CREATE POLICY "Delete messages when user deletes account as sender" ON messages
  FOR DELETE USING (auth.uid() = sender_id);

-- Policy for deleting messages when user deletes account (as receiver)
CREATE POLICY "Delete messages when user deletes account as receiver" ON messages
  FOR DELETE USING (auth.uid() = receiver_id);

-- =====================================================
-- CHATS TABLE POLICIES
-- =====================================================

-- Policy for users to read their own chats
CREATE POLICY "Users can read their own chats" ON chats
  FOR SELECT USING (
    auth.uid() = user1_id OR 
    auth.uid() = user2_id
  );

-- Policy for users to create chats
CREATE POLICY "Users can create chats" ON chats
  FOR INSERT WITH CHECK (
    auth.uid() = user1_id OR 
    auth.uid() = user2_id
  );

-- Policy for users to update their own chats
CREATE POLICY "Users can update their own chats" ON chats
  FOR UPDATE USING (
    auth.uid() = user1_id OR 
    auth.uid() = user2_id
  );

-- Policy for users to delete their own chats
CREATE POLICY "Users can delete their own chats" ON chats
  FOR DELETE USING (
    auth.uid() = user1_id OR 
    auth.uid() = user2_id
  );

-- Policy for deleting chats when user deletes account
CREATE POLICY "Delete chats when user deletes account" ON chats
  FOR DELETE USING (
    auth.uid() = user1_id OR 
    auth.uid() = user2_id
  );

-- =====================================================
-- DATABASE FUNCTIONS
-- =====================================================

-- Function to delete user account and all associated data
CREATE OR REPLACE FUNCTION delete_user_account(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete user's products
  DELETE FROM products WHERE user_id = delete_user_account.user_id;
  
  -- Delete user's reviews (both as reviewer and reviewed)
  DELETE FROM reviews WHERE reviewer_id = delete_user_account.user_id OR reviewed_user_id = delete_user_account.user_id;
  
  -- Delete user's favorites
  DELETE FROM favorites WHERE user_id = delete_user_account.user_id;
  
  -- Delete user's messages (both sent and received)
  DELETE FROM messages WHERE sender_id = delete_user_account.user_id OR receiver_id = delete_user_account.user_id;
  
  -- Delete user's chats
  DELETE FROM chats WHERE user1_id = delete_user_account.user_id OR user2_id = delete_user_account.user_id;
  
  -- Delete user profile
  DELETE FROM users WHERE id = delete_user_account.user_id;
  
  -- Note: The auth.users table deletion requires admin privileges
  -- This will be handled by a separate admin process or webhook
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;

-- Function to get user chats with details
CREATE OR REPLACE FUNCTION get_user_chats_with_details(p_user_id UUID)
RETURNS TABLE (
  chat_id TEXT,
  user1_id UUID,
  user2_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  last_message_text TEXT,
  last_message_created_at TIMESTAMPTZ,
  other_user_id UUID,
  other_user_name TEXT,
  other_user_photo_url TEXT,
  unread_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.chat_id,
    c.user1_id,
    c.user2_id,
    c.created_at,
    c.updated_at,
    lm.message_text as last_message_text,
    lm.created_at as last_message_created_at,
    CASE 
      WHEN c.user1_id = p_user_id THEN c.user2_id
      ELSE c.user1_id
    END as other_user_id,
    CASE 
      WHEN c.user1_id = p_user_id THEN u2.name
      ELSE u1.name
    END as other_user_name,
    CASE 
      WHEN c.user1_id = p_user_id THEN u2.photo_url
      ELSE u1.photo_url
    END as other_user_photo_url,
    COALESCE(unread.unread_count, 0) as unread_count
  FROM chats c
  LEFT JOIN users u1 ON c.user1_id = u1.id
  LEFT JOIN users u2 ON c.user2_id = u2.id
  LEFT JOIN LATERAL (
    SELECT message_text, created_at
    FROM messages m
    WHERE m.chat_id = c.chat_id
    ORDER BY created_at DESC
    LIMIT 1
  ) lm ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*) as unread_count
    FROM messages m
    WHERE m.chat_id = c.chat_id
    AND m.receiver_id = p_user_id
    AND m.is_read = false
  ) unread ON true
  WHERE c.user1_id = p_user_id OR c.user2_id = p_user_id
  ORDER BY lm.created_at DESC NULLS LAST;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_chats_with_details(UUID) TO authenticated;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(p_chat_id TEXT, p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE messages 
  SET is_read = true
  WHERE chat_id = p_chat_id 
  AND receiver_id = p_user_id 
  AND is_read = false;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION mark_messages_as_read(TEXT, UUID) TO authenticated;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users table
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for products table
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for chats table
CREATE TRIGGER update_chats_updated_at
  BEFORE UPDATE ON chats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- INDEXES FOR BETTER PERFORMANCE
-- =====================================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_campus ON users(campus);

-- Products table indexes
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_campus ON products(campus);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);
CREATE INDEX IF NOT EXISTS idx_products_is_sold ON products(is_sold);

-- Reviews table indexes
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewed_user_id ON reviews(reviewed_user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at);

-- Favorites table indexes
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_product_id ON favorites(product_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_product ON favorites(user_id, product_id);

-- Messages table indexes
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read);

-- Chats table indexes
CREATE INDEX IF NOT EXISTS idx_chats_user1_id ON chats(user1_id);
CREATE INDEX IF NOT EXISTS idx_chats_user2_id ON chats(user2_id);
CREATE INDEX IF NOT EXISTS idx_chats_updated_at ON chats(updated_at);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for products with seller information
CREATE OR REPLACE VIEW products_with_seller AS
SELECT 
  p.*,
  u.name as seller_name,
  u.photo_url as seller_photo_url,
  u.campus as seller_campus
FROM products p
LEFT JOIN users u ON p.user_id = u.id
WHERE p.is_sold = false;

-- View for user ratings
CREATE OR REPLACE VIEW user_ratings AS
SELECT 
  reviewed_user_id,
  COUNT(*) as total_reviews,
  AVG(rating) as average_rating,
  COUNT(CASE WHEN rating = 5 THEN 1 END) as five_star_reviews,
  COUNT(CASE WHEN rating = 4 THEN 1 END) as four_star_reviews,
  COUNT(CASE WHEN rating = 3 THEN 1 END) as three_star_reviews,
  COUNT(CASE WHEN rating = 2 THEN 1 END) as two_star_reviews,
  COUNT(CASE WHEN rating = 1 THEN 1 END) as one_star_reviews
FROM reviews
GROUP BY reviewed_user_id;

-- =====================================================
-- CONSTRAINTS AND VALIDATIONS
-- =====================================================

-- Add check constraints for data validation
ALTER TABLE products ADD CONSTRAINT check_price_positive CHECK (price > 0);
ALTER TABLE products ADD CONSTRAINT check_title_not_empty CHECK (LENGTH(TRIM(title)) > 0);
ALTER TABLE reviews ADD CONSTRAINT check_rating_range CHECK (rating >= 1 AND rating <= 5);
ALTER TABLE messages ADD CONSTRAINT check_message_not_empty CHECK (LENGTH(TRIM(message_text)) > 0);

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE users IS 'User profiles and authentication data';
COMMENT ON TABLE products IS 'Products listed for sale by users';
COMMENT ON TABLE reviews IS 'User reviews and ratings';
COMMENT ON TABLE favorites IS 'User favorite products';
COMMENT ON TABLE messages IS 'Chat messages between users';
COMMENT ON TABLE chats IS 'Chat sessions between users';

COMMENT ON FUNCTION delete_user_account(UUID) IS 'Deletes user account and all associated data';
COMMENT ON FUNCTION get_user_chats_with_details(UUID) IS 'Returns user chats with last message and other user details';
COMMENT ON FUNCTION mark_messages_as_read(TEXT, UUID) IS 'Marks all messages in a chat as read for a specific user';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if RLS is enabled on all tables
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'products', 'reviews', 'favorites', 'messages', 'chats');

-- Check policies on all tables
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check functions
SELECT 
  proname as function_name,
  prosrc as function_source
FROM pg_proc 
WHERE proname IN ('delete_user_account', 'get_user_chats_with_details', 'mark_messages_as_read');

-- =====================================================
-- SETUP COMPLETE
-- =====================================================

-- This completes the database setup for UniMart authentication features
-- All tables have RLS enabled with appropriate policies
-- Functions are created for account deletion and chat management
-- Indexes are created for optimal performance
-- Views are created for common queries
-- Constraints are added for data validation

-- Next steps:
-- 1. Configure email templates in Supabase Dashboard
-- 2. Set up SMTP settings for password reset emails
-- 3. Test all authentication flows
-- 4. Monitor logs for any issues

