import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/number_to_words.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final Function(TransactionModel)? onShare;
  final Function(TransactionModel)? onEdit;
  final Function(TransactionModel)? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onShare,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDebit = transaction.isDebit;
    final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(transaction.timestamp);
    final String amountInWords = NumberToWords.convert(transaction.amount);

    Color badgeColor;
    String badgeText;

    if (isDebit) {
      if (transaction.app == 'VDPAYS') {
        badgeColor = AppTheme.vdPaysColor;
        badgeText = 'VP';
      } else if (transaction.app == 'Master Pay') {
        badgeColor = AppTheme.masterPayColor;
        badgeText = 'MP';
      } else if (transaction.app == 'Leo Recharge') {
        badgeColor = const Color(0xFFE040FB); // Magenta/Violet
        badgeText = 'LR';
      } else {
        badgeColor = AppTheme.primaryIndigo;
        badgeText = 'TX';
      }
    } else {
      if (transaction.app == 'VDPAYS') {
        badgeColor = AppTheme.vdPaysColor;
        badgeText = 'VP';
      } else if (transaction.app == 'Master Pay') {
        badgeColor = AppTheme.masterPayColor;
        badgeText = 'MP';
      } else if (transaction.app == 'Leo Recharge') {
        badgeColor = const Color(0xFFE040FB);
        badgeText = 'LR';
      } else {
        badgeColor = AppTheme.creditGreen;
        badgeText = 'RC';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.03),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.15),
          radius: 22,
          child: Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              isDebit ? 'Transferred' : 'Received',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (transaction.app != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.app!,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transaction.notes!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDebit ? "-" : "+"} Rs. ${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isDebit ? AppTheme.debitRed : AppTheme.creditGreen,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount in Words:',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amountInWords,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryIndigo,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (onShare != null || onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onDelete != null)
                          Tooltip(
                            message: 'Delete',
                            child: IconButton(
                              onPressed: () => onDelete!(transaction),
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.debitRed),
                            ),
                          ),
                        if (onEdit != null)
                          Tooltip(
                            message: 'Edit',
                            child: IconButton(
                              onPressed: () => onEdit!(transaction),
                              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orangeAccent),
                            ),
                          ),
                        if (onShare != null)
                          Tooltip(
                            message: 'Share Receipt',
                            child: IconButton(
                              onPressed: () => onShare!(transaction),
                              icon: const Icon(Icons.share, size: 20, color: AppTheme.creditGreen),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
