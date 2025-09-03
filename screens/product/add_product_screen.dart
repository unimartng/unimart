// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unimart/screens/product/plan_selection_screen.dart';

import 'package:unimart/widgets/custom_button.dart';
import 'package:unimart/widgets/loading_widget.dart';
import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/product_model.dart';
import '../../models/university_model.dart';
import '../../constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? editProduct;
  const AddProductScreen({super.key, this.editProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCondition;
  String? _selectedCategory;
  University? _selectedUniversity;
  List<dynamic> _images = [];
  bool _isLoading = false;
  bool _isFeatured = false;

  List<String> _conditions = ['new', 'like_new', 'good', 'fair', 'poor'];
  List<String> _categories = [
    'Electronics',
    'Fashion',
    'Books',
    'Sports',
    'Food',
    'Services',
    'Other',
  ];
  List<University> _universities = [];
  bool _categoriesLoading = false;
  bool _conditionsLoading = false;
  bool _universitiesLoading = true;

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  // Form field animations
  final List<AnimationController> _fieldControllers = [];
  final List<Animation<Offset>> _fieldAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategories();
    _loadConditions();
    _loadUniversities();

    if (widget.editProduct != null) {
      _nameController.text = widget.editProduct!.title;
      _descController.text = widget.editProduct!.description;
      _priceController.text = widget.editProduct!.price.toString();
      _selectedCategory = widget.editProduct!.category;
      _images = List<dynamic>.from(widget.editProduct!.imageUrls);
      _isFeatured = widget.editProduct!.isFeatured;
      // Optionally set featuredUntil if you want to show expiry
    }

    _startInitialAnimations();
  }

  void _initializeAnimations() {
    // Main animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticInOut),
    );

    // Form field animations (staggered)
    for (int i = 0; i < 8; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 400 + (i * 100)),
        vsync: this,
      );
      final animation = Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

      _fieldControllers.add(controller);
      _fieldAnimations.add(animation);
    }
  }

  void _startInitialAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    });

    // Stagger form field animations
    for (int i = 0; i < _fieldControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 150)), () {
        if (mounted) {
          _fieldControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    for (final controller in _fieldControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _categoriesLoading = true;
    });
    try {
      final response = await SupabaseService.instance.client
          .from('categories')
          .select('name');
      if (response.isNotEmpty) {
        if (mounted) {
          setState(() {
            _categories = response
                .map<String>((e) => e['name'] as String)
                .toList();
          });
        }
      }
    } catch (e) {
      // Fallback to hardcoded list
    } finally {
      if (mounted) {
        setState(() {
          _categoriesLoading = false;
        });
      }
    }
  }

  Future<void> _loadConditions() async {
    if (!mounted) return;
    setState(() {
      _conditionsLoading = true;
    });
    try {
      final response = await SupabaseService.instance.client
          .from('conditions')
          .select('name');
      if (response.isNotEmpty) {
        if (mounted) {
          setState(() {
            _conditions = response
                .map<String>((e) => e['name'] as String)
                .toList();
          });
        }
      }
    } catch (e) {
      // Fallback to hardcoded list
    } finally {
      if (mounted) {
        setState(() {
          _conditionsLoading = false;
        });
      }
    }
  }

  Future<void> _loadUniversities() async {
    setState(() => _universitiesLoading = true);
    try {
      final universities = await SupabaseService.instance.getUniversities();
      setState(() {
        _universities = universities;
        _universitiesLoading = false;
      });
    } catch (e) {
      setState(() => _universitiesLoading = false);
    }
  }

  Future<void> _pickImages() async {
    // Animate button press
    _rotationController.forward().then((_) {
      _rotationController.reverse();
    });

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
      });

      // Animate new images appearing
      _scaleController.reset();
      _scaleController.forward();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _images.isEmpty) {
      // Shake animation for error
      _shakeAnimation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and add images.')),
      );
      return;
    }

    if (_isFeatured) {
      final int? selectedDays = await Navigator.push<int>(
        context,
        _createSlideRoute(
          PlanSelectionScreen(
            images: _images,
            productData: {
              'title': _nameController.text.trim(),
              'description': _descController.text.trim(),
              'price': double.parse(_priceController.text.trim()),
              'category': _selectedCategory,
            },
          ),
        ),
      );

      if (selectedDays != null) {
        await _completeSubmission(selectedDays);
      }
    } else {
      await _completeSubmission(null);
    }
  }

  void _shakeAnimation() {
    _rotationController.reset();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _rotationController.forward().then((_) {
            _rotationController.reverse();
          });
        }
      });
    }
  }

  // Custom page route with slide transition
  Route<int> _createSlideRoute(Widget page) {
    return PageRouteBuilder<int>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Future<void> _completeSubmission(int? featuredDays) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user == null) throw Exception('User not found');

      List<String> imageUrls = [];
      for (final img in _images) {
        if (img is String) {
          imageUrls.add(img);
        } else if (img is XFile) {
          final bytes = await img.readAsBytes();
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
          final url = await SupabaseService.instance.uploadImage(
            fileName,
            bytes,
          );
          imageUrls.add(url);
        }
      }

      final product = ProductModel(
        id: '',
        userId: user.id,
        title: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory!,
        imageUrls: imageUrls,
        campus: user.campus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSold: false,
        isFeatured: featuredDays != null,
        featuredUntil: featuredDays != null
            ? DateTime.now().add(Duration(days: featuredDays))
            : null,
        seller: user,
      );

      final newProduct = await SupabaseService.instance.createProduct(product);
      if (newProduct.id != null && newProduct.id!.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              margin: EdgeInsets.all(15),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color.fromARGB(255, 14, 90, 31),
              duration: Duration(seconds: 2),
              content: Text('Product created successfully!'),
            ),
          );
        }
        _nameController.clear();
        _descController.clear();
        _priceController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedCondition = null;
          _images = [];
          _isFeatured = false;
        });
      } else {
        throw Exception('Product creation failed. No ID returned.');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProduct([int? featuredDays]) async {
    // Build imageUrls from _images
    List<String> imageUrls = [];
    for (final img in _images) {
      if (img is String) {
        imageUrls.add(img);
      } else if (img is XFile) {
        final bytes = await img.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final url = await SupabaseService.instance.uploadImage(fileName, bytes);
        imageUrls.add(url);
      }
    }

    if (widget.editProduct != null) {
      await SupabaseService.instance.updateProduct(widget.editProduct!.id!, {
        'title': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory!,
        'is_featured': _isFeatured,
        'featured_until': (_isFeatured && featuredDays != null)
            ? DateTime.now().add(Duration(days: featuredDays)).toIso8601String()
            : null,
        'image_urls': imageUrls,
      });
    } else {
      // ...existing code for creating product...
    }
    Navigator.pop(context, true);
  }

  Widget _buildAnimatedImage(dynamic img, int index) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildImage(img, index),
        );
      },
    );
  }

  Widget _buildImage(dynamic img, int index) {
    if (img is String) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          img,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, size: 32),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: LoadingIndicator(message: 'Loading...'));
          },
        ),
      );
    } else if (img is XFile) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: img.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                snapshot.data!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            );
          },
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(img.path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAnimatedFormField(Widget child, int index) {
    if (index >= _fieldAnimations.length) return child;

    return SlideTransition(
      position: _fieldAnimations[index],
      child: FadeTransition(opacity: _fieldControllers[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: SlideTransition(
          position: _slideAnimation,
          child: Text(
            'Add Product',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAnimatedFormField(
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Product Name',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter product name'
                              : null,
                        ),
                        0,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFormField(
                        TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(
                            hintText: 'Product Description',
                            fillColor: Theme.of(context).colorScheme.tertiary,
                          ),
                          minLines: 3,
                          maxLines: 5,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter description'
                              : null,
                        ),
                        1,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFormField(
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Price',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter price' : null,
                        ),
                        2,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFormField(
                        DropdownButtonFormField<String>(
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Theme.of(context).colorScheme.tertiary,
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                          value: _selectedCondition,
                          items: _conditions
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: _conditionsLoading
                              ? null
                              : (v) => setState(() => _selectedCondition = v),
                          decoration: InputDecoration(
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Condition Type',
                          ),
                          validator: (v) =>
                              v == null ? 'Select condition' : null,
                          disabledHint: _conditionsLoading
                              ? const Text('Loading...')
                              : null,
                        ),
                        3,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFormField(
                        DropdownButtonFormField<String>(
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Theme.of(context).colorScheme.tertiary,
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                          value: _categories.contains(_selectedCategory)
                              ? _selectedCategory
                              : null,
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: _categoriesLoading
                              ? null
                              : (v) => setState(() => _selectedCategory = v),
                          decoration: InputDecoration(
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Category',
                          ),
                          validator: (v) =>
                              v == null ? 'Select category' : null,
                          disabledHint: _categoriesLoading
                              ? const Text('Loading...')
                              : null,
                        ),
                        4,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFormField(
                        DropdownButtonFormField<University>(
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Theme.of(context).colorScheme.tertiary,
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                          value: _selectedUniversity,
                          items: _universities
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u.name),
                                ),
                              )
                              .toList(),
                          onChanged: _universitiesLoading
                              ? null
                              : (v) => setState(() => _selectedUniversity = v),
                          decoration: InputDecoration(
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Select University',
                          ),
                          validator: (v) =>
                              v == null ? 'Select university' : null,
                          disabledHint: _universitiesLoading
                              ? const Text('Loading...')
                              : null,
                        ),
                        5,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFormField(
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: _isFeatured
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: _isFeatured
                                ? Border.all(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.3,
                                    ),
                                  )
                                : null,
                          ),
                          child: SwitchListTile(
                            activeColor: AppColors.primaryBlue,
                            title: Text(
                              'Feature this product',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            value: _isFeatured,
                            onChanged: (value) =>
                                setState(() => _isFeatured = value),
                          ),
                        ),
                        6,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFormField(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Images',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 90,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ..._images.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final img = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          _buildAnimatedImage(img, index),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () async {
                                                setState(() {
                                                  _images.remove(img);
                                                });
                                                if (img is String) {
                                                  final uri = Uri.parse(img);
                                                  final segments =
                                                      uri.pathSegments;
                                                  final imageIndex = segments
                                                      .indexOf('images');
                                                  if (imageIndex != -1 &&
                                                      imageIndex + 1 <
                                                          segments.length) {
                                                    final imagePath = segments
                                                        .sublist(imageIndex + 1)
                                                        .join('/');
                                                    await SupabaseService
                                                        .instance
                                                        .deleteImage(imagePath);
                                                  }
                                                }
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.8,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: AnimatedBuilder(
                                      animation: _rotationAnimation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _rotationAnimation.value * 0.1,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.tertiary,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.primaryBlue,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryBlue
                                                      .withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.add_a_photo,
                                              size: 28,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        7,
                      ),
                      const SizedBox(height: 24),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: CustomButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    bool success = false;
                                    if (widget.editProduct != null) {
                                      int? selectedDays;
                                      if (_isFeatured) {
                                        selectedDays =
                                            await Navigator.push<int>(
                                              context,
                                              _createSlideRoute(
                                                PlanSelectionScreen(
                                                  images: _images,
                                                  productData: {
                                                    'title': _nameController
                                                        .text
                                                        .trim(),
                                                    'description':
                                                        _descController.text
                                                            .trim(),
                                                    'price': double.parse(
                                                      _priceController.text
                                                          .trim(),
                                                    ),
                                                    'category':
                                                        _selectedCategory,
                                                  },
                                                ),
                                              ),
                                            );
                                      }
                                      await _saveProduct(selectedDays);
                                      success = true;
                                    } else {
                                      await _submit();
                                      success = true;
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Product updated successfully!'
                                                : 'Product update failed.',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(15),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(15),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  widget.editProduct != null
                                      ? 'Update'
                                      : 'Submit',
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
