import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/product.dart';
import '../models/database_model.dart';
import '../database/db_helper.dart';

class ExcelService {
  // ─── IMPORT ───────────────────────────────────────────

  static Future<DatabaseModel?> importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes ?? File(file.path!).readAsBytesSync();

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) return null;

    final dbModel = DatabaseModel(
      name: file.name.replaceAll(RegExp(r'\.(xlsx|xls)$'), ''),
      fileName: file.name,
      createdAt: DateTime.now(),
      itemCount: 0,
    );

    final databaseId = await DBHelper.insertDatabase(dbModel);
    final List<Product> products = [];

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;

      String getString(int colIndex) {
        if (colIndex >= row.length) return '';
        final cell = row[colIndex];
        if (cell == null || cell.value == null) return '';
        return cell.value.toString().trim();
      }

      double getDouble(int colIndex) {
        final str = getString(colIndex);
        final value = double.tryParse(str) ?? 0.0;
        return double.parse(value.toStringAsFixed(2));
      }

      final itemNumber = getString(2);
      final itemName = getString(3);
      final importFee = getDouble(4);
      final serviceFee = getDouble(5);
      final totalFee = getDouble(6);
      final commercialName = getString(11);

      if (itemNumber.isEmpty) continue;

      products.add(Product(
        databaseId: databaseId,
        itemNumber: itemNumber,
        itemName: itemName,
        description: itemName,
        importFee: importFee,
        serviceFee: serviceFee,
        totalFee: totalFee,
        commercialName: commercialName,
      ));
    }

    await DBHelper.insertProducts(products);
    await DBHelper.updateDatabaseItemCount(databaseId);

    dbModel.id = databaseId;
    dbModel.itemCount = products.length;
    return dbModel;
  }


  static Future<void> exportExcel(
      DatabaseModel dbModel, List<Product> products) async {
    try {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();

      if (products.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      print('Starting export with ${products.length} products');

      // Create excel with default sheet
      var excel = Excel.createExcel();
      var sheet = excel.sheets[excel.getDefaultSheet()!]!;

      // Add headers
      List<String> headers = [
        'البند الفرعي',
        'اسم البند', 
        'رسم الاستيراد',
        'بدل خدمات',
        'رسم الاستيراد كامل',
        'الاسم التجاري',
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Add product rows
      for (final p in products) {
        sheet.appendRow([
          TextCellValue(p.itemNumber),
          TextCellValue(p.itemName),
          TextCellValue(p.importFee.toString()),
          TextCellValue(p.serviceFee.toString()),
          TextCellValue(p.totalFee.toString()),
          TextCellValue(p.commercialName),
        ]);
      }

      print('Rows added: ${sheet.maxRows}');

      // Encode
      final fileBytes = excel.encode();
      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('فشل في ترميز الملف');
      }

      print('Encoded bytes: ${fileBytes.length}');

      // Save to Downloads
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName = '${dbModel.name}_export.xlsx';
      final filePath = '${directory.path}/$fileName';

      await File(filePath).writeAsBytes(fileBytes, flush: true);

      final fileSize = await File(filePath).length();
      print('File saved: $filePath ($fileSize bytes)');

      await OpenFilex.open(filePath);

    } catch (e) {
      print('Export error: $e');
      rethrow;
    }
  }
}