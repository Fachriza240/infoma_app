import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/activity_model.dart';
import '../../core/constants/app_colors.dart';
import 'activity_detail_screen.dart';
import 'activity_form_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    'Gratis',
    'Berbayar',
    '< 100rb',
    '100rb - 500rb',
    '> 500rb',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
    });
  }

  Future<void> _loadActivities() async {
    final auth = context.read<AuthProvider>();
    final activityProvider = context.read<ActivityProvider>();

    if (auth.isProvider && auth.user != null) {
      // Penyedia: hanya lihat miliknya
      await activityProvider.fetchMyActivities(auth.user!.id);
    } else {
      // Mahasiswa: lihat semua
      await activityProvider.fetchActivities();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final provider = context.read<ActivityProvider>();

    if (_selectedFilter == 'Semua') {
      provider.filterByPrice(null, null);
    } else if (_selectedFilter == 'Gratis') {
      provider.filterByPrice(0, 0);
    } else if (_selectedFilter == 'Berbayar') {
      provider.filterByPrice(1, null);
    } else if (_selectedFilter == '< 100rb') {
      provider.filterByPrice(null, 100000);
    } else if (_selectedFilter == '100rb - 500rb') {
      provider.filterByPrice(100000, 500000);
    } else if (_selectedFilter == '> 500rb') {
      provider.filterByPrice(500000, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPenyedia = authProvider.user?.role == 'provider';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kegiatan Kampus'),
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
                    builder: (context) => const ActivityFormScreen(),
                  ),
                );

                if (result == true && context.mounted) {
                  context.read<ActivityProvider>().fetchActivities();
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
                hintText: 'Cari kegiatan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ActivityProvider>().search('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                context.read<ActivityProvider>().search(value);
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

          // Activities List
          Expanded(
            child: Consumer<ActivityProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada kegiatan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchActivities(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.activities.length,
                    itemBuilder: (context, index) {
                      final activity = provider.activities[index];
                      return _ActivityCard(
                        activity: activity,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityDetailScreen(
                                activityId: activity.id,
                              ),
                            ),
                          );
                        },
                      );
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
}

class _ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: _buildImage(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badges
                  Row(
                    children: [
                      if (!activity.isRegistrationOpen)
                        const _Badge(
                          label: 'Tutup',
                          color: Colors.red,
                        )
                      else if (activity.isUpcoming)
                        const _Badge(
                          label: 'Segera',
                          color: AppColors.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Date & Location
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(activity.eventDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price & Capacity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activity.hasDiscount) ...[
                            Text(
                              _formatPrice(activity.price),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            _formatPrice(activity.finalPrice),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),

                      // Capacity
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${activity.availableSlots} slot',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildImage() {
    if (activity.images.isEmpty) {
      return Container(
        height: 180,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.event,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    final imagePath = activity.images[0];
    final isLocalFile =
        !imagePath.startsWith('http') && !imagePath.startsWith('https');

    if (isLocalFile && !kIsWeb) {
      return Image.file(
        File(imagePath),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
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
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 180,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatPrice(double price) {
    if (price == 0) return 'GRATIS';
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
