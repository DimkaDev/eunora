import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirestoreService _firestoreService;

  UserProfileRepositoryImpl(this._firestoreService);

  @override
  Future<UserProfile?> getProfile(String uid) {
    return _firestoreService.getUserProfile(uid);
  }

  @override
  Future<void> saveProfile(UserProfile profile) {
    return _firestoreService.saveUserProfile(profile);
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryImpl(ref.read(firestoreServiceProvider));
});
