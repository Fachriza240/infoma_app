import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/auth_provider.dart';
import '../residence/residence_detail_screen.dart';
import '../activity/activity_detail_screen.dart';
import '../marketplace/marketplace_detail_screen.dart';

class MyBookmarksScreen extends StatefulWidget {
  const MyBookmarksScreen({Key? key}) : super(key: key);

  @override
  State<MyBookmarksScreen> createState() => _MyBookmarksScreenState();
}

class _MyBookmarksScreenState extends State<MyBookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final auth = context.read<AuthProvider>();
    final bookmark = context.read<BookmarkProvider>();

    if (auth.user != null) {
      await bookmark.loadBookmarks(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bookmark Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hunian'),
            Tab(text: 'Kegiatan'),
            Tab(text: 'Marketplace'),
          ],
        ),
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmark, child) {
          if (bookmark.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadBookmarks,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Hunian
                _buildResidenceTab(bookmark),
                // Tab Kegiatan
                _buildActivityTab(bookmark),
                // Tab Marketplace
                _buildMarketplaceTab(bookmark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResidenceTab(BookmarkProvider bookmark) {
    if (bookmark.bookmarkedResidences.isEmpty) {
      return _buildEmptyState('Belum ada hunian yang di-bookmark');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmark.bookmarkedResidences.length,
      itemBuilder: (context, index) {
        final residence = bookmark.bookmarkedResidences[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ResidenceDetailScreen(residenceId: residence.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      residence.images.first,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.home, size: 40),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          residence.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                residence.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Helpers.formatCurrency(residence.finalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remove bookmark button
                  IconButton(
                    icon:
                        const Icon(Icons.bookmark, color: AppColors.secondary),
                    onPressed: () => _removeBookmark(
                      'residence',
                      residence.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(BookmarkProvider bookmark) {
    if (bookmark.bookmarkedActivities.isEmpty) {
      return _buildEmptyState('Belum ada kegiatan yang di-bookmark');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmark.bookmarkedActivities.length,
      itemBuilder: (context, index) {
        final activity = bookmark.bookmarkedActivities[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ActivityDetailScreen(activityId: activity.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      activity.images.first,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.event, size: 40),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${activity.eventDate.day}/${activity.eventDate.month}/${activity.eventDate.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activity.price == 0
                              ? 'GRATIS'
                              : Helpers.formatCurrency(activity.finalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remove bookmark button
                  IconButton(
                    icon:
                        const Icon(Icons.bookmark, color: AppColors.secondary),
                    onPressed: () => _removeBookmark(
                      'activity',
                      activity.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketplaceTab(BookmarkProvider bookmark) {
    if (bookmark.bookmarkedProducts.isEmpty) {
      return _buildEmptyState('Belum ada produk yang di-bookmark');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmark.bookmarkedProducts.length,
      itemBuilder: (context, index) {
        final product = bookmark.bookmarkedProducts[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MarketplaceDetailScreen(productId: product.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.images.first,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.shopping_bag, size: 40),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.conditionLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Helpers.formatCurrency(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remove bookmark button
                  IconButton(
                    icon:
                        const Icon(Icons.bookmark, color: AppColors.secondary),
                    onPressed: () => _removeBookmark(
                      'marketplace',
                      product.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBookmark(String type, int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Bookmark'),
        content: const Text('Apakah Anda yakin ingin menghapus bookmark ini?'),
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

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final bookmark = context.read<BookmarkProvider>();

      await bookmark.toggleBookmark(
        userId: auth.user!.id,
        type: type,
        itemId: itemId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
