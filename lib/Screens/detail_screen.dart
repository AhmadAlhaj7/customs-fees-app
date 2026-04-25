import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class DetailScreen extends StatefulWidget {
  final Product product;
  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late TextEditingController _itemNumberController;
  late TextEditingController _itemNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _importFeeController;
  late TextEditingController _serviceFeeController;
  late TextEditingController _totalFeeController;
  late TextEditingController _commercialNameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _itemNumberController =
        TextEditingController(text: widget.product.itemNumber);
    _itemNameController =
        TextEditingController(text: widget.product.itemName);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _importFeeController =
        TextEditingController(text: widget.product.importFee.toString());
    _serviceFeeController =
        TextEditingController(text: widget.product.serviceFee.toString());
    _totalFeeController =
        TextEditingController(text: widget.product.totalFee.toString());
    _commercialNameController =
        TextEditingController(text: widget.product.commercialName);
  }

  @override
  void dispose() {
    _itemNumberController.dispose();
    _itemNameController.dispose();
    _descriptionController.dispose();
    _importFeeController.dispose();
    _serviceFeeController.dispose();
    _totalFeeController.dispose();
    _commercialNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updated = Product(
      id: widget.product.id,
      databaseId: widget.product.databaseId,
      itemNumber: _itemNumberController.text,
      itemName: _itemNameController.text,
      description: _descriptionController.text,
      importFee: double.tryParse(_importFeeController.text) ?? 0,
      serviceFee: double.tryParse(_serviceFeeController.text) ?? 0,
      totalFee: double.tryParse(_totalFeeController.text) ?? 0,
      commercialName: _commercialNameController.text,
      imagePath: widget.product.imagePath,
    );
    await DBHelper.updateProduct(updated);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تحديث المنتج بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content:
            const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.deleteProduct(
        widget.product.id!,
        widget.product.databaseId,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.commercialName.isNotEmpty
            ? widget.product.commercialName
            : widget.product.itemName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildField('رقم البند', _itemNumberController),
            _buildField('الاسم التجاري', _commercialNameController),
            _buildField('اسم البند', _itemNameController),
            _buildField('الوصف', _descriptionController),
            _buildField('رسم الاستيراد', _importFeeController,
                keyboardType: TextInputType.number),
            _buildField('بدل الخدمات', _serviceFeeController,
                keyboardType: TextInputType.number),
            _buildField('رسم الاستيراد الكامل', _totalFeeController,
                keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }
}