import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class AddScreen extends StatefulWidget {
  final int databaseId;
  const AddScreen({super.key, required this.databaseId});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _itemNumberController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _importFeeController = TextEditingController();
  final TextEditingController _serviceFeeController = TextEditingController();
  final TextEditingController _totalFeeController = TextEditingController();
  final TextEditingController _commercialNameController = TextEditingController();
  bool _isSaving = false;

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

  Future<void> _saveProduct() async {
    if (_itemNumberController.text.isEmpty ||
        _itemNameController.text.isEmpty ||
        _importFeeController.text.isEmpty ||
        _serviceFeeController.text.isEmpty ||
        _totalFeeController.text.isEmpty ||
        _commercialNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final product = Product(
      databaseId: widget.databaseId,
      itemNumber: _itemNumberController.text,
      itemName: _itemNameController.text,
      description: _descriptionController.text.isEmpty
          ? _itemNameController.text
          : _descriptionController.text,
      importFee: double.tryParse(_importFeeController.text) ?? 0,
      serviceFee: double.tryParse(_serviceFeeController.text) ?? 0,
      totalFee: double.tryParse(_totalFeeController.text) ?? 0,
      commercialName: _commercialNameController.text,
    );

    await DBHelper.insertProduct(product);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType? keyboardType, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '* Required fields',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildField('Item Number', _itemNumberController),
            _buildField('Commercial Name', _commercialNameController),
            _buildField('Item Name', _itemNameController),
            _buildField('Description', _descriptionController,
                required: false),
            _buildField('Import Fee', _importFeeController,
                keyboardType: TextInputType.number),
            _buildField('Service Fee', _serviceFeeController,
                keyboardType: TextInputType.number),
            _buildField('Total Fee', _totalFeeController,
                keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProduct,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Product',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}