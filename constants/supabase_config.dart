class SupabaseConfig {
  // Replace these with your actual Supabase credentials
  static const String url = 'https://ubwqruzgcgqfzgcpzaqd.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVid3FydXpnY2dxZnpnY3B6YXFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzNjExNjAsImV4cCI6MjA2NzkzNzE2MH0.IBXzs2xkCFhb2H6EpYXAMJpQr41lunFUOoF8FF_8JFk';

  // Storage bucket names
  static const String imagesBucket = 'images';
  static const String avatarsBucket = 'avatars';

  // Table names
  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String savedItemsTable = 'saved_items';
  static const String reviewsTable = 'reviews';
  static const String notificationsTable = 'notifications';

  // Authentication redirect URLs
  static const String redirectUrl = 'io.supabase.unimart://login-callback/';

  // File upload limits
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB

  // Allowed image types
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  ];

  // Product categories
  static const List<String> categories = [
    'Electronics',
    'Fashion',
    'Books',
    'Sports',
    'Food',
    'Services',
    'Other',
  ];

  // Product conditions
  static const List<String> conditions = [
    'new',
    'like_new',
    'good',
    'fair',
    'poor',
  ];

  // Campus options (customize for your university)
  static const List<String> campuses = [
    'Main Campus',
    'North Campus',
    'South Campus',
    'East Campus',
    'West Campus',
    'Online',
  ];
}
