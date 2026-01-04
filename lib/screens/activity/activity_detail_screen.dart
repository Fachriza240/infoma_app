import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/activity_model.dart';
import '../../core/constants/app_colors.dart';
import 'activity_form_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/bookmark_provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/custom_badge.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().fetchActivityById(widget.activityId);
    });
  }

  void _showRegistrationDialog(BuildContext context, ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Registrasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kegiatan: ${activity.name}'),
            const SizedBox(height: 8),
            Text('Tanggal: ${_formatDate(activity.eventDate)}'),
            const SizedBox(height: 8),
            Text(
              'Biaya: ${_formatPrice(activity.finalPrice)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apakah Anda yakin ingin mendaftar?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registrasi berhasil! (Mock)'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, ActivityModel activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kegiatan'),
        content: Text('Yakin ingin menghapus "${activity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<ActivityProvider>().deleteActivity(activity.id);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kegiatan berhasil dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus kegiatan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPenyedia = authProvider.user?.role == 'provider';

    return Scaffold(
      body: Consumer<ActivityProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Detail Kegiatan'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final activity = provider.selectedActivity;
          if (activity == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Detail Kegiatan'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: const Center(
                child: Text('Kegiatan tidak ditemukan'),
              ),
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
                      if (activity.images.isNotEmpty)
                        PageView.builder(
                          itemCount: activity.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildImage(activity.images[index]);
                          },
                        )
                      else
                        Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.event,
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
                      if (activity.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              activity.images.length,
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
                          'activity',
                          widget.activityId,
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
                              type: 'activity',
                              itemId: widget.activityId,
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityFormScreen(
                              activity: activity,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          _showDeleteConfirmation(context, activity),
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
                              if (!activity.isRegistrationOpen)
                                const CustomBadge(
                                  label: 'Tutup',
                                  backgroundColor: Colors.red,
                                )
                              else if (activity.isUpcoming)
                                const CustomBadge(
                                  label: 'Segera',
                                  backgroundColor: AppColors.success,
                                ),
                              if (activity.hasDiscount) ...[
                                const SizedBox(width: 8),
                                CustomBadge(
                                  label: activity.discountType == 'percentage'
                                      ? 'Diskon ${activity.discountValue?.toStringAsFixed(0)}%'
                                      : 'Diskon Rp ${(activity.discountValue ?? 0).toStringAsFixed(0)}',
                                  backgroundColor: Colors.red,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Title
                          Text(
                            activity.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Stats Cards
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.calendar_today,
                                  label: 'Tanggal',
                                  value: _formatDate(activity.eventDate),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.people,
                                  label: 'Peserta',
                                  value:
                                      '${activity.capacity - activity.availableSlots}/${activity.capacity}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Price
                          const Text(
                            'Biaya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (activity.hasDiscount) ...[
                                Text(
                                  _formatPrice(activity.price),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _formatPrice(activity.finalPrice),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                  activity.location,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Map Placeholder
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Map akan ditampilkan di sini',
                                    style: TextStyle(color: Colors.grey),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activity.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Rating Placeholder
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rating & Ulasan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada rating',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ActivityProvider>(
        builder: (context, provider, _) {
          final activity = provider.selectedActivity;
          final isPenyedia = authProvider.user?.role == 'provider';

          if (activity == null || isPenyedia || !activity.isRegistrationOpen) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _showRegistrationDialog(context, activity),
            backgroundColor: AppColors.secondary,
            icon: const Icon(Icons.how_to_reg, color: AppColors.primary),
            label: const Text(
              'Daftar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
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
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.grey,
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
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatPrice(double price) {
    if (price == 0) return 'GRATIS';
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
