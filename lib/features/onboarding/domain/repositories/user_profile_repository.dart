import 'package:eunora/features/onboarding/domain/models/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> getProfile(String uid);
  Future<void> saveProfile(UserProfile profile);
}
