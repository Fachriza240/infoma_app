import 'package:flutter/material.dart';
import '../data/models/booking_model.dart';
import '../data/local/database_helper.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  List<BookingModel> _filteredBookings = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  // Database Helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Getters
  List<BookingModel> get bookings => _filteredBookings;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _filteredBookings.isNotEmpty;

  // Count by status
  int get pendingCount => _bookings.where((b) => b.status == 'pending').length;
  int get approvedCount =>
      _bookings.where((b) => b.status == 'approved').length;
  int get completedCount =>
      _bookings.where((b) => b.status == 'completed').length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Generate booking code
  String _generateBookingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final bookingCode =
        List.generate(8, (_) => chars[random.nextInt(chars.length)])
            .join()
            .toUpperCase();
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'BK-$timestamp-$bookingCode';
  }

  /// Initialize - Load user's bookings
  Future<void> initialize(int userId) async {
    try {
      print('🔵 BookingProvider: Initializing...');
      await fetchMyBookings(userId);
      print('✅ Bookings loaded');
    } catch (e) {
      print('❌ Error initializing: $e');
      _setError('Failed to initialize: $e');
    }
  }

  /// Create new booking
  Future<void> createBooking({
    required int residenceId,
    required int userId,
    required int providerId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required List<String> documents,
    required String notes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Validasi tanggal
      if (checkOutDate.isBefore(checkInDate)) {
        _setError('Tanggal checkout harus setelah check-in');
        _setLoading(false);
        return;
      }

      // Generate booking code
      final bookingCode = _generateBookingCode();

      // Create model
      final booking = BookingModel(
        id: 0, // Auto-increment
        residenceId: residenceId,
        userId: userId,
        providerId: providerId,
        bookingCode: bookingCode,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        documents: documents,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notes,
      );

      // Convert to database format
      final Map<String, dynamic> dbData = {
        'residence_id': booking.residenceId,
        'user_id': booking.userId,
        'provider_id': booking.providerId,
        'booking_code': booking.bookingCode,
        'check_in_date': DateFormat('yyyy-MM-dd').format(booking.checkInDate),
        'check_out_date': DateFormat('yyyy-MM-dd').format(booking.checkOutDate),
        'documents': booking.documents.join(','),
        'status': booking.status,
        'notes': booking.notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert to SQLite
      final id = await _dbHelper.insert('bookings', dbData);
      print('✅ Booking created: $bookingCode (ID: $id)');

      // Add to local list
      booking.id = id;
      _bookings.add(booking);
      _filteredBookings = List.from(_bookings);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error creating booking: $e');
      _setError('Gagal membuat booking: $e');
      _setLoading(false);
    }
  }

  /// Fetch user's bookings
  Future<void> fetchMyBookings(int userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final List<Map<String, dynamic>> maps = await _dbHelper.queryWhere(
        'bookings',
        'user_id = ?',
        [userId],
      );

      _bookings = maps.map((map) => BookingModel.fromDatabase(map)).toList();
      _filteredBookings = List.from(_bookings);

      print('✅ Loaded ${_bookings.length} bookings for user $userId');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      _setError('Gagal memuat booking: $e');
      _setLoading(false);
    }
  }

  /// Fetch provider's incoming bookings
  Future<void> fetchIncomingBookings(int providerId) async {
    try {
      _setLoading(true);
      _setError(null);

      final List<Map<String, dynamic>> maps = await _dbHelper.queryWhere(
        'bookings',
        'provider_id = ?',
        [providerId],
      );

      _bookings = maps.map((map) => BookingModel.fromDatabase(map)).toList();
      _filteredBookings = List.from(_bookings);

      print(
          '✅ Loaded ${_bookings.length} incoming bookings for provider $providerId');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching incoming bookings: $e');
      _setError('Gagal memuat booking: $e');
      _setLoading(false);
    }
  }

  /// Get booking by ID
  Future<void> fetchBookingById(int bookingId) async {
    try {
      _setLoading(true);

      final map = await _dbHelper.queryById('bookings', bookingId);

      if (map != null) {
        _selectedBooking = BookingModel.fromDatabase(map);
        print('✅ Booking loaded: ${_selectedBooking?.bookingCode}');
      } else {
        _setError('Booking tidak ditemukan');
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching booking: $e');
      _setError('Gagal memuat detail booking: $e');
      _setLoading(false);
    }
  }

  /// Update booking status (for provider)
  Future<void> updateBookingStatus(
    int bookingId,
    String newStatus, {
    String? rejectionReason,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final Map<String, dynamic> updateData = {
        'status': newStatus,
        'rejection_reason': rejectionReason,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _dbHelper.update('bookings', updateData, bookingId);

      // Update local list
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final booking = _bookings[index];
        _bookings[index] = BookingModel(
          id: booking.id,
          residenceId: booking.residenceId,
          userId: booking.userId,
          providerId: booking.providerId,
          bookingCode: booking.bookingCode,
          checkInDate: booking.checkInDate,
          checkOutDate: booking.checkOutDate,
          documents: booking.documents,
          status: newStatus,
          rejectionReason: rejectionReason,
          notes: booking.notes,
          createdAt: booking.createdAt,
          updatedAt: DateTime.now(),
        );
        _filteredBookings = List.from(_bookings);
      }

      print('✅ Booking status updated to $newStatus');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error updating booking: $e');
      _setError('Gagal memperbarui booking: $e');
      _setLoading(false);
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(int bookingId) async {
    try {
      _setLoading(true);
      _setError(null);

      final Map<String, dynamic> updateData = {
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _dbHelper.update('bookings', updateData, bookingId);

      // Update local list
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final booking = _bookings[index];
        _bookings[index] = BookingModel(
          id: booking.id,
          residenceId: booking.residenceId,
          userId: booking.userId,
          providerId: booking.providerId,
          bookingCode: booking.bookingCode,
          checkInDate: booking.checkInDate,
          checkOutDate: booking.checkOutDate,
          documents: booking.documents,
          status: 'cancelled',
          notes: booking.notes,
          createdAt: booking.createdAt,
          updatedAt: DateTime.now(),
        );
        _filteredBookings = List.from(_bookings);
      }

      print('✅ Booking cancelled');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      _setError('Gagal membatalkan booking: $e');
      _setLoading(false);
    }
  }

  /// Delete booking
  Future<void> deleteBooking(int bookingId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _dbHelper.delete('bookings', bookingId);

      _bookings.removeWhere((b) => b.id == bookingId);
      _filteredBookings = List.from(_bookings);

      print('✅ Booking deleted');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting booking: $e');
      _setError('Gagal menghapus booking: $e');
      _setLoading(false);
    }
  }

  /// Filter by status
  void filterByStatus(String status) {
    if (status == 'all') {
      _filteredBookings = List.from(_bookings);
    } else {
      _filteredBookings = _bookings.where((b) => b.status == status).toList();
    }
    notifyListeners();
  }

  /// Get count by status
  int getCountByStatus(String status) {
    if (status == 'all') {
      return _bookings.length;
    }
    return _bookings.where((b) => b.status == status).length;
  }
}
