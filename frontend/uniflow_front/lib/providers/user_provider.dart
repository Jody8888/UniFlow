import 'package:flutter/foundation.dart';

import '../models/student_info.dart';
import '../models/user_preference.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    required StorageService storageService,
  }) : _storageService = storageService;

  final StorageService _storageService;

  StudentInfo? _studentInfo;
  UserPreference _preference = UserPreference.empty();
  bool _initialized = false;

  StudentInfo? get studentInfo => _studentInfo;
  UserPreference get preference => _preference;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    _studentInfo = await _storageService.loadStudentInfo();
    _preference = await _storageService.loadPreference();
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveStudentInfo(StudentInfo info) async {
    _studentInfo = info;
    await _storageService.saveStudentInfo(info);
    notifyListeners();
  }

  Future<void> markNoticeRead(String noticeId) async {
    final nextReadIds = Set<String>.from(_preference.readNoticeIds)
      ..add(noticeId);
    _preference = _preference.copyWith(readNoticeIds: nextReadIds);
    await _storageService.savePreference(_preference);
    notifyListeners();
  }

  Future<void> addDislikedGenre(String genre) async {
    final genres = Set<String>.from(_preference.dislikedGenres)..add(genre);
    _preference = _preference.copyWith(dislikedGenres: genres);
    await _storageService.savePreference(_preference);
    notifyListeners();
  }

  Future<void> removeDislikedGenre(String genre) async {
    final genres = Set<String>.from(_preference.dislikedGenres)..remove(genre);
    _preference = _preference.copyWith(dislikedGenres: genres);
    await _storageService.savePreference(_preference);
    notifyListeners();
  }

  Future<void> updateCustomWeight(String genre, double weight) async {
    final weights = Map<String, double>.from(_preference.customWeights)
      ..[genre] = _clampWeight(weight);
    _preference = _preference.copyWith(customWeights: weights);
    await _storageService.savePreference(_preference);
    notifyListeners();
  }

  Future<void> resetAll() async {
    _studentInfo = null;
    _preference = UserPreference.empty();
    await _storageService.resetAll();
    notifyListeners();
  }

  double _clampWeight(double value) {
    if (value < -0.5) {
      return -0.5;
    }
    if (value > 0.5) {
      return 0.5;
    }
    return value;
  }
}
