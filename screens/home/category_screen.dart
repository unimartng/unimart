import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/models/category_model.dart';
import 'package:unimart/models/product_model.dart';
import 'package:unimart/services/supabase_service.dart';
import 'package:unimart/widgets/product_list_tile.dart';

class CategoryGridPage extends StatefulWidget {
  const CategoryGridPage({super.key});

  @override
  State<CategoryGridPage> createState() => _CategoryGridPageState();
}

class _CategoryGridPageState extends State<CategoryGridPage>
    with SingleTickerProviderStateMixin {
  List<Category> _categories = [];
  bool _isLoading = true;
  TabController? _tabController;
  List<List<ProductModel>> _productsByCategory = [];
  List<bool> _productsLoading = [];
  String _currentUserId = '';

  // Simplified categories
  final List<Map<String, dynamic>> _categoryData = [
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
    _loadCategories();
    final user = SupabaseService.instance.currentUser;
    _currentUserId = user?.id ?? '';
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = _categoryData
          .map((data) => Category(name: data['name']))
          .toList();

      setState(() {
        _categories = categories;
        _isLoading = false;
        _tabController = TabController(length: _categories.length, vsync: this);
        _productsByCategory = List.generate(_categories.length, (_) => []);
        _productsLoading = List.generate(_categories.length, (_) => true);
      });

      // Load products for all categories
      for (int i = 0; i < _categories.length; i++) {
        _loadProductsForCategory(i);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProductsForCategory(int index) async {
    if (index >= _categories.length) return;

    final category = _categories[index];

    try {
      final products = await SupabaseService.instance.getProducts(
        category: category.name,
      );

      if (mounted) {
        setState(() {
          _productsByCategory[index] = products;
          _productsLoading[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _productsLoading[index] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No categories found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 60),
          child: Column(children: [_buildAppBar(), _buildTabBar()]),
        ),
        body: TabBarView(
          controller: _tabController,
          children: List.generate(_categories.length, (index) {
            return _buildTabContent(index);
          }),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: 50,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Categories',
        style: GoogleFonts.poppins(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: AppColors.primaryBlue,
      ),
      labelColor: AppColors.primaryOrange,
      unselectedLabelColor: Colors.grey[600],
      labelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
      tabs: _categories.map((category) {
        return Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(category.name),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabContent(int index) {
    if (_productsLoading[index]) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productsByCategory[index].isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _categoryData[index]['icon'] as IconData,
              size: 64,
              color: _categoryData[index]['color'] as Color,
            ),
            const SizedBox(height: 16),
            Text(
              'No products in ${_categories[index].name}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new items!',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProductsForCategory(index),
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 5, right: 10, left: 10),
        itemCount: _productsByCategory[index].length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ProductListTile(
              product: _productsByCategory[index][i],
              currentUserId: _currentUserId,
            ),
          );
        },
      ),
    );
  }
}
