import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/email_api.dart';
import '../../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository}) : _repository = repository {
    _subscription = _repository.authStateChanges().listen(_onAuthStateChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _subscription;

  User? _user;
  bool _isInitialising = true;
  bool _isProcessing = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isInitialising => _isInitialising;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_isProcessing) {
      return;
    }
    _setProcessing(true);
    try {
      await _repository.signInWithEmail(email: email, password: password);
      _errorMessage = null;
    } on FirebaseAuthException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to sign in: $error\n$stackTrace');
      }
      _errorMessage = _mapFirebaseError(error);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to sign in: $error\n$stackTrace');
      }
      _errorMessage = 'Could not sign in. Please try again.';
    } finally {
      _setProcessing(false);
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_isProcessing) {
      return;
    }
    _setProcessing(true);
    try {
      await _repository.signUpWithEmail(name: name, email: email, password: password);
      _errorMessage = null;
    } on FirebaseAuthException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to sign up: $error\n$stackTrace');
      }
      _errorMessage = _mapFirebaseError(error);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to sign up: $error\n$stackTrace');
      }
      _errorMessage = 'Could not sign up. Please try again.';
    } finally {
      _setProcessing(false);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isProcessing) {
      return;
    }
    _setProcessing(true);
    try {
      await _repository.signOut();
      _errorMessage = null;
    } on FirebaseAuthException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to sign out: $error\n$stackTrace');
      }
      _errorMessage = _mapFirebaseError(error);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to sign out: $error\n$stackTrace');
      }
      _errorMessage = 'Could not sign out. Please try again.';
    } finally {
      _setProcessing(false);
      notifyListeners();
    }
  }

  /// Requests a reset OTP by email. Returns true if the request was accepted.
  Future<bool> requestPasswordOtp(String email) async {
    _setProcessing(true);
    notifyListeners();
    try {
      await _repository.requestPasswordOtp(email);
      _errorMessage = null;
      return true;
    } on EmailApiException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to request OTP: $error\n$stackTrace');
      }
      _errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to request OTP: $error\n$stackTrace');
      }
      _errorMessage = 'Could not send the reset code. Please try again.';
      return false;
    } finally {
      _setProcessing(false);
      notifyListeners();
    }
  }

  /// Verifies the OTP and sets a new password. Returns true on success.
  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setProcessing(true);
    notifyListeners();
    try {
      await _repository.resetPasswordWithOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _errorMessage = null;
      return true;
    } on EmailApiException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to reset password: $error\n$stackTrace');
      }
      _errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to reset password: $error\n$stackTrace');
      }
      _errorMessage = 'Could not reset the password. Please try again.';
      return false;
    } finally {
      _setProcessing(false);
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    _isInitialising = false;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    if (_isProcessing == value) {
      return;
    }
    _isProcessing = value;
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'configuration-not-found':
        return 'Email/password sign-in is not enabled for this project. Enable it in the Firebase console.';
      case 'email-already-in-use':
        return 'That email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'user-not-found':
        return 'No account found for that email. Create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
