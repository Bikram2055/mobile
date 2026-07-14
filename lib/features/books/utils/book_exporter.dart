import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/book.dart';
import '../data/models/expense.dart';
import '../data/models/expense_category.dart';

class BookExporter {
  BookExporter()
      : _currencyFormat = NumberFormat.currency(
          locale: 'en_IN',
          name: 'NPR',
          symbol: 'Rs ',
        ),
        _dateFormat = DateFormat('yyyy-MM-dd');

  final NumberFormat _currencyFormat;
  final DateFormat _dateFormat;

  Uint8List toCsvBytes(Book book) {
    final buffer = StringBuffer();
    buffer.writeln('"Description","Category","Type","Amount","Date"');

    for (final expense in book.expenses) {
      buffer.writeln(_csvRow(expense));
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  String _csvRow(Expense expense) {
    final escapedDescription = expense.description.replaceAll('"', '""');
    final category = ExpenseCategories.byId(expense.categoryId).label;
    final type = expense.isIncome ? 'Income' : 'Expense';
    return '"$escapedDescription","$category","$type","${_currencyFormat.format(expense.amount)}","${_dateFormat.format(expense.date)}"';
  }

  Future<Uint8List> toPdfBytes(Book book) async {
    final doc = pw.Document();
    final headers = ['Description', 'Category', 'Type', 'Amount', 'Date'];
    final rows = book.expenses
        .map(
          (expense) => [
            expense.description,
            ExpenseCategories.byId(expense.categoryId).label,
            expense.isIncome ? 'Income' : 'Expense',
            _currencyFormat.format(expense.amount),
            _dateFormat.format(expense.date),
          ],
        )
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              book.title,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Total spent: ${_currencyFormat.format(book.totalSpent)}'),
          pw.Text('Expenses: ${book.expenseCount}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
