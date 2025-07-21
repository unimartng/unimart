import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../services/auth_provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    if (currentUser == null) {
      setState(() {
        _favoriteProducts = [];
        _isLoading = false;
      });
      return;
    }
    try {
      final favoriteIds = await SupabaseService.instance.getFavoritesForUser(
        currentUser.id,
      );

      List<ProductModel> products = [];
      for (final productId in favoriteIds) {
        final product = await SupabaseService.instance.getProductById(
          productId,
        );
        if (product != null) {
          products.add(product);
        }
      }
      setState(() {
        _favoriteProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _favoriteProducts = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteProducts.isEmpty
          ? Center(child: Text('No favorite products yet.'))
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: _favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = _favoriteProducts[index];
                  return ProductCard(
                    product: product,
                    currentUserId: currentUser?.id ?? '',
                    onFavoriteChanged: (isFavorite) async {
                      if (!isFavorite) {
                        setState(() {
                          _favoriteProducts.removeAt(index);
                        });
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
