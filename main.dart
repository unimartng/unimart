import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimart/constants/theme_provider.dart';
import 'package:unimart/screens/splash/splash_screen.dart';
import 'constants/supabase_config.dart';
import 'services/auth_provider.dart';
import 'services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const UnimartApp(),
    ),
  );
}

class UnimartApp extends StatefulWidget {
  const UnimartApp({super.key});

  @override
  State<UnimartApp> createState() => _UnimartAppState();
}

class _UnimartAppState extends State<UnimartApp> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Use post-frame callback to ensure provider is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.loadCurrentUser();
      });
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, _) {
        final theme = themeProvider.themeData;
        
        if (authProvider.isLoading) {
          // Show splash/loading screen while checking auth state
          return MaterialApp(
            theme: theme,
            home: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(child: SplashScreen()),
            ),
            debugShowCheckedModeBanner: false,
          );
        }
        // Show the real app after loading
        return MaterialApp.router(
          title: 'Unimart',
          theme: theme,
          routerConfig: NavigationService.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
