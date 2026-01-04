import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/residence_provider.dart';
import '../../providers/auth_provider.dart';
import 'residence_detail_screen.dart';
import 'residence_form_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResidenceListScreen extends StatefulWidget {
  const ResidenceListScreen({Key? key}) : super(key: key);

  @override
  State<ResidenceListScreen> createState() => _ResidenceListScreenState();
}

class _ResidenceListScreenState extends State<ResidenceListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResidences();
    });
  }

  Future<void> _loadResidences() async {
    final auth = context.read<AuthProvider>();
    final residenceProvider = context.read<ResidenceProvider>();

    if (auth.isProvider && auth.user != null) {
      // Penyedia: hanya lihat miliknya
      await residenceProvider.fetchMyResidences(auth.user!.id);
    } else {
      // Mahasiswa: lihat semua
      await residenceProvider.fetchResidences();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isProvider = authProvider.isProvider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hunian'),
        // Di AppBar actions
        actions: [
          if (isProvider)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResidenceFormScreen(),
                  ),
                );

                // Refresh WAJIB setelah create
                if (result == true) {
                  if (mounted) {
                    // Tidak perlu fetch lagi karena sudah auto-update di provider
                    setState(() {}); // Trigger rebuild
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari hunian...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ResidenceProvider>().search('');
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
                    context.read<ResidenceProvider>().search(value);
                  },
                ),

                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Semua',
                        isSelected: true,
                        onTap: () {
                          context.read<ResidenceProvider>().clearFilters();
                        },
                      ),
                      _buildFilterChip(
                        label: 'Bulanan',
                        onTap: () {
                          context
                              .read<ResidenceProvider>()
                              .filterByRentalPeriod('monthly');
                        },
                      ),
                      _buildFilterChip(
                        label: 'Tahunan',
                        onTap: () {
                          context
                              .read<ResidenceProvider>()
                              .filterByRentalPeriod('yearly');
                        },
                      ),
                      _buildFilterChip(
                        label: '< 2 Juta',
                        onTap: () {
                          context
                              .read<ResidenceProvider>()
                              .filterByPrice(null, 2000000);
                        },
                      ),
                      _buildFilterChip(
                        label: '2-5 Juta',
                        onTap: () {
                          context
                              .read<ResidenceProvider>()
                              .filterByPrice(2000000, 5000000);
                        },
                      ),
                      _buildFilterChip(
                        label: '> 5 Juta',
                        onTap: () {
                          context
                              .read<ResidenceProvider>()
                              .filterByPrice(5000000, null);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Residence List
          Expanded(
            child: Consumer<ResidenceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
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
                          onPressed: () => provider.fetchResidences(),
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
                          Icons.home_work_outlined,
                          size: 64,
                          color: AppColors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada hunian',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hunian akan muncul di sini',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        if (isProvider) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResidenceFormScreen(),
                                ),
                              );

                              // Refresh setelah create - TAMBAH INI
                              if (result == true && mounted) {
                                context
                                    .read<ResidenceProvider>()
                                    .fetchResidences();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Hunian'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchResidences(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.residences.length,
                    itemBuilder: (context, index) {
                      final residence = provider.residences[index];
                      return _buildResidenceCard(
                          context, residence, isProvider);
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

  Widget _buildFilterChip({
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.greyLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResidenceCard(
    BuildContext context,
    residence,
    bool isProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResidenceDetailScreen(residenceId: residence.id),
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
                  child: Builder(
                    builder: (context) {
                      final imagePath = residence.images.isNotEmpty
                          ? residence.images[0]
                          : '';

                      // FIX: Check if local file or URL
                      final isLocalFile = imagePath.isNotEmpty &&
                          !imagePath.startsWith('http') &&
                          !imagePath.startsWith('https');

                      if (imagePath.isEmpty) {
                        return Container(
                          width: double.infinity,
                          height: 180,
                          color: AppColors.greyExtraLight,
                          child: const Icon(
                            Icons.home_work,
                            size: 64,
                            color: AppColors.grey,
                          ),
                        );
                      }

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
                              Icons.home_work,
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
                            Icons.home_work,
                            size: 64,
                            color: AppColors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Discount Badge
                if (residence.hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        residence.discountType == 'percentage'
                            ? '-${residence.discountValue?.toInt()}%'
                            : '-${Helpers.formatCurrency(residence.discountValue ?? 0)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Availability Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: residence.isAvailable
                          ? AppColors.success
                          : AppColors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      residence.isAvailable ? 'Tersedia' : 'Penuh',
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
                    residence.name,
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
                          residence.address,
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

                  // Facilities
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: residence.facilities
                        .take(3)
                        .map<Widget>((facility) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                facility,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // Price & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (residence.hasDiscount) ...[
                            Text(
                              Helpers.formatCurrency(residence.price),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            Helpers.formatCurrency(residence.finalPrice),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '/${residence.rentalPeriod == 'monthly' ? 'bulan' : 'tahun'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResidenceDetailScreen(
                                residenceId: residence.id,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Detail'),
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
}
