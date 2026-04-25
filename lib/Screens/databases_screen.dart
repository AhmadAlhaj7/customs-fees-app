import 'package:flutter/material.dart';
import '../models/database_model.dart';
import '../database/db_helper.dart';
import '../services/excel_service.dart';
import 'home_screen.dart';

class DatabasesScreen extends StatefulWidget {
  const DatabasesScreen({super.key});

  @override
  State<DatabasesScreen> createState() => _DatabasesScreenState();
}

class _DatabasesScreenState extends State<DatabasesScreen> {
  List<DatabaseModel> _databases = [];
  bool _isLoading = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    setState(() => _isLoading = true);
    final databases = await DBHelper.getAllDatabases();
    setState(() {
      _databases = databases;
      _isLoading = false;
    });
  }

  Future<void> _importExcel() async {
    setState(() => _isImporting = true);
    try {
      final dbModel = await ExcelService.importExcel();
      if (dbModel != null) {
        await _loadDatabases();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Imported ${dbModel.itemCount} items from ${dbModel.fileName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isImporting = false);
  }

  Future<void> _deleteDatabase(DatabaseModel dbModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Database'),
        content: Text(
            'Are you sure you want to delete "${dbModel.name}" and all its items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.deleteDatabase(dbModel.id!);
      await _loadDatabases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customs Fees App'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _databases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No databases yet',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Import an Excel file to get started',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isImporting ? null : _importExcel,
                        icon: _isImporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                            _isImporting ? 'Importing...' : 'Import Excel'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _databases.length,
                  itemBuilder: (context, index) {
                    final db = _databases[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder,
                              color: Colors.orange, size: 30),
                        ),
                        title: Text(
                          db.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${db.itemCount} items • ${db.createdAt.day}/${db.createdAt.month}/${db.createdAt.year}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _deleteDatabase(db),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HomeScreen(database: db),
                            ),
                          );
                          _loadDatabases();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: _databases.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.orange,
              onPressed: _isImporting ? null : _importExcel,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                _isImporting ? 'Importing...' : 'Import Excel',
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}