import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/residence_model.dart';
import '../../providers/residence_provider.dart';
import '../../providers/auth_provider.dart';

class ResidenceFormScreen extends StatefulWidget {
  final ResidenceModel? residence;

  const ResidenceFormScreen({
    Key? key,
    this.residence,
  }) : super(key: key);

  @override
  State<ResidenceFormScreen> createState() => _ResidenceFormScreenState();
}

class _ResidenceFormScreenState extends State<ResidenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _availableSlotsController = TextEditingController();
  final _facilityController = TextEditingController();
  final _discountValueController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<String> _imageUrls = [];
  List<File> _newImages = [];

  String _selectedRentalPeriod = 'monthly';
  String? _selectedDiscountType;
  List<String> _facilities = [];

  bool get _isEdit => widget.residence != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final residence = widget.residence!;
    _nameController.text = residence.name;
    _descriptionController.text = residence.description;
    _addressController.text = residence.address;
    _priceController.text = residence.price.toString();
    _capacityController.text = residence.capacity.toString();
    _availableSlotsController.text = residence.availableSlots.toString();
    _selectedRentalPeriod = residence.rentalPeriod;
    _facilities = List.from(residence.facilities);
    _imageUrls = List.from(residence.images);

    if (residence.discountType != null) {
      _selectedDiscountType = residence.discountType;
      _discountValueController.text = residence.discountValue?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _availableSlotsController.dispose();
    _facilityController.dispose();
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
        Helpers.showSnackbar(
          context,
          'Gagal mengambil gambar: $e',
          isError: true,
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

  void _addFacility() {
    if (_facilityController.text.trim().isEmpty) return;

    setState(() {
      _facilities.add(_facilityController.text.trim());
      _facilityController.clear();
    });
  }

  void _removeFacility(int index) {
    setState(() {
      _facilities.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate images
    if (_imageUrls.isEmpty && _newImages.isEmpty) {
      Helpers.showSnackbar(
        context,
        'Minimal tambahkan 1 gambar',
        isError: true,
      );
      return;
    }

    // Validate facilities
    if (_facilities.isEmpty) {
      Helpers.showSnackbar(
        context,
        'Minimal tambahkan 1 fasilitas',
        isError: true,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final residenceProvider = context.read<ResidenceProvider>();

    // Prepare images (for now, convert File paths to strings)
    final List<String> allImages = [
      ..._imageUrls,
      ..._newImages.map((file) => file.path),
    ];

    // Create/Update residence model
    final residence = ResidenceModel(
      id: _isEdit ? widget.residence!.id : 0,
      providerId: authProvider.user?.id ?? 0,
      categoryId: 1, // TODO: Add category selection
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      latitude: -6.9147, // TODO: Add location picker
      longitude: 107.6098,
      rentalPeriod: _selectedRentalPeriod,
      price: double.parse(_priceController.text),
      capacity: int.parse(_capacityController.text),
      availableSlots: int.parse(_availableSlotsController.text),
      facilities: _facilities,
      images: allImages,
      discountType: _selectedDiscountType,
      discountValue: _discountValueController.text.isNotEmpty
          ? double.tryParse(_discountValueController.text)
          : null,
      isActive: true,
      createdAt: _isEdit ? widget.residence!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Helpers.showLoadingDialog(context);

    bool success;
    if (_isEdit) {
      success = await residenceProvider.updateResidence(residence);
    } else {
      success = await residenceProvider.createResidence(residence);
    }

    if (mounted) {
      Helpers.hideLoadingDialog(context);

      if (success) {
        Helpers.showSnackbar(
          context,
          _isEdit ? 'Hunian berhasil diupdate' : 'Hunian berhasil ditambahkan',
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        Helpers.showSnackbar(
          context,
          residenceProvider.errorMessage ?? 'Terjadi kesalahan',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Hunian' : 'Tambah Hunian'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images Section
            const Text(
              'Foto Hunian',
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

            // Basic Info
            CustomTextField(
              controller: _nameController,
              label: 'Nama Hunian',
              hint: 'Contoh: Kos Putri Sukabirus',
              prefixIcon: Icons.home_work,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama hunian tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _descriptionController,
              label: 'Deskripsi',
              hint: 'Deskripsikan hunian Anda...',
              prefixIcon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _addressController,
              label: 'Alamat',
              hint: 'Alamat lengkap hunian',
              prefixIcon: Icons.location_on,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alamat tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Rental Period
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Periode Sewa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'monthly',
                        groupValue: _selectedRentalPeriod,
                        onChanged: (value) {
                          setState(() {
                            _selectedRentalPeriod = value!;
                          });
                        },
                        title: const Text('Bulanan'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'yearly',
                        groupValue: _selectedRentalPeriod,
                        onChanged: (value) {
                          setState(() {
                            _selectedRentalPeriod = value!;
                          });
                        },
                        title: const Text('Tahunan'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Price
            CustomTextField(
              controller: _priceController,
              label: 'Harga',
              hint: 'Contoh: 1500000',
              prefixIcon: Icons.money,
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

            // Capacity & Available Slots
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _capacityController,
                    label: 'Kapasitas',
                    hint: '10',
                    prefixIcon: Icons.people,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wajib diisi';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Harus angka';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _availableSlotsController,
                    label: 'Slot Tersedia',
                    hint: '5',
                    prefixIcon: Icons.door_front_door,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wajib diisi';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Harus angka';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Facilities Section
            const Text(
              'Fasilitas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Add Facility Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _facilityController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: WiFi, AC, Kasur',
                      prefixIcon: const Icon(Icons.add_circle_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (_) => _addFacility(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addFacility,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Facilities List
            if (_facilities.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _facilities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final facility = entry.value;
                  return Chip(
                    label: Text(facility),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeFacility(index),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    deleteIconColor: AppColors.error,
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // Discount Section (Optional)
            const Text(
              'Diskon (Opsional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Fix: Buat Column, bukan Row - GANTI SELURUH BAGIAN INI
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
                  CustomTextField(
                    controller: _discountValueController,
                    label: 'Nilai Diskon',
                    hint: _selectedDiscountType == 'percentage'
                        ? 'Contoh: 10'
                        : 'Contoh: 100000',
                    prefixIcon: Icons.discount,
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

            const SizedBox(height: 32),

            // Submit Button
            Consumer<ResidenceProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: _isEdit ? 'Update Hunian' : 'Tambah Hunian',
                  onPressed: _handleSubmit,
                  isLoading: provider.isLoading,
                  icon: _isEdit ? Icons.save : Icons.add,
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
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
