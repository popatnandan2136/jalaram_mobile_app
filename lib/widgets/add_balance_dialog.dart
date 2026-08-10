import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../utils/number_to_words.dart';
import '../theme/app_theme.dart';

class AddBalanceDialog extends StatefulWidget {
  const AddBalanceDialog({super.key});

  @override
  State<AddBalanceDialog> createState() => _AddBalanceDialogState();
}

class _AddBalanceDialogState extends State<AddBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedApp = 'Cash/Other';
  String _amountInWords = "";

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _updateAmountInWords(String value) {
    if (value.isEmpty) {
      setState(() {
        _amountInWords = "";
      });
      return;
    }
    final double? amount = double.tryParse(value);
    if (amount != null && amount > 0) {
      setState(() {
        _amountInWords = NumberToWords.convert(amount);
      });
    } else {
      setState(() {
        _amountInWords = "Invalid Amount";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apps = ['VDPAYS', 'Master Pay', 'Leo Recharge', 'Cash/Other'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surfaceCard,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Shop Balance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (Rs.)',
                    prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.primaryIndigo),
                    hintText: 'Enter incoming amount',
                  ),
                  onChanged: _updateAmountInWords,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final double? amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                if (_amountInWords.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryIndigo.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      _amountInWords,
                      style: const TextStyle(
                        color: AppTheme.primaryIndigo,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Select Destination Account',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: apps.map((app) {
                    final bool isSelected = _selectedApp == app;
                    Color chipColor = AppTheme.primaryIndigo;
                    if (app == 'VDPAYS') chipColor = AppTheme.vdPaysColor;
                    if (app == 'Master Pay') chipColor = AppTheme.masterPayColor;
                    if (app == 'Leo Recharge') chipColor = const Color(0xFFE040FB); // Violet/Pink

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
                          setState(() {
                            _selectedApp = app;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description, color: AppTheme.primaryIndigo),
                    hintText: 'e.g., Cash Deposit, Bank Transfer',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final amount = double.parse(_amountController.text);
                      final desc = _descController.text.trim();
                      final provider = Provider.of<ShopProvider>(context, listen: false);
                      
                      await provider.addShopBalance(
                        amount: amount,
                        app: _selectedApp,
                        description: desc.isEmpty ? 'Direct Wallet Load' : desc,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Rs. $amount loaded into $_selectedApp successfully!'),
                            backgroundColor: AppTheme.creditGreen,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add Balance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
