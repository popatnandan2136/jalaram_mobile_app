import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/retailer.dart';
import '../models/transaction_model.dart';
import '../models/shop_balance.dart';

class ShopProvider with ChangeNotifier {
  List<Retailer> _retailers = [];
  List<Retailer> _customers = [];
  double _totalShopBalance = 0.0;
  double _todayIncomingBalance = 0.0;
  final Map<String, double> _retailerBalances = {};
  Map<String, double> _monthlySales = {};
  List<TransactionModel> _allTransactions = [];
  Map<String, double> _walletBalances = {
    'VDPAYS': 0.0,
    'Master Pay': 0.0,
    'Leo Recharge': 0.0,
    'Cash/Other': 0.0,
  };

  // Getters
  List<Retailer> get retailers => _retailers;
  List<Retailer> get customers => _customers;
  double get totalShopBalance => _totalShopBalance;
  double get todayIncomingBalance => _todayIncomingBalance;
  List<TransactionModel> get allTransactions => _allTransactions;
  Map<String, double> get monthlySales => _monthlySales;
  Map<String, double> get walletBalances => _walletBalances;

  ShopProvider() {
    _initFirestoreListeners();
  }

  // Set up real-time stream listeners to Firestore
  void _initFirestoreListeners() {
    final db = FirebaseFirestore.instance;

    // 1. Listen to contact profiles (retailers & customers)
    db.collection('retailers').orderBy('name').snapshots().listen((snapshot) {
      final contacts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Retailer.fromMap(data);
      }).toList();

      _retailers = contacts.where((c) => c.type == 'retailer').toList();
      _customers = contacts.where((c) => c.type == 'customer').toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint("Firestore retailers stream error: $e");
    });

    // 2. Keep local copy lists for reactive aggregates calculation
    List<TransactionModel> localTxs = [];
    List<ShopBalance> localBalances = [];

    void recalculateMetrics() {
      double totalAdded = 0.0;
      Map<String, double> walletAdded = {
        'VDPAYS': 0.0,
        'Master Pay': 0.0,
        'Leo Recharge': 0.0,
        'Cash/Other': 0.0
      };
      
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      double todayIncoming = 0.0;

      for (var item in localBalances) {
        final double amt = item.amount;
        final String app = item.app;
        final String timestamp = item.timestamp.toIso8601String();

        totalAdded += amt;
        if (walletAdded.containsKey(app)) {
          walletAdded[app] = (walletAdded[app] ?? 0.0) + amt;
        }
        if (timestamp.startsWith(todayStr)) {
          todayIncoming += amt;
        }
      }

      double totalDebits = 0.0;
      double totalCredits = 0.0;

      Map<String, double> walletDebits = {
        'VDPAYS': 0.0,
        'Master Pay': 0.0,
        'Leo Recharge': 0.0,
        'Cash/Other': 0.0
      };
      Map<String, double> walletCredits = {
        'VDPAYS': 0.0,
        'Master Pay': 0.0,
        'Leo Recharge': 0.0,
        'Cash/Other': 0.0
      };

      _retailerBalances.clear();
      _monthlySales.clear();

      for (var tx in localTxs) {
        final double amt = tx.amount;
        final String type = tx.type;
        final String? app = tx.app;
        final String contactId = tx.retailerId;
        final String timestamp = tx.timestamp.toIso8601String();

        if (type == 'debit') {
          totalDebits += amt;
          if (app != null && walletDebits.containsKey(app)) {
            walletDebits[app] = (walletDebits[app] ?? 0.0) + amt;
          }
          _retailerBalances[contactId] = (_retailerBalances[contactId] ?? 0.0) + amt;

          try {
            final monthKey = timestamp.substring(0, 7);
            _monthlySales[monthKey] = (_monthlySales[monthKey] ?? 0.0) + amt;
          } catch (_) {}
        } else {
          totalCredits += amt;
          if (app != null && walletCredits.containsKey(app)) {
            walletCredits[app] = (walletCredits[app] ?? 0.0) + amt;
          }
          _retailerBalances[contactId] = (_retailerBalances[contactId] ?? 0.0) - amt;
        }
      }

      _totalShopBalance = totalAdded - totalDebits + totalCredits;
      _todayIncomingBalance = todayIncoming;
      
      _walletBalances.clear();
      for (var app in ['VDPAYS', 'Master Pay', 'Leo Recharge', 'Cash/Other']) {
        _walletBalances[app] = (walletAdded[app] ?? 0.0) - (walletDebits[app] ?? 0.0) + (walletCredits[app] ?? 0.0);
      }
      
      _allTransactions = localTxs;
      notifyListeners();
    }

    // Listen to transaction updates
    db.collection('transactions').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      localTxs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TransactionModel.fromMap(data);
      }).toList();
      recalculateMetrics();
    }, onError: (e) {
      debugPrint("Firestore transactions stream error: $e");
    });

    // Listen to shop balances deposits
    db.collection('shop_balances').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      localBalances = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ShopBalance.fromMap(data);
      }).toList();
      recalculateMetrics();
    }, onError: (e) {
      debugPrint("Firestore shop_balances stream error: $e");
    });
  }

  // Keeps compatibility for manual calls, though stream listeners sync everything in background
  Future<void> loadData() async {
    // No-op since listeners handle data fetching in real-time
    return;
  }

  Future<void> fetchRetailers() async {
    return;
  }

  Future<void> fetchShopBalanceInfo() async {
    return;
  }

  Future<void> fetchAllTransactions() async {
    return;
  }

  Future<void> fetchMonthlySales() async {
    return;
  }

  double getRetailerOutstanding(String retailerId) {
    return _retailerBalances[retailerId] ?? 0.0;
  }

  Future<List<TransactionModel>> getTransactionsForRetailer(String retailerId) async {
    return await FirestoreService.getTransactions(retailerId: retailerId);
  }

  // Add a new retailer
  Future<void> addRetailer(String name, String mobile) async {
    final retailer = Retailer(
      name: name,
      mobile: mobile,
      createdAt: DateTime.now(),
      type: 'retailer',
    );
    await FirestoreService.addContact(retailer);
  }

  // Add a new customer
  Future<void> addCustomer(String name, String mobile) async {
    final customer = Retailer(
      name: name,
      mobile: mobile,
      createdAt: DateTime.now(),
      type: 'customer',
    );
    await FirestoreService.addContact(customer);
  }

  // Remove a contact (retailer or customer)
  Future<void> deleteRetailer(String id) async {
    await FirestoreService.deleteContact(id);
  }

  // Add direct incoming shop balance
  Future<void> addShopBalance({
    required double amount,
    required String app,
    String? description,
  }) async {
    final balance = ShopBalance(
      amount: amount,
      timestamp: DateTime.now(),
      app: app,
      description: description,
    );
    await FirestoreService.addShopBalance(balance);
  }

  // Add a transaction (Debit or Credit)
  Future<void> addTransaction({
    required String retailerId,
    required String type,
    required double amount,
    String? app,
    String? notes,
  }) async {
    final transaction = TransactionModel(
      retailerId: retailerId,
      type: type,
      amount: amount,
      app: app,
      timestamp: DateTime.now(),
      notes: notes,
    );
    await FirestoreService.addTransaction(transaction);
  }

  // Get shop balance deposit history logs
  Future<List<ShopBalance>> getShopBalanceHistory() async {
    return await FirestoreService.getShopBalances();
  }

  // Update contact profile details
  Future<void> updateContact(String id, String name, String mobile) async {
    await FirestoreService.updateContact(id, name, mobile);
  }

  // Update transaction details
  Future<void> updateTransaction({
    required String id,
    required double amount,
    String? app,
    String? notes,
  }) async {
    await FirestoreService.updateTransaction(id, amount, app, notes);
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    await FirestoreService.deleteTransaction(id);
  }
}
