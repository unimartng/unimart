import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_theme.dart';
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
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
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
    return MaterialApp.router(
      title: 'Unimart',
      theme: AppTheme.lightTheme,
      routerConfig: NavigationService.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
