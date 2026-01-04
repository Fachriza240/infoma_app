import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/activity_model.dart';
import '../../core/constants/app_colors.dart';

class ActivityFormScreen extends StatefulWidget {
  final ActivityModel? activity;

  const ActivityFormScreen({
    super.key,
    this.activity,
  });

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _discountValueController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<String> _imageUrls = [];
  List<File> _newImages = [];

  DateTime? _selectedDate;
  String? _selectedDiscountType;

  bool get _isEdit => widget.activity != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final activity = widget.activity!;
    _nameController.text = activity.name;
    _descriptionController.text = activity.description;
    _locationController.text = activity.location;
    _priceController.text = activity.price.toStringAsFixed(0);
    _capacityController.text = activity.capacity.toString();
    _selectedDate = activity.eventDate;
    _imageUrls = List.from(activity.images);

    if (activity.discountType != null && activity.discountValue != null) {
      _selectedDiscountType = activity.discountType;
      _discountValueController.text =
          activity.discountValue!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _newImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal kegiatan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_imageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal tambahkan 1 gambar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final activityProvider = context.read<ActivityProvider>();

      // Prepare images
      final List<String> allImages = [
        ..._imageUrls,
        ..._newImages.map((file) => file.path),
      ];

      // Create/Update activity model
      final activity = ActivityModel(
        id: _isEdit
            ? widget.activity!.id
            : DateTime.now().millisecondsSinceEpoch,
        providerId: authProvider.user?.id ?? 0,
        categoryId: 1, // TODO: Add category selection
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        latitude: -6.9147, // TODO: Add location picker
        longitude: 107.6098,
        eventDate: _selectedDate!,
        registrationDeadline: _selectedDate!.subtract(const Duration(days: 1)),
        price: double.parse(_priceController.text),
        capacity: int.parse(_capacityController.text),
        availableSlots: _isEdit
            ? widget.activity!.availableSlots
            : int.parse(_capacityController.text),
        images: allImages,
        discountType: _selectedDiscountType,
        discountValue: _discountValueController.text.isNotEmpty
            ? double.tryParse(_discountValueController.text)
            : null,
        isActive: true,
        createdAt: _isEdit ? widget.activity!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_isEdit) {
        success = await activityProvider.updateActivity(activity);
      } else {
        success = await activityProvider.createActivity(activity);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEdit
                    ? 'Kegiatan berhasil diupdate'
                    : 'Kegiatan berhasil ditambahkan',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                activityProvider.errorMessage ?? 'Terjadi kesalahan',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images Section
            const Text(
              'Foto Kegiatan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Existing Images (from URL)
            if (_imageUrls.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _imageUrls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return _buildImagePreview(
                    isUrl: true,
                    urlOrPath: url,
                    onRemove: () => _removeExistingImage(index),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // New Images (from File)
            if (_newImages.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _newImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return _buildImagePreview(
                    isUrl: false,
                    urlOrPath: file.path,
                    onRemove: () => _removeNewImage(index),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Add Image Button
            OutlinedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Tambah Foto'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kegiatan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama kegiatan tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Event Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Kegiatan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Pilih tanggal'
                      : _formatDate(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lokasi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lokasi tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Capacity
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Kapasitas Peserta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kapasitas tidak boleh kosong';
                }
                if (int.tryParse(value) == null) {
                  return 'Kapasitas harus berupa angka';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga (0 untuk gratis)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harga tidak boleh kosong';
                }
                if (double.tryParse(value) == null) {
                  return 'Harga harus berupa angka';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Discount Section
            const Text(
              'Diskon (Opsional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dropdown Tipe Diskon
                DropdownButtonFormField<String>(
                  value: _selectedDiscountType,
                  decoration: InputDecoration(
                    labelText: 'Tipe Diskon',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Tidak ada diskon'),
                    ),
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Persentase (%)'),
                    ),
                    DropdownMenuItem(
                      value: 'flat',
                      child: Text('Nominal (Rp)'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDiscountType = value;
                      if (value == null) {
                        _discountValueController.clear();
                      }
                    });
                  },
                ),

                // Nilai Diskon (conditional)
                if (_selectedDiscountType != null) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discountValueController,
                    decoration: InputDecoration(
                      labelText: 'Nilai Diskon',
                      hintText: _selectedDiscountType == 'percentage'
                          ? 'Contoh: 10'
                          : 'Contoh: 100000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.discount),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_selectedDiscountType != null) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Harus angka';
                        }
                        if (_selectedDiscountType == 'percentage') {
                          final percent = double.parse(value);
                          if (percent < 0 || percent > 100) {
                            return 'Persentase harus 0-100';
                          }
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Submit Button
            Consumer<ActivityProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Kegiatan' : 'Tambah Kegiatan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview({
    required bool isUrl,
    required String urlOrPath,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUrl
                ? Image.network(
                    urlOrPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.greyExtraLight,
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : Image.file(
                    File(urlOrPath),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
