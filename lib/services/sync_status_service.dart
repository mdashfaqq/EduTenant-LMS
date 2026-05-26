import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Enum representing the current sync status
enum SyncStatus { offline, syncing, synchronized, error }

/// Model for sync status information
class SyncStatusInfo {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final int pendingChanges;

  const SyncStatusInfo({
    required this.status,
    this.lastSyncTime,
    this.errorMessage,
    this.pendingChanges = 0,
  });

  SyncStatusInfo copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    String? errorMessage,
    int? pendingChanges,
  }) {
    return SyncStatusInfo(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingChanges: pendingChanges ?? this.pendingChanges,
    );
  }

  String get statusText {
    switch (status) {
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synchronized:
        return 'Synchronized';
      case SyncStatus.error:
        return 'Sync Error';
    }
  }

  String get timeAgo {
    if (lastSyncTime == null) return 'Never synced';

    final difference = DateTime.now().difference(lastSyncTime!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Service to manage sync status across the application
class SyncStatusService extends ChangeNotifier {
  static final SyncStatusService instance = SyncStatusService._init();

  SyncStatusService._init() {
    _initConnectivityMonitoring();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncStatusInfo _currentStatus = const SyncStatusInfo(
    status: SyncStatus.offline,
    lastSyncTime: null,
    pendingChanges: 0,
  );

  bool _isOnline = false;
  bool _isSyncing = false;
  Timer? _syncTimer;

  SyncStatusInfo get currentStatus => _currentStatus;
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  void _initConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (_isOnline && !wasOnline) {
      // Just came online, trigger sync
      _startAutoSync();
    } else if (!_isOnline && wasOnline) {
      // Just went offline
      _updateStatus(SyncStatus.offline);
      _stopAutoSync();
    }
  }

  /// Update the current sync status
  void _updateStatus(SyncStatus status, {String? errorMessage}) {
    _currentStatus = _currentStatus.copyWith(
      status: status,
      lastSyncTime: status == SyncStatus.synchronized
          ? DateTime.now()
          : _currentStatus.lastSyncTime,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  /// Start automatic sync when online
  void _startAutoSync() {
    _syncTimer?.cancel();
    performSync();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        performSync();
      }
    });
  }

  /// Stop automatic sync
  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Manually trigger a sync operation
  Future<void> performSync() async {
    if (!_isOnline) {
      _updateStatus(SyncStatus.offline);
      return;
    }

    if (_isSyncing) return;
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      // Simulate sync operation
      await Future.delayed(const Duration(seconds: 2));

      // In real implementation, sync with backend here
      // await _syncWithBackend();

      if (_isOnline) {
        _updateStatus(SyncStatus.synchronized);
      } else {
        _updateStatus(SyncStatus.offline);
      }
    } catch (e) {
      _updateStatus(SyncStatus.error, errorMessage: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Update pending changes count
  void updatePendingChanges(int count) {
    _currentStatus = _currentStatus.copyWith(pendingChanges: count);
    notifyListeners();
  }

  /// Force offline mode (for testing)
  void setOfflineMode(bool offline) {
    _isOnline = !offline;
    _updateStatus(offline ? SyncStatus.offline : SyncStatus.synchronized);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
