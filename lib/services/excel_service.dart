import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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
        return double.tryParse(str) ?? 0.0;
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

  // ─── EXPORT ───────────────────────────────────────────

  static Future<void> exportExcel(
      DatabaseModel dbModel, List<Product> products) async {
    // Step 1: Create Excel file
    final excel = Excel.createExcel();
    final sheet = excel['Products'];

    // Step 2: Add header row
    final headers = [
      'البند الفرعي',
      'اسم البند',
      'رسم الاستيراد',
      'بدل خدمات',
      'رسم الاستيراد كامل',
      'الاسم التجاري',
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Step 3: Add product rows
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final rowIndex = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(p.itemNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(p.itemName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = DoubleCellValue(p.importFee);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(p.serviceFee);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(p.totalFee);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(p.commercialName);
    }

    // Step 4: Save file to device
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${dbModel.name}_export.xlsx';
    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    // Step 5: Open the file
    await OpenFilex.open(filePath);
  }
}