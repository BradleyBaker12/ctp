import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> setupTokenRefresh() async {
    // Listen to token refresh events
    _auth.idTokenChanges().listen((User? user) async {
      if (user != null) {
        // Get new token when it's refreshed
        final token = await user.getIdToken();
        // You could store this token if needed
      }
    });

    // Add listener for auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // Handle signed out state
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  Future<void> refreshToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      await user.getIdToken(true); // Force token refresh
    }
  }
}
