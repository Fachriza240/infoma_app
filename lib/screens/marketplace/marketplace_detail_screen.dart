import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_badge.dart';
import '../../core/utils/helpers.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/auth_provider.dart';
import 'marketplace_form_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/bookmark_provider.dart';
import '../../providers/transaction_provider.dart';  

class MarketplaceDetailScreen extends StatefulWidget {
  final int productId;

  const MarketplaceDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<MarketplaceDetailScreen> createState() =>
      _MarketplaceDetailScreenState();
}

class _MarketplaceDetailScreenState extends State<MarketplaceDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceProvider>().fetchProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPenyedia = authProvider.user?.role == 'provider';

    return Scaffold(
      body: Consumer<MarketplaceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Detail Produk'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Detail Produk'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = provider.selectedProduct;
          if (product == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Detail Produk'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: const Center(child: Text('Produk tidak ditemukan')),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Carousel
                      if (product.images.isNotEmpty)
                        PageView.builder(
                          itemCount: product.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildImage(product.images[index]);
                          },
                        )
                      else
                        Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.shopping_bag,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                      // Gradient Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Image Indicator
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  // ✅ TAMBAH INI - Bookmark Button untuk Mahasiswa
                  if (!isPenyedia)
                    Consumer2<AuthProvider, BookmarkProvider>(
                      builder: (context, auth, bookmarkProvider, child) {
                        if (auth.user == null) return const SizedBox.shrink();

                        final isBookmarked = bookmarkProvider.isBookmarked(
                          'marketplace',
                          widget.productId,
                          auth.user!.id,
                        );

                        return IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          onPressed: () async {
                            await bookmarkProvider.toggleBookmark(
                              userId: auth.user!.id,
                              type: 'marketplace',
                              itemId: widget.productId,
                            );

                            if (mounted) {
                              Helpers.showSnackbar(
                                context,
                                isBookmarked
                                    ? 'Dihapus dari bookmark'
                                    : 'Ditambahkan ke bookmark',
                              );
                            }
                          },
                        );
                      },
                    ),
                  if (isPenyedia) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MarketplaceFormScreen(
                              product: product,
                            ),
                          ),
                        );

                        if (result == true && context.mounted) {
                          context
                              .read<MarketplaceProvider>()
                              .fetchProductById(widget.productId);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          _showDeleteConfirmation(context, product.id),
                    ),
                  ],
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Badges
                          Row(
                            children: [
                              CustomBadge(
                                label: product.conditionLabel,
                                backgroundColor: product.isNew
                                    ? AppColors.success
                                    : AppColors.info,
                              ),
                              if (product.stockQuantity > 1) ...[
                                const SizedBox(width: 8),
                                CustomBadge(
                                  label: 'Stok: ${product.stockQuantity}',
                                  backgroundColor: AppColors.primary,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Title
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Price
                          Text(
                            Helpers.formatCurrency(product.price),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildStatItem(
                            Icons.inventory_2_outlined,
                            'Stok',
                            '${product.stockQuantity} unit',
                          ),
                          const SizedBox(width: 24),
                          _buildStatItem(
                            Icons.visibility_outlined,
                            'Dilihat',
                            '${product.viewsCount}x',
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Location
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  product.location,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Map Placeholder
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: AppColors.greyExtraLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.greyLight),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.map,
                                    size: 48,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Google Maps',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${product.latitude?.toStringAsFixed(4)}, Long: ${product.longitude?.toStringAsFixed(4)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Description
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Tags (if available)
                    if (product.tags != null && product.tags!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tags',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: product.tags!.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                    const Divider(height: 1),

                    // Reviews Section (Placeholder)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Rating & Ulasan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 20,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.5',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(12 ulasan)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.greyExtraLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Ulasan akan muncul di sini',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // Bottom Action Button
      bottomNavigationBar: Consumer<MarketplaceProvider>(
        builder: (context, provider, _) {
          final product = provider.selectedProduct;
          if (product == null) return const SizedBox.shrink();

          final isPenyedia = authProvider.user?.role == 'provider';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: product.isAvailable
                    ? () async {
                        if (isPenyedia) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MarketplaceFormScreen(
                                product: product,
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            context
                                .read<MarketplaceProvider>()
                                .fetchProductById(widget.productId);
                          }
                        } else {
                          _showPurchaseDialog(context, product);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  isPenyedia
                      ? 'Edit Produk'
                      : product.isAvailable
                          ? 'Beli Sekarang'
                          : 'Stok Habis',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    final isLocalFile =
        !imagePath.startsWith('http') && !imagePath.startsWith('https');

    if (isLocalFile && !kIsWeb) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.greyExtraLight,
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: AppColors.grey,
              ),
            ),
          );
        },
      );
    }

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.greyExtraLight,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: AppColors.grey,
            ),
          ),
        );
      },
    );
  }

