import 'package:firebase_auth/firebase_auth.dart' as firebase;

class UserModel {
  final String uid;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? tradingName;

  UserModel({
    required this.uid,
    this.email,
    this.firstName,
    this.lastName,
    this.tradingName,
  });

  factory UserModel.fromFirebaseUser(firebase.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
    );
  }

  static UserModel? fromUser(firebase.User? user) {
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }
}
