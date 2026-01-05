import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_badge.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/residence_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _selectedStatus =
          ['all', 'pending', 'approved', 'completed'][_tabController.index];
    });
    context.read<BookingProvider>().filterByStatus(_selectedStatus);
  }

  Future<void> _loadBookings() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      await context
          .read<BookingProvider>()
          .fetchMyBookings(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Consumer<BookingProvider>(
                builder: (context, provider, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Semua'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tabController.index == 0
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${provider.bookings.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _tabController.index == 0
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Tab(
              child: Consumer<BookingProvider>(
                builder: (context, provider, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Menunggu'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${provider.pendingCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _tabController.index == 1
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Tab(
              child: Consumer<BookingProvider>(
                builder: (context, provider, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Disetujui'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tabController.index == 2
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${provider.approvedCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _tabController.index == 2
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Tab(
              child: Consumer<BookingProvider>(
                builder: (context, provider, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Selesai'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tabController.index == 3
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${provider.completedCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _tabController.index == 3
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList('all'),
          _buildBookingList('pending'),
          _buildBookingList('approved'),
          _buildBookingList('completed'),
        ],
      ),
    );
  }

  Widget _buildBookingList(String status) {
    return Consumer2<BookingProvider, ResidenceProvider>(
      builder: (context, bookingProvider, residenceProvider, _) {
        final bookings = status == 'all'
            ? bookingProvider.bookings
            : bookingProvider.bookings
                .where((b) => b.status == status)
                .toList();

        if (bookingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tidak ada pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadBookings,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final residence = residenceProvider.residences.firstWhere(
                  (r) => r.id == booking.residenceId,
                  orElse: () => residenceProvider.residences.first);

              return BookingCard(
                booking: booking,
                residence: residence,
                onCancel: booking.isPending || booking.isApproved
                    ? () => _showCancelDialog(booking)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showCancelDialog(dynamic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              context.read<BookingProvider>().cancelBooking(booking.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesanan dibatalkan'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}

// Booking Card Widget
class BookingCard extends StatelessWidget {
  final dynamic booking;
  final dynamic residence;
  final VoidCallback? onCancel;

  const BookingCard({
    Key? key,
    required this.booking,
    required this.residence,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header dengan status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.bookingCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        residence.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CustomBadge(
                  label: booking.statusLabel,
                  backgroundColor: booking.statusColor,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: AppColors.border),

          // Booking Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.formattedCheckIn} - ${booking.formattedCheckOut}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.nights_stay,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.durationDays} Malam',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          if (onCancel != null) ...[
            Container(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.close, color: AppColors.error),
                      label: const Text(
                        'Batalkan',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Show booking details
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Detail'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
