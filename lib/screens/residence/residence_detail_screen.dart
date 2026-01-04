import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_badge.dart';
import '../../core/utils/helpers.dart';
import '../../providers/residence_provider.dart';
import '../../providers/auth_provider.dart';
import 'residence_form_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/bookmark_provider.dart';

class ResidenceDetailScreen extends StatefulWidget {
  final int residenceId;

  const ResidenceDetailScreen({
    Key? key,
    required this.residenceId,
  }) : super(key: key);

  @override
  State<ResidenceDetailScreen> createState() => _ResidenceDetailScreenState();
}

class _ResidenceDetailScreenState extends State<ResidenceDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResidenceProvider>().fetchResidenceById(widget.residenceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isProvider = authProvider.isProvider;

    return Scaffold(
      body: Consumer<ResidenceProvider>(
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
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          final residence = provider.selectedResidence;
          if (residence == null) {
            return const Center(child: Text('Hunian tidak ditemukan'));
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Carousel
                      PageView.builder(
                        itemCount: residence.images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final imagePath = residence.images[index];

                          // FIX: Check if it's a local file path or URL
                          final isLocalFile = !imagePath.startsWith('http') &&
                              !imagePath.startsWith('https');

                          if (isLocalFile && !kIsWeb) {
                            // Local file - use Image.file
                            return Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.greyExtraLight,
                                child: const Icon(
                                  Icons.home_work,
                                  size: 64,
                                  color: AppColors.grey,
                                ),
                              ),
                            );
                          } else {
                            // Network URL - use Image.network
                            return Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.greyExtraLight,
                                child: const Icon(
                                  Icons.home_work,
                                  size: 64,
                                  color: AppColors.grey,
                                ),
                              ),
                            );
                          }
                        },
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
                      if (residence.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              residence.images.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? AppColors.white
                                      : AppColors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  // Bookmark Button (for students)
                  if (!isProvider)
                    Consumer2<AuthProvider, BookmarkProvider>(
                      builder: (context, auth, bookmarkProvider, child) {
                        if (auth.user == null) return const SizedBox.shrink();

                        final isBookmarked = bookmarkProvider.isBookmarked(
                          'residence',
                          widget.residenceId,
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
                              type: 'residence',
                              itemId: widget.residenceId,
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

                  // Edit Button (for provider)
                  if (isProvider)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResidenceFormScreen(
                              residence: residence,
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          context
                              .read<ResidenceProvider>()
                              .fetchResidenceById(widget.residenceId);
                        }
                      },
                    ),

                  // More Menu
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 12),
                            Text('Bagikan'),
                          ],
                        ),
                      ),
                      if (isProvider)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  size: 20, color: AppColors.error),
                              SizedBox(width: 12),
                              Text('Hapus',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      if (value == 'share') {
                        Helpers.showSnackbar(
                            context, 'Fitur bagikan akan segera hadir');
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, residence.id);
                      }
                    },
                  ),
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
                              // JADI (pakai CustomBadge):
                              CustomBadge(
                                label: residence.isAvailable
                                    ? 'Tersedia'
                                    : 'Penuh',
                                backgroundColor: residence.isAvailable
                                    ? AppColors.success
                                    : AppColors.grey,
                              ),
                              if (residence.hasDiscount) ...[
                                const SizedBox(width: 8),
                                CustomBadge(
                                  label: residence.discountType == 'percentage'
                                      ? 'Diskon ${residence.discountValue?.toInt()}%'
                                      : 'Diskon ${Helpers.formatCurrency(residence.discountValue ?? 0)}',
                                  backgroundColor: AppColors.error,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Title
                          Text(
                            residence.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  residence.address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Price
                          Row(
                            children: [
                              if (residence.hasDiscount) ...[
                                Text(
                                  Helpers.formatCurrency(residence.price),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                Helpers.formatCurrency(residence.finalPrice),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                ' /${residence.rentalPeriod == 'monthly' ? 'bulan' : 'tahun'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
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
                            Icons.meeting_room,
                            'Kapasitas',
                            '${residence.capacity} orang',
                          ),
                          const SizedBox(width: 24),
                          _buildStatItem(
                            Icons.door_front_door,
                            'Tersedia',
                            '${residence.availableSlots} slot',
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
                            residence.description,
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

                    // Facilities
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fasilitas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: residence.facilities.map((facility) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      facility,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Location Map (Placeholder)
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
                          Container(
                            height: 200,
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
                                    'Lat: ${residence.latitude?.toStringAsFixed(4)}, Long: ${residence.longitude?.toStringAsFixed(4)}',
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
                                    '(24 ulasan)',
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
      bottomNavigationBar: Consumer<ResidenceProvider>(
        builder: (context, provider, _) {
          final residence = provider.selectedResidence;
          if (residence == null) return const SizedBox.shrink();

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
                onPressed: residence.isAvailable
                    ? () async {
                        if (isProvider) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResidenceFormScreen(
                                residence: residence,
                              ),
                            ),
                          );

                          // Refresh setelah edit - TAMBAH INI
                          if (result == true && mounted) {
                            context
                                .read<ResidenceProvider>()
                                .fetchResidenceById(widget.residenceId);
                          }
                        } else {
                          _showBookingDialog(context, residence);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  isProvider
                      ? 'Edit Hunian'
                      : residence.isAvailable
                          ? 'Booking Sekarang'
                          : 'Tidak Tersedia',
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

  void _showBookingDialog(BuildContext context, residence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Hunian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anda akan booking:'),
            const SizedBox(height: 8),
            Text(
              residence.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text('Harga: ${Helpers.formatCurrency(residence.finalPrice)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackbar(
                context,
                'Fitur booking akan segera hadir!',
              );
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Hunian'),
        content: const Text('Apakah Anda yakin ingin menghapus hunian ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);

              // FIX: Check if context still valid
              if (!context.mounted) return;

              // Show loading
              Helpers.showLoadingDialog(context);

              try {
                // Perform delete
                final success =
                    await context.read<ResidenceProvider>().deleteResidence(id);

                // FIX: Always hide loading, even if error
                if (context.mounted) {
                  Helpers.hideLoadingDialog(context);

                  if (success) {
                    Helpers.showSnackbar(context, 'Hunian berhasil dihapus');

                    // FIX: Pop with delay to ensure dialog is closed
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (context.mounted) {
                      Navigator.pop(context); // Back to list
                    }
                  } else {
                    Helpers.showSnackbar(
                      context,
                      'Gagal menghapus hunian',
                      isError: true,
                    );
                  }
                }
              } catch (e) {
                // FIX: Handle error properly
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
