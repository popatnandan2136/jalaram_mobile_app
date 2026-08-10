import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/pdf_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/retailer.dart';
import '../models/transaction_model.dart';
import '../providers/shop_provider.dart';
import '../widgets/transaction_tile.dart';
import '../utils/number_to_words.dart';
import '../theme/app_theme.dart';

class RetailerDetailScreen extends StatefulWidget {
  final Retailer retailer;

  const RetailerDetailScreen({
    super.key,
    required this.retailer,
  });

  @override
  State<RetailerDetailScreen> createState() => _RetailerDetailScreenState();
}

class _RetailerDetailScreenState extends State<RetailerDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  Retailer get _currentRetailer {
    final provider = Provider.of<ShopProvider>(context, listen: false);
    return provider.retailers.firstWhere(
      (r) => r.id == widget.retailer.id,
      orElse: () => widget.retailer,
    );
  }

  // Clean phone numbers for direct WhatsApp launch URLs (digits only)
  String _formatMobile(String mobile) {
    String cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanMobile.length == 10) {
      return '91$cleanMobile'; // Default to Indian prefix (no + sign)
    }
    return cleanMobile;
  }

  // Direct WhatsApp Launcher with raw system share fallback
  Future<void> _sendMessage(String text) async {
    final formattedNum = _formatMobile(_currentRetailer.mobile);
    final whatsappUrl = Uri.parse("whatsapp://send?phone=$formattedNum&text=${Uri.encodeComponent(text)}");
    final webUrl = Uri.parse("https://wa.me/$formattedNum?text=${Uri.encodeComponent(text)}");

    try {
      final launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        final launchedWeb = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        if (!launchedWeb) {
          await Share.share(text);
        }
      }
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        await Share.share(text);
      }
    }
  }

  void _sendTransferNotification(TransactionModel tx, double remainingBalance) {
    final dateStr = DateFormat('dd MMM yyyy').format(tx.timestamp);
    final appStr = tx.app ?? "Transfer";

    final message = "          📱 *NP DIGITAL* 📱\n"
        "          *Date: $dateStr*\n"
        "----------------------------------------\n"
        "*TRANSACTION RECEIPT (DEBIT)*\n"
        "----------------------------------------\n"
        "*Retailer:* ${_currentRetailer.name}\n"
        "*Amount Sent:* Rs. ${tx.amount.toStringAsFixed(2)}\n"
        "*Transferred via:* $appStr\n\n"
        "*Ledger Status:*\n"
        "Remaining Balance to Pay: *Rs. ${remainingBalance.toStringAsFixed(2)}*\n"
        "----------------------------------------\n"
        "🙏 Thank you for choosing NP Digital! We appreciate your business.";
    
    _sendMessage(message);
  }

  void _sendReceivedNotification(TransactionModel tx, double remainingBalance) {
    final dateStr = DateFormat('dd MMM yyyy').format(tx.timestamp);
    final appStr = tx.app ?? "Cash/Other";

    final message = "          📱 *NP DIGITAL* 📱\n"
        "          *Date: $dateStr*\n"
        "----------------------------------------\n"
        "*PAYMENT RECEIPT (CREDIT)*\n"
        "----------------------------------------\n"
        "*Retailer:* ${_currentRetailer.name}\n"
        "*Amount Received:* Rs. ${tx.amount.toStringAsFixed(2)}\n"
        "*Received Mode:* $appStr\n\n"
        "*Ledger Status:*\n"
        "Remaining Balance to Pay: *Rs. ${remainingBalance.toStringAsFixed(2)}*\n"
        "----------------------------------------\n"
        "🙏 Thank you for choosing NP Digital! We appreciate your business.";

    _sendMessage(message);
  }

  void _sendOutstandingBalanceReminder(double remainingBalance) {
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    final message = "          📱 *NP DIGITAL* 📱\n"
        "          *Date: $dateStr*\n"
        "----------------------------------------\n"
        "*OUTSTANDING BALANCE REMINDER*\n"
        "----------------------------------------\n"
        "*Retailer:* ${_currentRetailer.name}\n\n"
        "*Ledger Status:*\n"
        "Remaining Balance to Pay: *Rs. ${remainingBalance.toStringAsFixed(2)}*\n"
        "----------------------------------------\n"
        "🙏 Thank you for choosing NP Digital! We appreciate your business.";

    _sendMessage(message);
  }

  void _sendTodayTransactionsSummary(List<TransactionModel> txs, double outstanding) {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final todayTxs = txs.where((tx) => DateFormat('yyyy-MM-dd').format(tx.timestamp) == todayStr).toList();

    if (todayTxs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions recorded today.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double todayDebits = 0;
    double todayCredits = 0;
    for (var tx in todayTxs) {
      if (tx.isDebit) {
        todayDebits += tx.amount;
      } else {
        todayCredits += tx.amount;
      }
    }

    final previousOutstanding = outstanding - todayDebits + todayCredits;
    final dateStr = DateFormat('dd MMM yyyy').format(today);

    final buffer = StringBuffer();
    buffer.writeln("          📱 *NP DIGITAL* 📱");
    buffer.writeln("          *Date: $dateStr*");
    buffer.writeln("----------------------------------------");
    buffer.writeln("*TODAY'S TRANSACTIONS SUMMARY*");
    buffer.writeln("----------------------------------------");
    buffer.writeln("*Retailer:* ${_currentRetailer.name}\n");
    buffer.writeln("*Ledger Status:*");

    if (todayDebits > 0 && todayCredits > 0) {
      buffer.writeln("Previous Outstanding: Rs. ${previousOutstanding.toStringAsFixed(2)}");
      buffer.writeln("Debit (Today's Sent): Rs. ${todayDebits.toStringAsFixed(2)}");
      buffer.writeln("Credit (Today's Got): Rs. ${todayCredits.toStringAsFixed(2)}");
      buffer.writeln("Remaining Balance to Pay: *Rs. ${outstanding.toStringAsFixed(2)}*");
    } else if (todayCredits > 0) {
      buffer.writeln("Outstanding (Before): Rs. ${previousOutstanding.toStringAsFixed(2)}");
      buffer.writeln("Credit (Today's Got): Rs. ${todayCredits.toStringAsFixed(2)}");
      buffer.writeln("Remaining Balance to Pay: *Rs. ${outstanding.toStringAsFixed(2)}*");
    } else {
      buffer.writeln("Previous Outstanding: Rs. ${previousOutstanding.toStringAsFixed(2)}");
      buffer.writeln("Debit (Today's Sent): Rs. ${todayDebits.toStringAsFixed(2)}");
      buffer.writeln("Remaining Balance to Pay: *Rs. ${outstanding.toStringAsFixed(2)}*");
    }

    buffer.writeln("----------------------------------------");
    buffer.write("🙏 Thank you for choosing NP Digital! We appreciate your business.");

    _sendMessage(buffer.toString());
  }

  Future<void> _exportPdfStatement(List<TransactionModel> txs, double outstanding) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: AppTheme.primaryIndigo),
            SizedBox(width: 10),
            Text('Download Statement', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Choose a date range for the statement:',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          // Quick: Today
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final today = DateTime.now();
              final startOfDay = DateTime(today.year, today.month, today.day);
              final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
              _generatePdf(txs, outstanding, startDate: startOfDay, endDate: endOfDay);
            },
            child: const Text('Today', style: TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
          ),
          // Quick: This Month
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final now = DateTime.now();
              final startOfMonth = DateTime(now.year, now.month, 1);
              _generatePdf(txs, outstanding, startDate: startOfMonth, endDate: now);
            },
            child: const Text('This Month', style: TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
          ),
          // Custom range
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final DateTimeRange? picked = await showDateRangePicker(
                context: this.context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primaryIndigo,
                        onPrimary: Colors.white,
                        surface: AppTheme.surfaceCard,
                        onSurface: AppTheme.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                _generatePdf(txs, outstanding, startDate: picked.start, endDate: picked.end);
              }
            },
            child: const Text('Custom Range', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          // Full history
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo),
            onPressed: () {
              Navigator.pop(ctx);
              _generatePdf(txs, outstanding);
            },
            child: const Text('Full History', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(List<TransactionModel> txs, double outstanding, {DateTime? startDate, DateTime? endDate}) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF Statement...'),
          duration: Duration(seconds: 1),
        ),
      );

      final assetBundle = DefaultAssetBundle.of(context);

      // Load logo bytes from assets
      Uint8List? logoBytes;
      try {
        final ByteData data = await assetBundle.load('assets/images/logo.jpg');
        logoBytes = data.buffer.asUint8List();
      } catch (_) {
        // Fallback silently if asset load fails
      }

      final filePath = await PdfHelper.generateStatement(
        contactName: widget.retailer.name,
        contactMobile: widget.retailer.mobile,
        contactType: 'Retailer',
        transactions: txs,
        outstandingBalance: outstanding,
        logoBytes: logoBytes,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf, color: AppTheme.creditGreen),
                SizedBox(width: 10),
                Text('Statement Ready', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Statement saved:\n${filePath.split(Platform.pathSeparator).last}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await OpenFilex.open(filePath);
                },
                icon: const Icon(Icons.visibility, color: AppTheme.accentCyan),
                label: const Text('View', style: TextStyle(color: AppTheme.accentCyan)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.creditGreen),
                onPressed: () {
                  Navigator.pop(ctx);
                  Share.shareXFiles([XFile(filePath)], text: 'Ledger Statement - ${widget.retailer.name}');
                },
                icon: const Icon(Icons.share, size: 16, color: Colors.white),
                label: const Text('Share', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  void _confirmDeleteTransaction(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete this Rs. ${tx.amount.toStringAsFixed(2)} '
          '${tx.isDebit ? 'debit' : 'credit'} transaction? This will permanently modify the ledger balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<ShopProvider>(context, listen: false);
              await provider.deleteTransaction(tx.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.debitRed)),
          ),
        ],
      ),
    );
  }

  void _openEditTransactionDialog(TransactionModel tx) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: tx.amount.toString());
    final notesController = TextEditingController(text: tx.notes ?? '');
    String selectedApp = tx.app ?? 'Cash/Other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${tx.isDebit ? 'Debit' : 'Credit'} Transaction'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rs.)',
                      prefixText: 'Rs. ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter amount';
                      if (double.tryParse(val) == null || double.parse(val) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (tx.isDebit || tx.app != null) ...[
                    DropdownButtonFormField<String>(
                      value: selectedApp,
                      decoration: const InputDecoration(labelText: 'Wallet / Account'),
                      dropdownColor: AppTheme.surfaceCard,
                      items: ['VDPAYS', 'Master Pay', 'Leo Recharge', 'Cash/Other']
                          .map((app) => DropdownMenuItem(
                                value: app,
                                child: Text(app),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedApp = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Remarks / Notes'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  final notes = notesController.text.trim();
                  
                  final provider = Provider.of<ShopProvider>(context, listen: false);
                  await provider.updateTransaction(
                    id: tx.id!,
                    amount: amount,
                    app: selectedApp == 'Cash/Other' ? null : selectedApp,
                    notes: notes,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction updated')),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: AppTheme.creditGreen)),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditProfileDialog(Retailer retailer) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: retailer.name);
    final mobileController = TextEditingController(text: retailer.mobile);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Retailer Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid mobile number' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = Provider.of<ShopProvider>(context, listen: false);
                await provider.updateContact(
                  retailer.id!,
                  nameController.text.trim(),
                  mobileController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.creditGreen)),
          ),
        ],
      ),
    );
  }

  // --- Bottom Sheet forms for Transfers and Credits ---

  void _openTransactionSheet(bool isDebit) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedApp = 'VDPAYS';
    String amountInWords = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateWords(String val) {
              if (val.isEmpty) {
                setModalState(() => amountInWords = '');
                return;
              }
              final amount = double.tryParse(val);
              if (amount != null && amount > 0) {
                setModalState(() => amountInWords = NumberToWords.convert(amount));
              } else {
                setModalState(() => amountInWords = 'Invalid Amount');
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDebit ? 'Send Funds (Debit)' : 'Receive Money (Credit)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDebit ? AppTheme.debitRed : AppTheme.creditGreen,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (Rs.)',
                          prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.primaryIndigo),
                          hintText: 'Enter amount',
                        ),
                        onChanged: updateWords,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final amt = double.tryParse(value);
                          if (amt == null || amt <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                      if (amountInWords.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDebit
                                ? AppTheme.debitRed.withOpacity(0.08)
                                : AppTheme.creditGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDebit
                                  ? AppTheme.debitRed.withOpacity(0.2)
                                  : AppTheme.creditGreen.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            amountInWords,
                            style: TextStyle(
                              color: isDebit ? AppTheme.debitRed : AppTheme.creditGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      // Account Selector chips
                      Text(
                        isDebit ? 'Select Transfer Wallet/Account' : 'Select Deposit Wallet/Account',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Choice chips listing VDPAYS, Master Pay, Leo Recharge (+ Cash for Credits)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: (isDebit
                                ? ['VDPAYS', 'Master Pay', 'Leo Recharge']
                                : ['VDPAYS', 'Master Pay', 'Leo Recharge', 'Cash/Other'])
                            .map((app) {
                          final bool isSelected = selectedApp == app;
                          Color chipColor = AppTheme.primaryIndigo;
                          if (app == 'VDPAYS') chipColor = AppTheme.vdPaysColor;
                          if (app == 'Master Pay') chipColor = AppTheme.masterPayColor;
                          if (app == 'Leo Recharge') chipColor = const Color(0xFFE040FB);
                          if (app == 'Cash/Other') chipColor = AppTheme.creditGreen;

                          return ChoiceChip(
                            label: Text(app),
                            selected: isSelected,
                            selectedColor: chipColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? chipColor : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected ? chipColor : Colors.white10,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => selectedApp = app);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Remarks (Optional)',
                          prefixIcon: Icon(Icons.note, color: AppTheme.primaryIndigo),
                          hintText: 'e.g., Urgently requested, cash settlement',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDebit ? AppTheme.debitRed : AppTheme.creditGreen,
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final amount = double.parse(amountController.text);
                            final notes = notesController.text.trim();
                            final provider = Provider.of<ShopProvider>(context, listen: false);

                            final newTx = TransactionModel(
                              retailerId: widget.retailer.id!,
                              type: isDebit ? 'debit' : 'credit',
                              amount: amount,
                              app: selectedApp,
                              notes: notes.isEmpty ? (isDebit ? 'Transfer via $selectedApp' : 'Received into $selectedApp') : notes,
                              timestamp: DateTime.now(),
                            );

                            await provider.addTransaction(
                              retailerId: newTx.retailerId,
                              type: newTx.type,
                              amount: newTx.amount,
                              app: newTx.app,
                              notes: newTx.notes,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              
                              final outstanding = provider.getRetailerOutstanding(widget.retailer.id!);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    isDebit ? 'Sent Rs. $amount' : 'Got Rs. $amount',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: isDebit ? AppTheme.debitRed : AppTheme.creditGreen,
                                  action: SnackBarAction(
                                    label: 'WhatsApp',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      if (isDebit) {
                                        _sendTransferNotification(newTx, outstanding);
                                      } else {
                                        _sendReceivedNotification(newTx, outstanding);
                                      }
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(isDebit ? 'Confirm Transfer' : 'Confirm Receipt'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, provider, child) {
        final currentRetailer = provider.retailers.firstWhere(
          (r) => r.id == widget.retailer.id,
          orElse: () => widget.retailer,
        );
        final outstanding = provider.getRetailerOutstanding(currentRetailer.id ?? '');
        final transactions = provider.allTransactions.where((t) => t.retailerId == currentRetailer.id).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(currentRetailer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.orangeAccent),
                tooltip: 'Edit Profile',
                onPressed: () => _openEditProfileDialog(currentRetailer),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: AppTheme.accentCyan),
                tooltip: 'Export Statement PDF',
                onPressed: () => _exportPdfStatement(transactions, outstanding),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.debitRed),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Retailer?'),
                      content: Text('Are you sure you want to delete ${currentRetailer.name} and all their transaction histories?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final prov = Provider.of<ShopProvider>(context, listen: false);
                            await prov.deleteRetailer(currentRetailer.id!);
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Delete', style: TextStyle(color: AppTheme.debitRed)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // Outstanding balance card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: outstanding > 0
                          ? AppTheme.debitRed.withOpacity(0.15)
                          : AppTheme.creditGreen.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        outstanding > 0 ? 'REMAINING BALANCE TO GET' : 'SETTLED',
                        style: TextStyle(
                          color: outstanding > 0 ? AppTheme.debitRed : AppTheme.creditGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${outstanding.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: outstanding > 0 ? AppTheme.debitRed : AppTheme.creditGreen,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        NumberToWords.convert(outstanding),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _sendOutstandingBalanceReminder(outstanding),
                              icon: const Icon(Icons.chat, color: AppTheme.creditGreen, size: 18),
                              label: const Text('WA Balance', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _sendTodayTransactionsSummary(transactions, outstanding),
                              icon: const Icon(Icons.today, color: AppTheme.accentCyan, size: 18),
                              label: const Text("Today's Summary", style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Ledger quick entry triggers
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
                        onPressed: () => _openTransactionSheet(true),
                        icon: const Icon(Icons.call_made, size: 16),
                        label: const Text('Send Funds'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.creditGreen),
                        onPressed: () => _openTransactionSheet(false),
                        icon: const Icon(Icons.call_received, size: 16),
                        label: const Text('Receive Money'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Transaction History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade800),
                              const SizedBox(height: 12),
                              const Text(
                                'No transactions yet.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return TransactionTile(
                              transaction: tx,
                              onShare: (transaction) {
                                if (transaction.isDebit) {
                                  _sendTransferNotification(transaction, outstanding);
                                } else {
                                  _sendReceivedNotification(transaction, outstanding);
                                }
                              },
                              onEdit: (transaction) => _openEditTransactionDialog(transaction),
                              onDelete: (transaction) => _confirmDeleteTransaction(transaction),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
