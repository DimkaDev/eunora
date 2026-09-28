import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String _kProductTourPrefKeyPrefix = 'has_seen_product_tour_';

final productTourControllerProvider = StateNotifierProvider<ProductTourNotifier, bool>((ref) {
  return ProductTourNotifier();
});

class ProductTourNotifier extends StateNotifier<bool> {
  ProductTourNotifier() : super(false) {
    checkTourStatus();
  }

  String _getKey() {
    String uid = 'guest';
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    } catch (_) {
      // Firebase not initialized in offline test environment
    }
    return '$_kProductTourPrefKeyPrefix$uid';
  }

  Future<void> checkTourStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_getKey()) ?? false;
    state = hasSeen;
  }

  Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getKey(), true);
    state = true;
  }

  Future<void> resetTourStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getKey(), false);
    state = false;
  }
}
