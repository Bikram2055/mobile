import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/connection_repository.dart';

class ConnectionController extends ChangeNotifier {
  ConnectionController({required ConnectionRepository repository})
      : _repository = repository;

  final ConnectionRepository _repository;

  StreamSubscription<List<ConnectionRecord>>? _subscription;
  List<ConnectionRecord> _connections = <ConnectionRecord>[];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;

  List<ConnectionRecord> get connections => List.unmodifiable(_connections);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void attachUser(String? userId) {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    _connections = <ConnectionRecord>[];
    _errorMessage = null;
    _subscription?.cancel();
    notifyListeners();

    if (_userId != null) {
      _listenToConnections();
    }
  }

  Future<bool> sendRequest(String email) async {
    if (_userId == null) {
      _errorMessage = 'Sign in first.';
      notifyListeners();
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      _errorMessage = 'Enter an email to connect.';
      notifyListeners();
      return false;
    }

    try {
      final targetId = await _repository.findUserIdByEmail(normalizedEmail);
      if (targetId == null) {
        _errorMessage = 'No user found with that email.';
        notifyListeners();
        return false;
      }

      if (targetId == _userId) {
        _errorMessage = 'You cannot connect with yourself.';
        notifyListeners();
        return false;
      }

      final alreadyConnected = _connections.any((record) => record.userId == targetId);
      if (alreadyConnected) {
        _errorMessage = 'You already have a connection or request with this user.';
        notifyListeners();
        return false;
      }

      await _repository.sendConnectionRequest(
        fromUserId: _userId!,
        toUserId: targetId,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to send request: $error\n$stackTrace');
      _errorMessage = 'Unable to send request. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> accept(String otherUserId) async {
    if (_userId == null) {
      return;
    }
    try {
      await _repository.acceptConnection(userId: _userId!, otherUserId: otherUserId);
      _errorMessage = null;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Failed to accept connection: $error\n$stackTrace');
      _errorMessage = 'Could not accept the request.';
      notifyListeners();
    }
  }

  Future<void> decline(String otherUserId) async {
    if (_userId == null) {
      return;
    }
    try {
      await _repository.declineConnection(userId: _userId!, otherUserId: otherUserId);
      _errorMessage = null;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Failed to decline connection: $error\n$stackTrace');
      _errorMessage = 'Could not decline the request.';
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _listenToConnections() {
    _setLoading(true);
    _subscription = _repository.watchConnections(_userId!).listen(
      (records) {
        _connections = records;
        _setLoading(false);
      },
      onError: (error, stackTrace) {
        debugPrint('Failed to load connections: $error\n$stackTrace');
        _errorMessage = 'Unable to load connections.';
        _setLoading(false);
      },
    );
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
