import 'package:flutter/material.dart';

import 'package:unimart/services/auth_provider.dart';
import 'package:unimart/widgets/search_bar.dart';
import '../../models/product_model.dart';
import '../../services/supabase_service.dart';
import '../../constants/app_colors.dart';
import '../../widgets/product_card.dart';

import 'package:unimart/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _showWelcomeBanner = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps, 'color': Colors.blueGrey},
    {'name': 'Electronics', 'icon': Icons.devices, 'color': Colors.blue},
    {'name': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pink},
    {'name': 'Books', 'icon': Icons.menu_book, 'color': Colors.orange},
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': Colors.green},
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Colors.redAccent},
    {'name': 'Services', 'icon': Icons.handshake, 'color': Colors.teal},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await SupabaseService.instance.getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        bool matchesCategory =
            _selectedCategory.isEmpty ||
            _selectedCategory == 'All' ||
            product.category == _selectedCategory;

        bool matchesSearch =
            _searchQuery.isEmpty ||
            product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  final authService = AuthProvider();
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    return Scaffold(
      body: Column(
        children: [
          // Custom App Bar
          Container(
            height: MediaQuery.of(context).size.height / 4,
            padding: EdgeInsets.only(top: 50, right: 8, left: 8, bottom: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hello, ${currentUser?.name ?? "Student"}👋',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Find great deals on campus',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 250, 250, 250),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundImage: AssetImage(
                          'assets/images/profile.jpg',
                        ),
                        radius: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search Bar & Campus Filter
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: CustomSearchBar(
                    onChanged: _onSearchChanged,
                    hintText: 'Search products, categories...',
                  ),
                ),
              ],
            ),
          ),

          // Show welcome banner only if _showWelcomeBanner is true
          if (_showWelcomeBanner)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AppColors.primaryOrange.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.campaign, color: Colors.white, size: 38),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Unimart! 🎉',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'List your items or grab a deal from fellow students.',
                          style: Theme.of(context).textTheme.bodyMedium
                              // ignore: deprecated_member_use
                              ?.copyWith(color: Colors.white.withOpacity(0.95)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showWelcomeBanner = false;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Category Chips
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected =
                      category['name'] == _selectedCategory ||
                      (_selectedCategory.isEmpty && category['name'] == 'All');
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onCategorySelected(category['name']),
                          borderRadius: BorderRadius.circular(32),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? category['color']
                                  : AppColors.surface,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: category['color'].withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                              border: isSelected
                                  ? Border.all(
                                      color: category['color'],
                                      width: 2.5,
                                    )
                                  : Border.all(
                                      // ignore: deprecated_member_use
                                      color: AppColors.textLight.withOpacity(
                                        0.15,
                                      ),
                                      width: 1.2,
                                    ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              category['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : category['color'],
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? category['color']
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Text(
                'Latest Products',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/empty.png', height: 120),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final currentUser = Provider.of<AuthProvider>(
                          context,
                        ).currentUser;
                        return ProductCard(
                          product: product,
                          currentUserId: currentUser?.id ?? '',
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
