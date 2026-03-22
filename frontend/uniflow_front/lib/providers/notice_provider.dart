import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notice_model.dart';
import '../models/student_info.dart';
import '../models/user_preference.dart';
import '../services/api_service.dart';
import '../services/sort_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class NoticeProvider extends ChangeNotifier {
  NoticeProvider({
    required ApiService apiService,
    required StorageService storageService,
    required SortService sortService,
  })  : _apiService = apiService,
        _storageService = storageService,
        _sortService = sortService;

  final ApiService _apiService;
  final StorageService _storageService;
  final SortService _sortService;

  final List<NoticeModel> _rawNotices = <NoticeModel>[];
  List<NoticeModel> _sortedNotices = <NoticeModel>[];
  StudentInfo? _studentInfo;
  UserPreference _preference = UserPreference.empty();
  Timer? _autoRefreshTimer;

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialized = false;
  String? _errorMessage;
  int _currentPage = 1;

  List<NoticeModel> get notices =>
      List<NoticeModel>.unmodifiable(_sortedNotices);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get initialized => _initialized;
  String? get errorMessage => _errorMessage;

  Future<void> initialize({
    required StudentInfo? studentInfo,
    required UserPreference preference,
    bool deferRemoteRefresh = false,
  }) async {
    _studentInfo = studentInfo;
    _preference = preference;
    _applyOperationalSettings();

    final cache = await _storageService.loadNotices();
    _rawNotices
      ..clear()
      ..addAll(cache);
    _resort();
    _initialized = true;
    notifyListeners();

    if (deferRemoteRefresh) {
      unawaited(
        Future<void>.microtask(
          () => refreshNotices(showLoading: _rawNotices.isEmpty),
        ),
      );
      return;
    }

    await refreshNotices(showLoading: _rawNotices.isEmpty);
  }

  void applyPersonalization({
    required StudentInfo? studentInfo,
    required UserPreference preference,
  }) {
    _studentInfo = studentInfo;
    _preference = preference;
    _applyOperationalSettings();
    _resort();
    notifyListeners();
  }

  Future<bool> refreshNotices({bool showLoading = false}) async {
    if (_isRefreshing || _isLoading) {
      return false;
    }

    if (showLoading) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchNotices(
        page: 1,
        pageSize: AppConstants.pageSize,
        sortMode: _preference.homeSortMode,
      );
      _currentPage = 1;
      _hasMore = response.length >= AppConstants.pageSize;
      _rawNotices
        ..clear()
        ..addAll(response);
      _resort();
      await _storageService.saveNotices(_rawNotices);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      if (_rawNotices.isEmpty) {
        final cache = await _storageService.loadNotices();
        _rawNotices
          ..clear()
          ..addAll(cache);
        _resort();
      }
      return false;
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return false;
    }
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.fetchNotices(
        page: nextPage,
        pageSize: AppConstants.pageSize,
        sortMode: _preference.homeSortMode,
      );
      if (response.isEmpty) {
        _hasMore = false;
        return true;
      }

      final existedIds = _rawNotices.map((item) => item.id).toSet();
      for (final item in response) {
        if (!existedIds.contains(item.id)) {
          _rawNotices.add(item);
        }
      }
      _currentPage = nextPage;
      _hasMore = response.length >= AppConstants.pageSize;
      _resort();
      await _storageService.saveNotices(_rawNotices);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    _rawNotices.clear();
    _sortedNotices = <NoticeModel>[];
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    await _storageService.clearNoticeCache();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    _rawNotices.clear();
    _sortedNotices = <NoticeModel>[];
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    _autoRefreshTimer?.cancel();
    await _storageService.clearNoticeCache();
    notifyListeners();
  }

  void _resort() {
    _sortedNotices = _sortService.sortNotices(
      notices: List<NoticeModel>.from(_rawNotices),
      studentInfo: _studentInfo,
      preference: _preference,
    );
  }

  void _applyOperationalSettings() {
    _apiService.updateSource(_preference.activeApiSource);
    _configureAutoRefresh(_preference.resolvedAutoRefreshMinutes);
  }

  void _configureAutoRefresh(int minutes) {
    _autoRefreshTimer?.cancel();
    if (minutes <= 0) {
      return;
    }

    _autoRefreshTimer = Timer.periodic(
      Duration(minutes: minutes),
      (_) {
        if (!_isLoading && !_isRefreshing && !_isLoadingMore) {
          refreshNotices();
        }
      },
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
