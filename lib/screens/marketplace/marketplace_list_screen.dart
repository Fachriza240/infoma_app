import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/marketplace_product_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import 'marketplace_detail_screen.dart';
import 'marketplace_form_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class MarketplaceListScreen extends StatefulWidget {
  const MarketplaceListScreen({super.key});

  @override
  State<MarketplaceListScreen> createState() => _MarketplaceListScreenState();
}

class _MarketplaceListScreenState extends State<MarketplaceListScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    'Baru',
    'Bekas',
    '< 1 Juta',
    '1-5 Juta',
    '> 5 Juta',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    final auth = context.read<AuthProvider>();
    final marketplaceProvider = context.read<MarketplaceProvider>();

    if (auth.isProvider && auth.user != null) {
      // Penyedia: hanya lihat miliknya
      await marketplaceProvider.fetchMyProducts(auth.user!.id);
    } else {
      // Mahasiswa: lihat semua
      await marketplaceProvider.fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final provider = context.read<MarketplaceProvider>();

    if (_selectedFilter == 'Semua') {
      provider.filterByCondition(null);
      provider.filterByPrice(null, null);
    } else if (_selectedFilter == 'Baru') {
      provider.filterByCondition('new');
      provider.filterByPrice(null, null);
    } else if (_selectedFilter == 'Bekas') {
      provider.filterByCondition(null);
      provider.filterByPrice(null, null);
    } else if (_selectedFilter == '< 1 Juta') {
      provider.filterByCondition(null);
      provider.filterByPrice(null, 1000000);
    } else if (_selectedFilter == '1-5 Juta') {
      provider.filterByCondition(null);
      provider.filterByPrice(1000000, 5000000);
    } else if (_selectedFilter == '> 5 Juta') {
      provider.filterByCondition(null);
      provider.filterByPrice(5000000, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPenyedia = authProvider.user?.role == 'provider';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isPenyedia)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MarketplaceFormScreen(),
                  ),
                );

                if (result == true && context.mounted) {
                  context.read<MarketplaceProvider>().fetchProducts();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<MarketplaceProvider>().search('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.greyExtraLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<MarketplaceProvider>().search(value);
              },
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _applyFilters();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.primary : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.greyLight,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Products List
          Expanded(
            child: Consumer<MarketplaceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchProducts(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (!provider.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: AppColors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada produk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Produk akan muncul di sini',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        if (isPenyedia) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MarketplaceFormScreen(),
                                ),
                              );

                              if (result == true && context.mounted) {
                                context
                                    .read<MarketplaceProvider>()
                                    .fetchProducts();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Produk'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchProducts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final product = provider.products[index];
                      return _buildProductCard(context, product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, MarketplaceProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarketplaceDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: _buildImage(product),
                ),

                // Condition Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: product.isNew ? AppColors.success : AppColors.info,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.conditionLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Stock Badge
                if (product.stockQuantity > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Stok: ${product.stockQuantity}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price & Views
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        Helpers.formatCurrency(product.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),

                      // Views
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.viewsCount} views',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(MarketplaceProductModel product) {
    if (product.images.isEmpty) {
      return Container(
        height: 180,
        color: AppColors.greyExtraLight,
        child: const Center(
          child: Icon(
            Icons.shopping_bag,
            size: 64,
            color: AppColors.grey,
          ),
        ),
      );
    }

    final imagePath = product.images[0];
    final isLocalFile =
        !imagePath.startsWith('http') && !imagePath.startsWith('https');

    if (isLocalFile && !kIsWeb) {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: double.infinity,
          height: 180,
          color: AppColors.greyExtraLight,
          child: const Icon(
            Icons.shopping_bag,
            size: 64,
            color: AppColors.grey,
          ),
        ),
      );
    }

    return Image.network(
      imagePath,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: 180,
        color: AppColors.greyExtraLight,
        child: const Icon(
          Icons.shopping_bag,
          size: 64,
          color: AppColors.grey,
        ),
      ),
    );
  }
}
