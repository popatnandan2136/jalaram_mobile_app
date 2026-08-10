import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/shop_provider.dart';
import '../models/shop_balance.dart';
import '../utils/number_to_words.dart';
import '../theme/app_theme.dart';

class BalanceHistoryScreen extends StatefulWidget {
  const BalanceHistoryScreen({super.key});

  @override
  State<BalanceHistoryScreen> createState() => _BalanceHistoryScreenState();
}

class _BalanceHistoryScreenState extends State<BalanceHistoryScreen> {
  DateTime? _selectedDate;
  String _selectedApp = 'All'; // 'All', 'VDPAYS', 'Master Pay', 'Leo Recharge', 'Cash/Other'
  List<ShopBalance> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    final provider = Provider.of<ShopProvider>(context, listen: false);
    final list = await provider.getShopBalanceHistory();
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  // Pick a date from the calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Group items by calendar day
  Map<String, List<ShopBalance>> _groupHistoryByDay(List<ShopBalance> items) {
    final Map<String, List<ShopBalance>> groups = {};
    for (var item in items) {
      final String formattedDay = DateFormat('dd MMMM yyyy').format(item.timestamp);
      if (groups[formattedDay] == null) {
        groups[formattedDay] = [];
      }
      groups[formattedDay]!.add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter local history based on selected app and selected date
    List<ShopBalance> filteredHistory = _history.where((item) {
      // Filter by Wallet/App
      if (_selectedApp != 'All' && item.app != _selectedApp) {
        return false;
      }
      // Filter by Date
      if (_selectedDate != null) {
        final itemDate = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
        final filterDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        if (itemDate != filterDate) {
          return false;
        }
      }
      return true;
    }).toList();

    // 2. Group history logs day-wise
    final groupedHistory = _groupHistoryByDay(filteredHistory);
    final sortedDays = groupedHistory.keys.toList(); // Group maps preserve insertion order (sorted DESC by DB query)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Balance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh list',
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter section row (Calendar selection & Selected value chip)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16, color: AppTheme.accentCyan),
                  label: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppTheme.debitRed),
                    tooltip: 'Clear Date Filter',
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          
          // Wallet filters choice chips list
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ['All', 'VDPAYS', 'Master Pay', 'Leo Recharge', 'Cash/Other'].map((app) {
                final bool isSelected = _selectedApp == app;
                Color chipColor = AppTheme.primaryIndigo;
                if (app == 'VDPAYS') chipColor = AppTheme.vdPaysColor;
                if (app == 'Master Pay') chipColor = AppTheme.masterPayColor;
                if (app == 'Leo Recharge') chipColor = const Color(0xFFE040FB);
                if (app == 'Cash/Other') chipColor = AppTheme.creditGreen;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
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
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          
          // Grouped listing scroll area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.list_alt, size: 50, color: Colors.grey.shade800),
                            const SizedBox(height: 12),
                            const Text(
                              'No deposit records found.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: sortedDays.length,
                        itemBuilder: (context, dayIndex) {
                          final dayKey = sortedDays[dayIndex];
                          final dayRecords = groupedHistory[dayKey] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Date Header Row
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  dayKey,
                                  style: const TextStyle(
                                    color: AppTheme.accentCyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Deposits logged on this day
                              ...dayRecords.map((item) {
                                final timeStr = DateFormat('hh:mm a').format(item.timestamp);
                                final words = NumberToWords.convert(item.amount);
                                Color walletColor = AppTheme.primaryIndigo;
                                if (item.app == 'VDPAYS') walletColor = AppTheme.vdPaysColor;
                                if (item.app == 'Master Pay') walletColor = AppTheme.masterPayColor;
                                if (item.app == 'Leo Recharge') walletColor = const Color(0xFFE040FB);
                                if (item.app == 'Cash/Other') walletColor = AppTheme.creditGreen;

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
                                      backgroundColor: walletColor.withOpacity(0.15),
                                      radius: 20,
                                      child: const Icon(
                                        Icons.add,
                                        color: AppTheme.creditGreen,
                                        size: 18,
                                      ),
                                    ),
                                    title: Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        const Text(
                                          'Loaded Balance',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: walletColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.app,
                                            style: TextStyle(
                                              color: walletColor,
                                              fontSize: 9,
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
                                          timeStr,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (item.description != null && item.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12,
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
                                          '+ Rs. ${item.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: AppTheme.creditGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 14,
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
                                                  fontSize: 10,
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                words,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.primaryIndigo,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
