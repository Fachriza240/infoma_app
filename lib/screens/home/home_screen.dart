import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../residence/residence_list_screen.dart';
import '../activity/activity_list_screen.dart';
import '../marketplace/marketplace_list_screen.dart';
import '../bookmark/my_bookmarks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isProvider = authProvider.isProvider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('InfoMA'),
        actions: [
          // Notification Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            _buildWelcomeCard(user?.name ?? 'User', isProvider),

            const SizedBox(height: 24),

            // Quick Access Section
            if (!isProvider) ...[
              _buildSectionTitle('Layanan'),
              const SizedBox(height: 16),
              _buildServiceGrid(context),
              const SizedBox(height: 24),
            ],

            if (isProvider) ...[
              _buildSectionTitle('Kelola Layanan'),
              const SizedBox(height: 16),
              _buildProviderServiceGrid(context),
              const SizedBox(height: 24),
            ],

            // Recent Activities (placeholder)
            _buildSectionTitle('Aktivitas Terbaru'),
            const SizedBox(height: 16),
            _buildEmptyState('Belum ada aktivitas'),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name, bool isProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isProvider ? 'PENYEDIA' : 'MAHASISWA',
                  style: const TextStyle(
                    color: AppColors.textOnSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat Datang,',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isProvider
                ? 'Kelola layanan Anda dengan mudah'
                : 'Temukan hunian, kegiatan, dan produk terbaik',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    final services = [
      {
        'icon': Icons.home_work,
        'title': 'Hunian',
        'subtitle': 'Kos & Apartemen',
        'color': AppColors.primary,
        'route': '/residence',
      },
      {
        'icon': Icons.event,
        'title': 'Kegiatan',
        'subtitle': 'Seminar & Workshop',
        'color': AppColors.activityPrimary,
        'route': '/activity',
      },
      {
        'icon': Icons.shopping_bag,
        'title': 'Marketplace',
        'subtitle': 'Jual Beli Barang',
        'color': AppColors.marketplacePrimary,
        'route': '/marketplace',
      },
      {
        'icon': Icons.bookmark,
        'title': 'Bookmark',
        'subtitle': 'Simpanan Saya',
        'color': AppColors.secondary,
        'route': '/bookmark',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(
          context,
          icon: service['icon'] as IconData,
          title: service['title'] as String,
          subtitle: service['subtitle'] as String,
          color: service['color'] as Color,
          onTap: () {
            // Navigate based on service
            if (service['title'] == 'Hunian') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResidenceListScreen()),
              );
            } else if (service['title'] == 'Kegiatan') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityListScreen()),
              );
            } else if (service['title'] == 'Marketplace') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MarketplaceListScreen()),
              );
            } else if (service['title'] == 'Bookmark') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBookmarksScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${service['title']} akan segera hadir!'),
                  backgroundColor: AppColors.info,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildProviderServiceGrid(BuildContext context) {
    final services = [
      {
        'icon': Icons.home_work,
        'title': 'Hunian',
        'subtitle': 'Kelola Hunian',
        'color': AppColors.primary,
        'route': '/provider/residence',
      },
      {
        'icon': Icons.event,
        'title': 'Kegiatan',
        'subtitle': 'Kelola Kegiatan',
        'color': AppColors.activityPrimary,
        'route': '/provider/activity',
      },
      {
        'icon': Icons.store,
        'title': 'Produk',
        'subtitle': 'Kelola Produk',
        'color': AppColors.marketplacePrimary,
        'route': '/provider/marketplace',
      },
      {
        'icon': Icons.list_alt,
        'title': 'Booking',
        'subtitle': 'Kelola Booking',
        'color': AppColors.secondary,
        'route': '/provider/booking',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(
          context,
          icon: service['icon'] as IconData,
          title: service['title'] as String,
          subtitle: service['subtitle'] as String,
          color: service['color'] as Color,
          onTap: () {
            // Navigate based on service
            if (service['title'] == 'Hunian') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResidenceListScreen()),
              );
            } else if (service['title'] == 'Kegiatan') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityListScreen()),
              );
            } else if (service['title'] == 'Produk') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MarketplaceListScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${service['title']} akan segera hadir!'),
                  backgroundColor: AppColors.info,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.greyLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.greyExtraLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
