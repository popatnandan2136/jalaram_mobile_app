import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/shop_balance.dart';
import '../utils/number_to_words.dart';

class PdfHelper {
  static Future<String> generateStatement({
    required String contactName,
    required String contactMobile,
    required String contactType, // 'Retailer' or 'Customer'
    required List<TransactionModel> transactions,
    required double outstandingBalance,
    Uint8List? logoBytes,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );
    
    // Filter transactions based on date range for rendering
    final periodTxs = transactions.where((tx) {
      if (startDate != null && tx.timestamp.isBefore(startDate)) return false;
      if (endDate != null && tx.timestamp.isAfter(endDate.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();

    // Calculate opening balance (outstanding balance before startDate)
    double openingBalance = 0.0;
    if (startDate != null) {
      for (var tx in transactions) {
        if (tx.timestamp.isBefore(startDate)) {
          if (tx.isDebit) {
            openingBalance += tx.amount;
          } else {
            openingBalance -= tx.amount;
          }
        }
      }
    }

    // Calculate period summaries
    double periodDebits = 0.0;
    double periodCredits = 0.0;
    for (var tx in periodTxs) {
      if (tx.isDebit) {
        periodDebits += tx.amount;
      } else {
        periodCredits += tx.amount;
      }
    }

    // Closing balance
    final double closingBalance = openingBalance + periodDebits - periodCredits;

    // Formatting variables
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final outstandingWords = NumberToWords.convert(closingBalance);
    final subtitleStr = (startDate != null && endDate != null)
        ? 'Statement Period: ${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}'
        : 'Mobile Recharge & Ledger Statement';
    
    // Theme colors
    final primaryColor = PdfColor.fromHex('#3F51B5'); // Indigo
    final textDark = PdfColor.fromHex('#212121');
    final textMuted = PdfColor.fromHex('#757575');
    final zebraColor = PdfColor.fromHex('#F5F5F5');

    // Build PDF content page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Banner
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoBytes != null) ...[
                      pw.Container(
                        width: 42,
                        height: 42,
                        margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.cover),
                      ),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NP DIGITAL',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          subtitleStr,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'STATEMENT OF ACCOUNT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: $dateStr',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 2, color: primaryColor),
            pw.SizedBox(height: 8),
            pw.Text(
              'Note: In this statement, Indigo blue represents NP Digital corporate records, Green represents payment receipts/credits, and Red represents debits/deletions.',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: textMuted),
            ),
            pw.SizedBox(height: 8),
            
            // Info block grid (Contact & Summary)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'STATEMENT FOR:',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        contactName,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textDark),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Mobile: $contactMobile',
                        style: pw.TextStyle(fontSize: 10, color: textDark),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Account Type: $contactType',
                        style: pw.TextStyle(fontSize: 10, color: primaryColor, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: zebraColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.indigo100, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        startDate != null ? 'CLOSING BALANCE' : 'NET OUTSTANDING',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Rs. ${closingBalance.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        closingBalance > 0 ? 'Owes Balance to Shop' : 'Settled / No Outstanding',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: closingBalance > 0 ? PdfColors.red : PdfColors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 24),
            
            // Transactions Table
            pw.TableHelper.fromTextArray(
              headers: ['Date & Time', 'Type', 'Account/App', 'Remarks / Notes', 'Debit (-)', 'Credit (+)'],
              data: periodTxs.map((tx) {
                final txDate = DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp);
                final String type = tx.isDebit ? 'Debit' : 'Credit';
                final String appStr = tx.app ?? 'Cash/Other';
                final String notes = tx.notes ?? '-';
                
                final String debit = tx.isDebit ? 'Rs. ${tx.amount.toStringAsFixed(2)}' : '-';
                final String credit = !tx.isDebit ? 'Rs. ${tx.amount.toStringAsFixed(2)}' : '-';
                
                return [txDate, type, appStr, notes, debit, credit];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(color: zebraColor),
              cellStyle: pw.TextStyle(color: textDark, fontSize: 8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary Calculation Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      if (startDate != null) ...[
                        _buildSummaryRow('Opening Balance:', 'Rs. ${openingBalance.toStringAsFixed(2)}', textDark, false),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Period Debits:', 'Rs. ${periodDebits.toStringAsFixed(2)}', textDark, false),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Period Credits:', 'Rs. ${periodCredits.toStringAsFixed(2)}', textDark, false),
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 1, color: PdfColors.grey300),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Closing Balance:', 'Rs. ${closingBalance.toStringAsFixed(2)}', primaryColor, true),
                      ] else ...[
                        _buildSummaryRow('Total Sent (Debits):', 'Rs. ${periodDebits.toStringAsFixed(2)}', textDark, false),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Total Got (Credits):', 'Rs. ${periodCredits.toStringAsFixed(2)}', textDark, false),
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 1, color: PdfColors.grey300),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Net Balance:', 'Rs. ${closingBalance.toStringAsFixed(2)}', primaryColor, true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 16),
            
            // Amount in words box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: zebraColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Balance in Words: ',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      outstandingWords,
                      style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: primaryColor, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 40),
            
            // Signature lines
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 120, height: 1, color: textMuted),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(width: 120, height: 1, color: textMuted),
                    pw.SizedBox(height: 4),
                    pw.Text('Customer/Retailer Signature', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                  ],
                ),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Thank you for your business. Generated via NP Digital App.',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save PDF file to users Downloads folder (with safe documents dir fallbacks)
    final String safeName = contactName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final String filename = 'Statement_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    File file;
    try {
      if (Platform.isAndroid) {
        // Try to save directly to users public Downloads directory
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          file = File('${downloadDir.path}/$filename');
        } else {
          // Fallback to app-specific external files storage
          final extDir = await getExternalStorageDirectory();
          file = File('${extDir!.path}/$filename');
        }
      } else {
        // Fallback for iOS
        final docDir = await getApplicationDocumentsDirectory();
        file = File('${docDir.path}/$filename');
      }
    } catch (_) {
      // General ultimate fallback
      final docDir = await getApplicationDocumentsDirectory();
      file = File('${docDir.path}/$filename');
    }

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<String> generateShopStatement({
    required double totalShopBalance,
    required Map<String, double> walletBalances,
    required List<TransactionModel> transactions,
    required List<ShopBalance> shopBalances,
    required Map<String, String> contactNames,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );
    
    // Formatting variables
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    
    // Theme colors
    final primaryColor = PdfColor.fromHex('#3F51B5'); // Indigo
    final textDark = PdfColor.fromHex('#212121');
    final textMuted = PdfColor.fromHex('#757575');
    final zebraColor = PdfColor.fromHex('#F5F5F5');

    // Build PDF content page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Banner
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoBytes != null) ...[
                      pw.Container(
                        width: 42,
                        height: 42,
                        margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.cover),
                      ),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NP DIGITAL',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Overall Shop Ledger & Balances',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'SHOP REPORT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: $dateStr',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 2, color: primaryColor),
            pw.SizedBox(height: 8),
            pw.Text(
              'Note: In this statement, Indigo blue represents NP Digital corporate records, Green represents payment receipts/credits, and Red represents debits/deletions.',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: textMuted),
            ),
            pw.SizedBox(height: 8),
            
            // Shop Summary Cards
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WALLET BALANCES:',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted),
                      ),
                      pw.SizedBox(height: 4),
                      for (var entry in walletBalances.entries) ...[
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(entry.key, style: pw.TextStyle(fontSize: 9, color: textDark)),
                            pw.Text('Rs. ${entry.value.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: zebraColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.indigo100, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TOTAL SHOP BALANCE',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Rs. ${totalShopBalance.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 24),
            
            // Title for transaction list
            pw.Text(
              'RECENT TRANSACTIONS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),
            
            // Transactions Table (limit to last 50 for page size and speed)
            pw.TableHelper.fromTextArray(
              headers: ['Date & Time', 'Contact Name', 'Type', 'Account/App', 'Remarks / Notes', 'Amount'],
              data: transactions.take(50).map((tx) {
                final txDate = DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp);
                final String type = tx.isDebit ? 'Debit' : 'Credit';
                final String appStr = tx.app ?? 'Cash/Other';
                final String notes = tx.notes ?? '-';
                final String amount = 'Rs. ${tx.amount.toStringAsFixed(2)}';
                final String contactName = contactNames[tx.retailerId] ?? tx.retailerId;
                
                return [txDate, contactName, type, appStr, notes, amount];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(color: zebraColor),
              cellStyle: pw.TextStyle(color: textDark, fontSize: 7),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
              },
            ),
            
            pw.SizedBox(height: 30),
            
            // Signature lines
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 120, height: 1, color: textMuted),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                  ],
                ),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated via NP Digital App.',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
              ],
            ),
          );
        },
      ),
    );

    final String filename = 'Shop_Statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    File file;
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          file = File('${downloadDir.path}/$filename');
        } else {
          final extDir = await getExternalStorageDirectory();
          file = File('${extDir!.path}/$filename');
        }
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        file = File('${docDir.path}/$filename');
      }
    } catch (_) {
      final docDir = await getApplicationDocumentsDirectory();
      file = File('${docDir.path}/$filename');
    }

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildSummaryRow(String label, String value, PdfColor textColor, bool isBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isBold ? 11 : 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
