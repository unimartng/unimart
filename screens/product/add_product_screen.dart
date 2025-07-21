import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/product_model.dart';
import '../../constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCondition;
  String? _selectedCategory;
  List<XFile> _images = [];
  bool _isLoading = false;

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
  bool _categoriesLoading = false;
  bool _conditionsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadConditions();
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _images = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and add images.')),
      );
      return;
    }
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
        final bytes = await img.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final url = await SupabaseService.instance.uploadImage(fileName, bytes);
        imageUrls.add(url);
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
        seller: user,
      );
      await SupabaseService.instance.createProduct(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        // Clear all fields after successful add
        _nameController.clear();
        _descController.clear();
        _priceController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedCondition = null;
          _images = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter product name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Product Description',
                ),
                minLines: 3,
                maxLines: 5,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                items: _conditions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _conditionsLoading
                    ? null
                    : (v) => setState(() => _selectedCondition = v),
                decoration: const InputDecoration(labelText: 'Condition Type'),
                validator: (v) => v == null ? 'Select condition' : null,
                disabledHint: _conditionsLoading
                    ? const Text('Loading...')
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _categoriesLoading
                    ? null
                    : (v) => setState(() => _selectedCategory = v),
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => v == null ? 'Select category' : null,
                disabledHint: _categoriesLoading
                    ? const Text('Loading...')
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Images', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._images.map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.file(
                          File(img.path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBlue),
                        ),
                        child: const Icon(Icons.add_a_photo, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
