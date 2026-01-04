import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/residence_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/marketplace_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load all data for stats
    final residenceProvider = context.read<ResidenceProvider>();
    final activityProvider = context.read<ActivityProvider>();
    final marketplaceProvider = context.read<MarketplaceProvider>();

    if (residenceProvider.residences.isEmpty) {
      await residenceProvider.fetchResidences();
    }
    if (activityProvider.activities.isEmpty) {
      await activityProvider.fetchActivities();
    }
    if (marketplaceProvider.products.isEmpty) {
      await marketplaceProvider.fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isProvider = authProvider.isProvider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isProvider) ..._buildStudentDashboard(),
            if (isProvider) ..._buildProviderDashboard(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentDashboard() {
    return [
      const Text(
        'Dashboard Mahasiswa',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 24),

      // Stats Cards
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Booking',
              '0',
              Icons.home_work,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Kegiatan',
              '0',
              Icons.event,
              AppColors.activityPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Transaksi',
              '0',
              Icons.shopping_bag,
              AppColors.marketplacePrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Bookmark',
              '0',
              Icons.bookmark,
              AppColors.secondary,
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      const Text(
        'Riwayat Terbaru',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 16),

      _buildEmptyState(),
    ];
  }

  List<Widget> _buildProviderDashboard() {
    return [
      const Text(
        'Dashboard Penyedia',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 24),

      // Stats Cards with REAL DATA
      Consumer3<ResidenceProvider, ActivityProvider, MarketplaceProvider>(
        builder: (context, residenceProvider, activityProvider,
            marketplaceProvider, _) {
          final userId = context.read<AuthProvider>().user?.id ?? 0;

          // Filter by provider ID
          final myResidences = residenceProvider.residences
              .where((r) => r.providerId == userId)
              .length;
          final myActivities = activityProvider.activities
              .where((a) => a.providerId == userId)
              .length;
          final myProducts = marketplaceProvider.products
              .where((p) => p.sellerId == userId)
              .length;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Hunian',
                      myResidences.toString(),
                      Icons.home_work,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Kegiatan',
                      myActivities.toString(),
                      Icons.event,
                      AppColors.activityPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Produk',
                      myProducts.toString(),
                      Icons.store,
                      AppColors.marketplacePrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Booking',
                      '0',
                      Icons.list_alt,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),

      const SizedBox(height: 24),

      const Text(
        'Pending Approval',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 16),

      _buildEmptyState(),
    ];
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'Belum ada data',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}