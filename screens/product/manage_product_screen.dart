// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/widgets/loading_widget.dart';
import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/product_model.dart';
import 'add_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen>
    with TickerProviderStateMixin {
  late Future<List<ProductModel>> _productsFuture;
  late AnimationController _fabController;
  late AnimationController _listController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _fabSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProducts();
  }

  void _setupAnimations() {
    // FAB animations
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _fabSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
        );

    // List animation controller
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start FAB animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;

    if (currentUser?.id != null) {
      _productsFuture = SupabaseService.instance.getProductsByUser(
        currentUser!.id,
      );

      // Trigger list animation when products load
      _productsFuture
          .then((_) {
            if (mounted) {
              _listController.reset();
              _listController.forward();
            }
          })
          .catchError((error) {
            // Handle error gracefully
          });
    } else {
      // Handle case where user is null
      _productsFuture = Future.value([]);
    }
  }

  void _refresh() {
    setState(() => _loadProducts());
    // Add a subtle bounce to FAB on refresh
    if (_fabController.isCompleted) {
      _fabController.reverse().then((_) {
        if (mounted) _fabController.forward();
      });
    }
  }

  Future<void> _goToAddProduct() async {
    try {
      // Scale down FAB before navigation
      if (_fabController.isCompleted) {
        await _fabController.reverse();
      }

      final added = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddProductScreen()),
      );

      // Scale back up FAB after returning
      if (mounted && !_fabController.isCompleted) {
        _fabController.forward();
      }

      if (added == true && mounted) _refresh();
    } catch (e) {
      // Ensure FAB is restored even if navigation fails
      if (mounted && !_fabController.isCompleted) {
        _fabController.forward();
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product, int index) async {
    try {
      // Show delete confirmation with animation
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text('Delete Product'),
                  content: const Text(
                    'Are you sure you want to delete this product? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      if (confirmed == true && mounted) {
        // Show loading indicator while deleting
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await SupabaseService.instance.deleteProduct(product.id!);

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _refresh();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if open
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true, // Allow back navigation
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Manage Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryBlue,
          toolbarHeight: 60,
          elevation: 10,
        ),
        body: FutureBuilder<List<ProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: LoadingIndicator(message: 'Loading...'),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Something went wrong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            final products = snapshot.data ?? [];

            if (products.isEmpty) {
              return Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first product',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: AnimatedBuilder(
                    animation: _listController,
                    builder: (context, child) {
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, i) {
                          final product = products[i];

                          // Staggered animation for each item
                          final animationDelay = (i * 0.1).clamp(0.0, 1.0);
                          final itemAnimation =
                              Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _listController,
                                  curve: Interval(
                                    animationDelay,
                                    (0.6 + animationDelay).clamp(0.0, 1.0),
                                    curve: Curves
                                        .easeOut, // Changed from easeOutBack
                                  ),
                                ),
                              );

                          final slideAnimation =
                              Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _listController,
                                  curve: Interval(
                                    animationDelay,
                                    (0.6 + animationDelay).clamp(0.0, 1.0),
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              );

                          return AnimatedBuilder(
                            animation: itemAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: itemAnimation.value.clamp(0.0, 1.0),
                                child: SlideTransition(
                                  position: slideAnimation,
                                  child: Opacity(
                                    opacity: itemAnimation.value.clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(
                                            16,
                                          ),
                                          title: Text(
                                            product.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              '₦${product.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _AnimatedIconButton(
                                                icon: Icons.edit,
                                                color: Colors.blue,
                                                onPressed: () async {
                                                  try {
                                                    final updated =
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                AddProductScreen(
                                                                  editProduct:
                                                                      product,
                                                                ),
                                                          ),
                                                        );
                                                    if (updated == true &&
                                                        mounted) {
                                                      _refresh();
                                                    }
                                                  } catch (e) {}
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              _AnimatedIconButton(
                                                icon: Icons.delete,
                                                color: AppColors.error,
                                                onPressed: () =>
                                                    _deleteProduct(product, i),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) {
            return SlideTransition(
              position: _fabSlideAnimation,
              child: ScaleTransition(
                scale: _fabScaleAnimation,
                child: FloatingActionButton.extended(
                  onPressed: _goToAddProduct,
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Product"),
                  heroTag: "addProduct",
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _AnimatedIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(widget.icon, color: widget.color),
                onPressed: widget.onPressed,
              ),
            ),
          );
        },
      ),
    );
  }
}
