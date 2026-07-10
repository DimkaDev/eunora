import 'package:flutter_riverpod/flutter_riverpod.dart';

final premiumGuardProvider = StateProvider<bool>((ref) {
  // Free tier by default, can be updated dynamically
  return false;
});
