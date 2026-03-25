import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_app/services/desktop_google_auth.dart';

/// Authentication service — Google Sign-In via Firebase Auth.
///
/// Uses `google_sign_in` plugin on mobile/web where it's natively supported.
/// Uses a loopback OAuth flow with PKCE on Windows/macOS/Linux, which opens
/// the system browser for Google consent and catches the redirect on localhost.
///
/// Does NOT force sign-in; the app works fully offline without auth.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;
  String? _error;

  /// Current Firebase user (null if signed out).
  User? get user => _user;

  /// Whether a sign-in/sign-out operation is in progress.
  bool get isLoading => _isLoading;

  /// Whether the user is signed in.
  bool get isSignedIn => _user != null;

  /// The Firebase UID (null if not signed in).
  String? get uid => _user?.uid;

  /// User display name.
  String? get displayName => _user?.displayName;

  /// User email.
  String? get email => _user?.email;

  /// User photo URL.
  String? get photoUrl => _user?.photoURL;

  /// Last error message.
  String? get error => _error;

  /// Whether we're on a desktop platform (Windows/macOS/Linux).
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.linux);

  /// Initialize — listen for auth state changes.
  void init() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
    if (user != null) {
      debugPrint('[AUTH] Signed in: ${user.email} (${user.uid})');
    } else {
      debugPrint('[AUTH] Signed out');
    }
  }

  /// Sign in with Google.
  ///
  /// On mobile/web: uses the `google_sign_in` plugin (native OAuth flow).
  /// On desktop: uses a loopback OAuth flow with PKCE (opens browser).
  ///
  /// Returns true if sign-in was successful, false if cancelled or failed.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isDesktop) {
        return await _signInDesktop();
      } else {
        return await _signInMobile();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] Firebase error: ${e.code} - ${e.message}');
      _error = e.message ?? 'Sign-in failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AUTH] Sign-in error: $e');
      _error = 'Sign-in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Desktop: Loopback OAuth flow — opens browser, catches redirect on localhost.
  Future<bool> _signInDesktop() async {
    final tokens = await DesktopGoogleAuth.signIn();

    if (tokens == null) {
      _error = null; // User cancelled, not an error
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Use the tokens to create a Firebase credential
    final credential = GoogleAuthProvider.credential(
      idToken: tokens['idToken'],
      accessToken: tokens['accessToken'],
    );

    await _auth.signInWithCredential(credential);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Mobile/Web: Native Google Sign-In via the google_sign_in plugin.
  Future<bool> _signInMobile() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isDesktop) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AUTH] Sign-out error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Delete the user's account (Firebase Auth only).
  /// Cloud data deletion is handled by CloudSyncService.
  Future<bool> deleteAccount() async {
    try {
      await _user?.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _error = 'Please sign in again before deleting your account';
      } else {
        _error = e.message ?? 'Account deletion failed';
      }
      notifyListeners();
      return false;
    }
  }
}
