import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/database_model.dart';
import '../database/db_helper.dart';
import '../services/excel_service.dart';
import 'add_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseModel database;
  const HomeScreen({super.key, required this.database});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products =
        await DBHelper.getProductsByDatabase(widget.database.id!);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      _loadProducts();
      return;
    }
    setState(() => _isLoading = true);
    final products =
        await DBHelper.searchProducts(widget.database.id!, query);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final products =
          await DBHelper.getProductsByDatabase(widget.database.id!);
      await ExcelService.exportExcel(widget.database, products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.database.name),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            tooltip: 'تصدير Excel',
            onPressed: _isExporting ? null : _exportExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchProducts,
              decoration: InputDecoration(
                hintText: 'ابحث برقم البند أو الاسم...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Item count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_products.length} عنصر',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('لا توجد منتجات'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  product.itemNumber.isNotEmpty
                                      ? product.itemNumber.substring(0, 1)
                                      : '?',
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                product.commercialName.isNotEmpty
                                    ? product.commercialName
                                    : product.itemName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('رقم البند: ${product.itemNumber}'),
                              trailing: Text(
                                '${product.totalFee.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailScreen(product: product),
                                  ),
                                );
                                _loadProducts();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

      // Add new item button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddScreen(databaseId: widget.database.id!),
            ),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}