void _showPurchaseDialog(BuildContext context, product) {
  final quantityController = TextEditingController(text: '1');
  int quantity = 1;
  double totalPrice = product.price;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Beli Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kondisi: ${product.condition}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stok tersedia: ${product.stockQuantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: product.stockQuantity > 5 
                        ? Colors.green 
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 24),
                
                // Quantity Input
                const Text(
                  'Jumlah',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Minus Button
                    IconButton(
                      onPressed: quantity > 1
                          ? () {
                              setDialogState(() {
                                quantity--;
                                quantityController.text = quantity.toString();
                                totalPrice = product.price * quantity;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    
                    // Quantity TextField
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          final parsedValue = int.tryParse(value);
                          if (parsedValue != null && 
                              parsedValue > 0 && 
                              parsedValue <= product.stockQuantity) {
                            setDialogState(() {
                              quantity = parsedValue;
                              totalPrice = product.price * quantity;
                            });
                          }
                        },
                      ),
                    ),
                    
                    // Plus Button
                    IconButton(
                      onPressed: quantity < product.stockQuantity
                          ? () {
                              setDialogState(() {
                                quantity++;
                                quantityController.text = quantity.toString();
                                totalPrice = product.price * quantity;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                
                // Validation Message
                if (quantity > product.stockQuantity) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Jumlah melebihi stok yang tersedia',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ],
                
                const Divider(height: 24),
                
                // Price Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Harga per item',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      Helpers.formatCurrency(product.price),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            Consumer2<AuthProvider, TransactionProvider>(
              builder: (context, auth, transactionProvider, child) {
                // Validate
                final isValid = quantity > 0 && 
                                quantity <= product.stockQuantity;
                
                return ElevatedButton(
                  onPressed: isValid
                      ? () async {
                          // Close dialog
                          Navigator.pop(context);
                          
                          // Show loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Memproses pembelian...'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.blue,
                            ),
                          );
                          
                          // Create transaction
                          final success = await transactionProvider.createTransaction(
                            productId: product.id!,
                            buyerId: auth.user!.id,
                            sellerId: product.sellerId,
                            quantity: quantity,
                            totalPrice: totalPrice,
                          );
                          
                          if (context.mounted) {
                            if (success) {
                              // Success
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Pembelian berhasil! Menunggu konfirmasi penjual.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else {
                              // Error
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '❌ ${transactionProvider.error ?? "Gagal memproses pembelian"}',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Beli Sekarang'),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}

  void _showDeleteConfirmation(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!context.mounted) return;

              Helpers.showLoadingDialog(context);

              try {
                final success =
                    await context.read<MarketplaceProvider>().deleteProduct(id);

                if (context.mounted) {
                  Helpers.hideLoadingDialog(context);

                  if (success) {
                    Helpers.showSnackbar(context, 'Produk berhasil dihapus');

                    await Future.delayed(const Duration(milliseconds: 300));
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    Helpers.showSnackbar(
                      context,
                      'Gagal menghapus produk',
                      isError: true,
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Helpers.hideLoadingDialog(context);
                  Helpers.showSnackbar(
                    context,
                    'Terjadi kesalahan: $e',
                    isError: true,
                  );
                }
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
