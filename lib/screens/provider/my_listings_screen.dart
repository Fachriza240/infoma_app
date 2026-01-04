import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/residence_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../residence/residence_detail_screen.dart';
import '../activity/activity_detail_screen.dart';
import '../marketplace/marketplace_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<ResidenceProvider>().fetchResidences(),
      context.read<ActivityProvider>().fetchActivities(),
      context.read<MarketplaceProvider>().fetchProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.id ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Hunian', icon: Icon(Icons.home_work)),
            Tab(text: 'Kegiatan', icon: Icon(Icons.event)),
            Tab(text: 'Produk', icon: Icon(Icons.shopping_bag)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResidenceTab(userId),
          _buildActivityTab(userId),
          _buildProductTab(userId),
        ],
      ),
    );
  }

  Widget _buildResidenceTab(int userId) {
    return Consumer<ResidenceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter by provider ID
        final myResidences =
            provider.residences.where((r) => r.providerId == userId).toList();

        if (myResidences.isEmpty) {
          return _buildEmptyState(
            'Belum ada hunian',
            'Tambahkan hunian pertama Anda',
            Icons.home_work_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchResidences(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myResidences.length,
            itemBuilder: (context, index) {
              final residence = myResidences[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.home_work,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    residence.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatCurrency(residence.finalPrice),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: residence.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              residence.isAvailable ? 'Tersedia' : 'Penuh',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${residence.availableSlots}/${residence.capacity} slot',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ResidenceDetailScreen(residenceId: residence.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(int userId) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter by provider ID
        final myActivities =
            provider.activities.where((a) => a.providerId == userId).toList();

        if (myActivities.isEmpty) {
          return _buildEmptyState(
            'Belum ada kegiatan',
            'Tambahkan kegiatan pertama Anda',
            Icons.event_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchActivities(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myActivities.length,
            itemBuilder: (context, index) {
              final activity = myActivities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.activityPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: AppColors.activityPrimary,
                    ),
                  ),
                  title: Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatCurrency(activity.finalPrice),
                        style: const TextStyle(
                          color: AppColors.activityPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: activity.isRegistrationOpen
                                  ? AppColors.success
                                  : AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activity.isRegistrationOpen ? 'Buka' : 'Tutup',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activity.availableSlots}/${activity.capacity} slot',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ActivityDetailScreen(activityId: activity.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductTab(int userId) {
    return Consumer<MarketplaceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter by seller ID
        final myProducts =
            provider.products.where((p) => p.sellerId == userId).toList();

        if (myProducts.isEmpty) {
          return _buildEmptyState(
            'Belum ada produk',
            'Tambahkan produk pertama Anda',
            Icons.shopping_bag_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchProducts(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myProducts.length,
            itemBuilder: (context, index) {
              final product = myProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          AppColors.marketplacePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: AppColors.marketplacePrimary,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatCurrency(product.price),
                        style: const TextStyle(
                          color: AppColors.marketplacePrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: product.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isAvailable ? 'Aktif' : 'Habis',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stok: ${product.stockQuantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MarketplaceDetailScreen(productId: product.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
