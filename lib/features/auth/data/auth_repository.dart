import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/email_api.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    EmailApiClient? emailApi,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _emailApi = emailApi ?? EmailApiClient();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EmailApiClient _emailApi;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.toLowerCase();
    return _auth.signInWithEmailAndPassword(email: normalizedEmail, password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    await credential.user?.updateDisplayName(name);
    await credential.user?.reload();

    final docRef = _firestore.collection('users').doc(credential.user!.uid);
    await docRef.set({
      'displayName': name,
      'email': normalizedEmail,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Fire-and-forget welcome email. If the email server is down, slow, or
    // unconfigured, sign-up must still complete immediately and succeed — the
    // email is best-effort and never awaited here.
    unawaited(_sendWelcomeEmail(credential.user));

    return credential;
  }

  Future<void> _sendWelcomeEmail(User? user) async {
    try {
      final token = await user?.getIdToken();
      if (token != null) {
        await _emailApi.sendWelcome(token);
      }
    } catch (_) {
      // Best-effort only; ignore any email failure.
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Requests a password-reset OTP to be emailed to [email].
  Future<void> requestPasswordOtp(String email) {
    return _emailApi.requestOtp(email.trim().toLowerCase());
  }

  /// Verifies the OTP and sets a new password.
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _emailApi.resetPassword(
      email: email.trim().toLowerCase(),
      otp: otp.trim(),
      newPassword: newPassword,
    );
  }
}
