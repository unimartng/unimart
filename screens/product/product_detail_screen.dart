// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/product_model.dart';

import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../chat/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });
    final product = await SupabaseService.instance.getProductById(
      widget.productId,
    );
    setState(() {
      _product = product;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(child: Text('Product not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      itemCount: _product!.imageUrls.length,
                      itemBuilder: (context, index) {
                        final url = _product!.imageUrls[index];
                        final isValid = url.startsWith('http');
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: isValid
                                ? (index == 0
                                      ? Hero(
                                          tag: 'product-image-${_product!.id}',
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        )
                                      : Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ))
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _product!.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Price: ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₦${_product!.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Category: ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _product!.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Condition: ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _product!.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_product!.seller != null)
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(_product!.seller!.name),
                      subtitle: Text(_product!.seller!.email),
                    ),
                  const SizedBox(height: 24),
                  if (_product!.seller != null &&
                      currentUser != null &&
                      _product!.seller!.id != currentUser.id)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat with Seller'),
                      onPressed: () async {
                        final chatId = await SupabaseService.instance
                            .createOrGetChat(
                              currentUser.id,
                              _product!.seller!.id,
                            );
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(chatId: chatId),
                            ),
                          );
                        }
                      },
                    ),
                  ElevatedButton(
                    onPressed: () {
                      // Implement edit or chat functionality
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
    );
  }
}
