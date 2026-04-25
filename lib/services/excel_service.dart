import 'dart:io';
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
    // Step 1: Let user pick an Excel file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes ?? File(file.path!).readAsBytesSync();

    // Step 2: Parse the Excel file
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) return null;

    // Step 3: Create a new database entry
    final dbModel = DatabaseModel(
      name: file.name.replaceAll(RegExp(r'\.(xlsx|xls)$'), ''),
      fileName: file.name,
      createdAt: DateTime.now(),
      itemCount: 0,
    );

    final databaseId = await DBHelper.insertDatabase(dbModel);

    // Step 4: Read rows and convert to products
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

      final itemNumber = getString(2);      // Column C
      final itemName = getString(3);        // Column D
      final importFee = getDouble(4);       // Column E
      final serviceFee = getDouble(5);      // Column F
      final totalFee = getDouble(6);        // Column G
      final commercialName = getString(11); // Column L

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

    // Step 5: Save all products in one batch
    await DBHelper.insertProducts(products);
    await DBHelper.updateDatabaseItemCount(databaseId);

    dbModel.id = databaseId;
    dbModel.itemCount = products.length;
    return dbModel;
  }
static Future<void> exportExcel(
      DatabaseModel dbModel, List<Product> products) async {
    try {
      // Step 1: Request permissions
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();

      // Step 2: Verify we have products
      if (products.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      // Step 3: Create Excel
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Step 4: Add headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('البند الفرعي');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('اسم البند');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('رسم الاستيراد');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('بدل خدمات');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue('رسم الاستيراد كامل');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = TextCellValue('الاسم التجاري');

      // Step 5: Add rows
      for (int i = 0; i < products.length; i++) {
        final p = products[i];
        final row = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(p.itemNumber);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(p.itemName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(p.importFee.toString());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(p.serviceFee.toString());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(p.totalFee.toString());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(p.commercialName);
      }

      // Step 6: Save file
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName = '${dbModel.name}_export.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.encode()!;
      await File(filePath).writeAsBytes(fileBytes, flush: true);

      // Step 7: Open file
      await OpenFilex.open(filePath);

    } catch (e) {
      rethrow;
    }
  }
}