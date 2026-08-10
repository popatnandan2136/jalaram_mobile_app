import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/shop_provider.dart';
import '../widgets/add_balance_dialog.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_helper.dart';
import 'add_retailer_screen.dart';
import 'add_customer_screen.dart';
import 'retailer_detail_screen.dart';
import 'customer_detail_screen.dart';
import 'balance_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = "";
  String? _selectedMonthKey; // Format: "YYYY-MM"
  String _selectedLedgerTab = 'retailer'; // 'retailer' or 'customer'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShopProvider>(context, listen: false).loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatMonthKey(String key) {
    try {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return key;
    }
  }

  Future<void> _exportShopStatement() async {
    try {
      final provider = Provider.of<ShopProvider>(context, listen: false);
      final assetBundle = DefaultAssetBundle.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating Shop Statement PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      final shopBalances = await provider.getShopBalanceHistory();

      // Read logo asset bytes
      Uint8List? logoBytes;
      try {
        final byteData = await assetBundle.load('assets/images/logo.jpg');
        logoBytes = byteData.buffer.asUint8List();
      } catch (_) {}

      final Map<String, String> contactNames = {};
      for (var r in provider.retailers) {
        if (r.id != null) contactNames[r.id!] = r.name;
      }
      for (var c in provider.customers) {
        if (c.id != null) contactNames[c.id!] = c.name;
      }

      final filePath = await PdfHelper.generateShopStatement(
        totalShopBalance: provider.totalShopBalance,
        walletBalances: provider.walletBalances,
        transactions: provider.allTransactions,
        shopBalances: shopBalances,
        contactNames: contactNames,
        logoBytes: logoBytes,
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
              'Shop statement saved:\n${filePath.split(Platform.pathSeparator).last}',
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
                  Share.shareXFiles([XFile(filePath)], text: 'NP Digital Shop Statement');
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
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.debitRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Provider.of<ShopProvider>(context, listen: false).loadData(),
          color: AppTheme.primaryIndigo,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBalanceCard(),
                const SizedBox(height: 24),
                _buildMonthlySalesBlock(),
                const SizedBox(height: 24),
                _buildRetailersSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedLedgerTab == 'retailer') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddRetailerScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
            );
          }
        },
        icon: const Icon(Icons.person_add),
        label: Text(_selectedLedgerTab == 'retailer' ? 'Add Retailer' : 'Add Customer'),
        backgroundColor: _selectedLedgerTab == 'retailer' ? AppTheme.primaryIndigo : Colors.orangeAccent,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryIndigo, AppTheme.accentCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryIndigo.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27.5),
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'NP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'NP Digital',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: AppTheme.accentCyan, size: 28),
          tooltip: 'Export Shop Statement',
          onPressed: _exportShopStatement,
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Consumer<ShopProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceCard,
                AppTheme.primaryIndigo.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppTheme.primaryIndigo.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryIndigo.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL SHOP BALANCE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history, color: AppTheme.textSecondary, size: 24),
                          tooltip: 'View Deposit History',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BalanceHistoryScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTheme.accentCyan, size: 28),
                          tooltip: 'Add incoming balance to shop',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const AddBalanceDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${provider.totalShopBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                const Text(
                  'WALLET ACCOUNT BALANCES',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: provider.walletBalances.entries.map((entry) {
                      final walletName = entry.key;
                      final walletBalance = entry.value;
                      
                      Color walletColor = AppTheme.primaryIndigo;
                      if (walletName == 'VDPAYS') walletColor = AppTheme.vdPaysColor;
                      if (walletName == 'Master Pay') walletColor = AppTheme.masterPayColor;
                      if (walletName == 'Leo Recharge') walletColor = const Color(0xFFE040FB);
                      if (walletName == 'Cash/Other') walletColor = AppTheme.creditGreen;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: walletColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              walletName,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${walletBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: walletColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Incoming Balance",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+ Rs. ${provider.todayIncomingBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.creditGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.trending_up,
                      color: AppTheme.creditGreen.withOpacity(0.8),
                      size: 28,
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySalesBlock() {
    return Consumer<ShopProvider>(
      builder: (context, provider, child) {
        final salesData = provider.monthlySales;
        if (salesData.isEmpty) {
          return const SizedBox.shrink();
        }

        final monthKeys = salesData.keys.toList();
        if (_selectedMonthKey == null || !monthKeys.contains(_selectedMonthKey)) {
          _selectedMonthKey = monthKeys.last;
        }

        final double selectedMonthSales = salesData[_selectedMonthKey] ?? 0.0;
        final double maxSales = salesData.values.fold(1.0, (prev, element) => element > prev ? element : prev);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Analytics (Month Wise)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthKeys.map((key) {
                      final sales = salesData[key] ?? 0.0;
                      final isSelected = key == _selectedMonthKey;
                      
                      final double heightFactor = maxSales > 0 ? (sales / maxSales) : 0.0;
                      
                      String label = key;
                      try {
                        final date = DateTime(int.parse(key.split('-')[0]), int.parse(key.split('-')[1]));
                        label = DateFormat('MMM').format(date);
                      } catch (_) {}

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonthKey = key;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              sales > 0 ? '${(sales / 1000).toStringAsFixed(1)}k' : '0',
                              style: TextStyle(
                                color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 32,
                              height: (heightFactor * 70).clamp(6.0, 70.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [AppTheme.accentCyan, AppTheme.primaryIndigo]
                                      : [Colors.grey.shade800, Colors.grey.shade700],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accentCyan.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),

                if (_selectedMonthKey != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatMonthKey(_selectedMonthKey!),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Total Transfers (Debit)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sells/Outgoing:',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      Text(
                        'Rs. ${selectedMonthSales.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.debitRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRetailersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedLedgerTab == 'retailer' ? 'Retailers Ledger' : 'Customers Ledger',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Consumer<ShopProvider>(
              builder: (context, provider, child) {
                final count = _selectedLedgerTab == 'retailer'
                    ? provider.retailers.length
                    : provider.customers.length;
                return Text(
                  '$count ${ _selectedLedgerTab == 'retailer' ? "Retailers" : "Customers"}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                );
              },
            )
          ],
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _selectedLedgerTab == 'retailer'
                ? 'Search retailer name or mobile...'
                : 'Search customer name or mobile...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = "";
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 16),

        // Tab Selector Row (Retailer vs Customer)
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Retailers')),
                selected: _selectedLedgerTab == 'retailer',
                selectedColor: AppTheme.primaryIndigo.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: _selectedLedgerTab == 'retailer' ? AppTheme.primaryIndigo : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide(
                  color: _selectedLedgerTab == 'retailer' ? AppTheme.primaryIndigo : Colors.white10,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedLedgerTab = 'retailer';
                      _searchQuery = "";
                      _searchController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Customers')),
                selected: _selectedLedgerTab == 'customer',
                selectedColor: Colors.orangeAccent.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: _selectedLedgerTab == 'customer' ? Colors.orangeAccent : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide(
                  color: _selectedLedgerTab == 'customer' ? Colors.orangeAccent : Colors.white10,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedLedgerTab = 'customer';
                      _searchQuery = "";
                      _searchController.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Consumer<ShopProvider>(
          builder: (context, provider, child) {
            final activeList = _selectedLedgerTab == 'retailer'
                ? provider.retailers
                : provider.customers;

            if (activeList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      _selectedLedgerTab == 'retailer' ? Icons.storefront : Icons.people_outline,
                      size: 60,
                      color: Colors.grey.shade800,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedLedgerTab == 'retailer'
                          ? 'No retailers added yet.'
                          : 'No customers added yet.',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLedgerTab == 'retailer'
                          ? 'Click "Add Retailer" below to start.'
                          : 'Click "Add Customer" below to start.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            final filteredContacts = activeList.where((contact) {
              return contact.name.toLowerCase().contains(_searchQuery) ||
                  contact.mobile.contains(_searchQuery);
            }).toList();

            if (filteredContacts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No matches found.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                final outstanding = provider.getRetailerOutstanding(contact.id ?? '');
                final isRetailer = _selectedLedgerTab == 'retailer';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isRetailer
                          ? AppTheme.primaryIndigo.withOpacity(0.1)
                          : Colors.orangeAccent.withOpacity(0.1),
                      child: Text(
                        contact.name.substring(0, contact.name.isNotEmpty ? 1 : 0).toUpperCase(),
                        style: TextStyle(
                          color: isRetailer ? AppTheme.primaryIndigo : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        contact.mobile,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          outstanding > 0 ? 'Owes' : 'Settled',
                          style: TextStyle(
                            color: outstanding > 0
                                ? (isRetailer ? AppTheme.debitRed : Colors.orangeAccent)
                                : AppTheme.creditGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${outstanding.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: outstanding > 0
                                ? (isRetailer ? AppTheme.debitRed : Colors.orangeAccent)
                                : AppTheme.creditGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (isRetailer) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RetailerDetailScreen(retailer: contact),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailScreen(customer: contact),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
