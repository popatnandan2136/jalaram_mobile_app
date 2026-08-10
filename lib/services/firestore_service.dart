import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/retailer.dart';
import '../models/transaction_model.dart';
import '../models/shop_balance.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Contacts Collections (/retailers) ---
  
  static Future<List<Retailer>> getContacts(String type) async {
    final snapshot = await _db.collection('retailers')
        .where('type', isEqualTo: type)
        .orderBy('name')
        .get();
        
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Retailer.fromMap(data);
    }).toList();
  }

  static Future<Retailer> addContact(Retailer contact) async {
    final docRef = _db.collection('retailers').doc();
    final data = contact.toMap();
    data['id'] = docRef.id;
    await docRef.set(data);
    return Retailer.fromMap(data);
  }

  static Future<void> updateContact(String id, String name, String mobile) async {
    await _db.collection('retailers').doc(id).update({
      'name': name,
      'mobile': mobile,
    });
  }

  static Future<void> deleteContact(String id) async {
    // 1. Delete contact
    await _db.collection('retailers').doc(id).delete();
    
    // 2. Delete all linked transactions in cascade
    final txSnapshot = await _db.collection('transactions')
        .where('retailerId', isEqualTo: id)
        .get();
        
    final batch = _db.batch();
    for (var doc in txSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Transactions Collection (/transactions) ---

  static Future<List<TransactionModel>> getTransactions({String? retailerId}) async {
    Query query = _db.collection('transactions');
    if (retailerId != null) {
      query = query.where('retailerId', isEqualTo: retailerId);
    }
    
    final snapshot = await query.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return TransactionModel.fromMap(data);
    }).toList();
  }

  static Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    final docRef = _db.collection('transactions').doc();
    final data = transaction.toMap();
    data['id'] = docRef.id;
    await docRef.set(data);
    return TransactionModel.fromMap(data);
  }

  static Future<void> updateTransaction(String id, double amount, String? app, String? notes) async {
    await _db.collection('transactions').doc(id).update({
      'amount': amount,
      'app': app,
      'notes': notes,
    });
  }

  static Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }

  // --- Shop Balances Collection (/shop_balances) ---

  static Future<List<ShopBalance>> getShopBalances() async {
    final snapshot = await _db.collection('shop_balances')
        .orderBy('timestamp', descending: true)
        .get();
        
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ShopBalance.fromMap(data);
    }).toList();
  }

  static Future<ShopBalance> addShopBalance(ShopBalance balance) async {
    final docRef = _db.collection('shop_balances').doc();
    final data = balance.toMap();
    data['id'] = docRef.id;
    await docRef.set(data);
    return ShopBalance.fromMap(data);
  }
}
