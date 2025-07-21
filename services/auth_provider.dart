import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String campus,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final response = await SupabaseService.instance.signUp(
        email: email,
        password: password,
        name: name,
        campus: campus,
      );

      if (response.user != null) {
        _currentUser = await SupabaseService.instance.getUserProfile(
          response.user!.id,
        );
        notifyListeners();
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      setLoading(true);
      setError(null);

      final response = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = await SupabaseService.instance.getUserProfile(
          response.user!.id,
        );
        notifyListeners();
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setLoading(true);
      setError(null);

      await SupabaseService.instance.signInWithGoogle();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      setLoading(true);
      await SupabaseService.instance.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadCurrentUser() async {
    setLoading(true);
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        _currentUser = await SupabaseService.instance.getUserProfile(user.id);
        notifyListeners();
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      setLoading(true);
      setError(null);

      if (_currentUser != null) {
        await SupabaseService.instance.updateUserProfile(
          _currentUser!.id,
          updates,
        );
        _currentUser = await SupabaseService.instance.getUserProfile(
          _currentUser!.id,
        );
        notifyListeners();
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  //Get user email
  String? getCurrentUserEmail() {
    final session = SupabaseService.instance.client.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
