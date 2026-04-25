import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database/db_helper.dart';
import 'add_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Load all products from database
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await DBHelper.getAllProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  // Search products by item number
  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      _loadProducts();
      return;
    }
    setState(() => _isLoading = true);
    final products = await DBHelper.searchByItemNumber(query);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customs Fees App'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Export Excel',
            onPressed: () {
              // We will add this later
            },
          ),
          // Import button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import Excel',
            onPressed: () {
              // We will add this later
            },
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
                hintText: 'Search by item number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Product count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_products.length} items found',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  product.itemNumber.substring(0, 1),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(product.commercialName),
                              subtitle: Text('Item #${product.itemNumber}'),
                              trailing: Text(
                                'Total: ${product.totalFee}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
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
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}