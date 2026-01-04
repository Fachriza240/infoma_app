import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/marketplace_product_model.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/auth_provider.dart';

class MarketplaceFormScreen extends StatefulWidget {
  final MarketplaceProductModel? product;

  const MarketplaceFormScreen({
    super.key,
    this.product,
  });

  @override
  State<MarketplaceFormScreen> createState() => _MarketplaceFormScreenState();
}

class _MarketplaceFormScreenState extends State<MarketplaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<String> _imageUrls = [];
  List<File> _newImages = [];

  String _selectedCondition = 'good';
  final List<Map<String, String>> _conditions = [
    {'value': 'new', 'label': 'Baru'},
    {'value': 'like_new', 'label': 'Seperti Baru'},
    {'value': 'good', 'label': 'Baik'},
    {'value': 'fair', 'label': 'Lumayan'},
    {'value': 'needs_repair', 'label': 'Perlu Perbaikan'},
  ];

  List<String> _tags = [];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _stockController.text = product.stockQuantity.toString();
    _locationController.text = product.location;
    _selectedCondition = product.condition;
    _imageUrls = List.from(product.images);
    if (product.tags != null) {
      _tags = List.from(product.tags!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    _tagController.dispose();
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

  void _addTag() {
    if (_tagController.text.trim().isEmpty) return;

    setState(() {
      _tags.add(_tagController.text.trim());
      _tagController.clear();
    });
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
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

    final authProvider = context.read<AuthProvider>();
    final marketplaceProvider = context.read<MarketplaceProvider>();

    // Prepare images
    final List<String> allImages = [
      ..._imageUrls,
      ..._newImages.map((file) => file.path),
    ];

    // Create/Update product model
    final product = MarketplaceProductModel(
      id: _isEdit ? widget.product!.id : 0,
      sellerId: authProvider.user?.id ?? 0,
      categoryId: 1, // TODO: Add category selection
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      condition: _selectedCondition,
      price: double.parse(_priceController.text),
      stockQuantity: int.parse(_stockController.text),
      location: _locationController.text.trim(),
      latitude: -6.9147, // TODO: Add location picker
      longitude: 107.6098,
      images: allImages,
      tags: _tags.isNotEmpty ? _tags : null,
      status: 'active',
      viewsCount: _isEdit ? widget.product!.viewsCount : 0,
      createdAt: _isEdit ? widget.product!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Helpers.showLoadingDialog(context);

    bool success;
    if (_isEdit) {
      success = await marketplaceProvider.updateProduct(product);
    } else {
      success = await marketplaceProvider.createProduct(product);
    }

    if (mounted) {
      Helpers.hideLoadingDialog(context);

      if (success) {
        Helpers.showSnackbar(
          context,
          _isEdit ? 'Produk berhasil diupdate' : 'Produk berhasil ditambahkan',
        );
        Navigator.pop(context, true);
      } else {
        Helpers.showSnackbar(
          context,
          marketplaceProvider.errorMessage ?? 'Terjadi kesalahan',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images Section
            const Text(
              'Foto Produk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Existing Images
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

            // New Images
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

            // Product Name
            CustomTextField(
              controller: _nameController,
              label: 'Nama Produk',
              hint: 'Contoh: Laptop ASUS ROG',
              prefixIcon: Icons.shopping_bag,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama produk tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Condition Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Kondisi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.verified),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition['value'],
                  child: Text(condition['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Price & Stock
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _priceController,
                    label: 'Harga',
                    hint: '1500000',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wajib diisi';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Harus angka';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _stockController,
                    label: 'Stok',
                    hint: '1',
                    prefixIcon: Icons.inventory_2,
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

            const SizedBox(height: 16),

            // Location
            CustomTextField(
              controller: _locationController,
              label: 'Lokasi',
              hint: 'Bandung, Jawa Barat',
              prefixIcon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lokasi tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Deskripsi',
              hint: 'Jelaskan produk Anda...',
              prefixIcon: Icons.description,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Tags Section
            const Text(
              'Tags (Opsional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Add Tag Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: laptop, gaming',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags List
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tag = entry.value;
                  return Chip(
                    label: Text('#$tag'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(index),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    deleteIconColor: AppColors.error,
                  );
                }).toList(),
              ),

            const SizedBox(height: 32),

            // Submit Button
            Consumer<MarketplaceProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: _isEdit ? 'Update Produk' : 'Tambah Produk',
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
