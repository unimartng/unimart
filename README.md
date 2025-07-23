# Unimart - Campus Marketplace App

A Flutter mobile app for university students to buy and sell products and services within their campus.

## 🚀 Features

### Authentication
- ✅ Email and password sign up/login
- ✅ Google OAuth integration
- ✅ User profile management (name, email, campus, profile photo)

### Home Page
- ✅ Search bar with real-time filtering
- ✅ Campus filter chips
- ✅ Promotional banner
- ✅ Horizontal scrollable category icons
- ✅ Product grid with modern cards
- ✅ Pull-to-refresh functionality

### Product Management
- ✅ Product listing with images, title, price, seller info
- ✅ Category-based filtering
- ✅ Search functionality
- ✅ Product detail pages (placeholder)
- ✅ Add product functionality (placeholder)

### Chat System
- ✅ Real-time messaging infrastructure
- ✅ Chat list and individual chat screens (placeholder)
- ✅ Message history and notifications

### Profile Management
- ✅ User profile viewing and editing
- ✅ User's product listings
- ✅ Saved items (placeholder)
- ✅ Logout functionality

## 🎨 Design

- **Color Scheme**: Blue (#4A90E2) and Orange (#F5A623) with clean white backgrounds
- **Typography**: Inter font family for modern, readable text
- **Components**: Rounded corners (12px), subtle shadows, and smooth animations
- **Mobile-First**: Optimized for mobile devices with responsive design

## 🛠 Tech Stack

- **Frontend**: Flutter 3.8+
- **Backend**: Supabase (Authentication, Database, Real-time, Storage)
- **State Management**: Provider
- **Navigation**: Go Router
- **UI Components**: Custom widgets with Material Design 3
- **Image Handling**: Cached Network Image
- **Icons**: Material Icons and custom SVG support

## 📱 App Structure

```
lib/
├── constants/
│   ├── app_colors.dart      # Color definitions
│   └── app_theme.dart       # Theme configuration
├── models/
│   ├── user_model.dart      # User data model
│   ├── product_model.dart   # Product data model
│   ├── message_model.dart   # Message data model
│   └── chat_model.dart      # Chat data model
├── services/
│   ├── supabase_service.dart # Supabase API integration
│   ├── auth_provider.dart   # Authentication state management
│   └── navigation_service.dart # App navigation
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── product/
│   │   ├── product_detail_screen.dart
│   │   └── add_product_screen.dart
│   ├── chat/
│   │   ├── chat_list_screen.dart
│   │   └── chat_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── search_bar.dart
│   ├── category_item.dart
│   └── product_card.dart
└── main.dart
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8+
- Dart SDK
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd unimart
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new Supabase project
   - Get your project URL and anon key
   - Update `lib/main.dart` with your Supabase credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. **Set up Supabase Database**
   Create the following tables in your Supabase database:

   **users table:**
   ```sql
   CREATE TABLE users (
     id UUID PRIMARY KEY REFERENCES auth.users(id),
     email TEXT NOT NULL,
     name TEXT NOT NULL,
     campus TEXT NOT NULL,
     profile_photo_url TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

   **products table:**
   ```sql
   CREATE TABLE products (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID REFERENCES users(id),
     title TEXT NOT NULL,
     description TEXT,
     price DECIMAL(10,2) NOT NULL,
     category TEXT NOT NULL,
     image_urls TEXT[],
     campus TEXT NOT NULL,
     is_sold BOOLEAN DEFAULT FALSE,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

   **chats table:**
   ```sql
   CREATE TABLE chats (
     chat_id TEXT PRIMARY KEY,
     user1_id UUID REFERENCES users(id),
     user2_id UUID REFERENCES users(id),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

   **messages table:**
   ```sql
   CREATE TABLE messages (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     chat_id TEXT REFERENCES chats(chat_id),
     sender_id UUID REFERENCES users(id),
     receiver_id UUID REFERENCES users(id),
     message_text TEXT NOT NULL,
     image_url TEXT,
     is_read BOOLEAN DEFAULT FALSE,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Supabase Setup

1. **Authentication**: Enable Email and Google OAuth providers
2. **Storage**: Create a bucket named 'images' for product photos
3. **Row Level Security**: Configure RLS policies for data security
4. **Real-time**: Enable real-time subscriptions for chat functionality

### Environment Variables

Create a `.env` file in the root directory:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 📱 Features in Detail

### Authentication Flow
- Users can sign up with email/password or Google OAuth
- Profile creation with campus selection
- Secure session management

### Product Discovery
- Browse products by category
- Search by title and description
- Filter by campus location
- View product details with seller information

### Chat System
- Real-time messaging between buyers and sellers
- Chat history persistence
- Message status indicators

### User Profiles
- View and edit personal information
- Manage product listings
- Track transaction history

## 🎯 Next Steps

### Immediate Tasks
1. Complete product detail screen implementation
2. Implement add product functionality with image upload
3. Complete chat screen with real-time messaging
4. Add profile screen with user management

### Future Enhancements
1. Push notifications for new messages and product updates
2. Payment integration for secure transactions
3. Rating and review system
4. Advanced search filters
5. Offline support with local caching
6. Dark mode theme
7. Multi-language support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues or have questions:
1. Check the existing issues
2. Create a new issue with detailed information
3. Contact the development team

---

**Built with ❤️ for university students**
