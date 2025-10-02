import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';

class ExportService {
  final ApiService _apiService = ApiService();
  final Logger logger = Logger();

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      }
    } catch (err) {
      logger.e("Cannot get download folder path");
    }
    return directory?.path;
  }

  Future<String?> exportToCsv(int year, int month) async {
    if (!await requestStoragePermission()) return null;

    final result = await _apiService.exportTransactions(year: year, month: month);
    if (result['statusCode'] != 200) return null;

    final path = await getDownloadPath();
    if (path == null) return null;

    final fileName = 'laporan-transaksi-$year-$month.csv';
    final file = File('$path/$fileName');
    await file.writeAsString(result['body']);
    return file.path;
  }
  
  Future<String?> exportToPdf(int year, int month) async {
    if (!await requestStoragePermission()) return null;

    final result = await _apiService.getTransactions(year: year, month: month);
    if (result['statusCode'] != 200) return null;

    final List<dynamic> transactions = result['body'];
    if (transactions.isEmpty) return 'no_data';
    
    final pdf = pw.Document();
    
    final fontData = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildPdfHeader(context, year, month, font, boldFont),
          _buildPdfSummary(context, transactions, boldFont),
          pw.SizedBox(height: 20),
          _buildPdfTable(context, transactions, font, boldFont),
        ],
      ),
    );

    final path = await getDownloadPath();
    if (path == null) return null;

    final fileName = 'laporan-keuangan-$year-$month.pdf';
    final file = File('$path/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _buildPdfHeader(pw.Context context, int year, int month, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('SkydashNET Finance Tracker', style: pw.TextStyle(font: boldFont, fontSize: 24)),
        pw.Text('Laporan Keuangan Bulanan', style: pw.TextStyle(font: font, fontSize: 16)),
        pw.Divider(height: 20, thickness: 2),
        pw.Text(
          'Periode: ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month))}',
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildPdfSummary(pw.Context context, List<dynamic> transactions, pw.Font boldFont) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var trx in transactions) {
      if (trx['category_type'] == 'income') {
        totalIncome += num.parse(trx['amount'].toString());
      } else {
        totalExpense += num.parse(trx['amount'].toString());
      }
    }
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryBox('Total Pemasukan', totalIncome, PdfColors.green, boldFont),
        _buildSummaryBox('Total Pengeluaran', totalExpense, PdfColors.red, boldFont),
        _buildSummaryBox('Hasil Akhir', totalIncome - totalExpense, PdfColors.blue, boldFont),
      ]
    );
  }
  
  pw.Widget _buildSummaryBox(String title, double amount, PdfColor color, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
            style: pw.TextStyle(font: boldFont, fontSize: 16, color: color),
          )
        ]
      )
    );
  }

  pw.Widget _buildPdfTable(pw.Context context, List<dynamic> transactions, pw.Font font, pw.Font boldFont) {
    const tableHeaders = ['Tanggal', 'Kategori', 'Deskripsi', 'Pemasukan', 'Pengeluaran'];
    return pw.TableHelper.fromTextArray(
      headers: tableHeaders,
      data: transactions.map((trx) {
        final isIncome = trx['category_type'] == 'income';
        final amount = num.parse(trx['amount'].toString());
        return [
          DateFormat('d MMM yyyy').format(DateTime.parse(trx['transaction_date'])),
          trx['category_name'],
          trx['description'] ?? '',
          isIncome ? NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount) : '',
          !isIncome ? NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount) : '',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellStyle: pw.TextStyle(font: font),
      cellAlignments: {
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }
}