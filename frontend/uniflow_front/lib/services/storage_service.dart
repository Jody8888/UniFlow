import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notice_model.dart';
import '../models/student_info.dart';
import '../models/user_preference.dart';
import '../utils/constants.dart';

class StorageService {
  StorageService() : _prefsFuture = SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefsFuture;

  Future<void> saveNotices(List<NoticeModel> notices) async {
    final prefs = await _prefsFuture;
    final payload = notices.map((notice) => notice.toJson()).toList();
    await prefs.setString(
      AppStorageKeys.noticeCache,
      jsonEncode(payload),
    );
  }

  Future<List<NoticeModel>> loadNotices() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(AppStorageKeys.noticeCache);
    if (raw == null || raw.isEmpty) {
      return <NoticeModel>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <NoticeModel>[];
      }
      return decoded
          .whereType<Map>()
          .map((item) => NoticeModel.fromJson(
                item.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ))
          .toList();
    } catch (_) {
      return <NoticeModel>[];
    }
  }

  Future<void> clearNoticeCache() async {
    final prefs = await _prefsFuture;
    await prefs.remove(AppStorageKeys.noticeCache);
  }

  Future<void> saveStudentInfo(StudentInfo? studentInfo) async {
    final prefs = await _prefsFuture;
    if (studentInfo == null) {
      await prefs.remove(AppStorageKeys.studentInfo);
      return;
    }
    await prefs.setString(
      AppStorageKeys.studentInfo,
      jsonEncode(studentInfo.toJson()),
    );
  }

  Future<StudentInfo?> loadStudentInfo() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(AppStorageKeys.studentInfo);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return StudentInfo.fromJson(
        decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> savePreference(UserPreference preference) async {
    final prefs = await _prefsFuture;
    await prefs.setString(
      AppStorageKeys.preference,
      jsonEncode(preference.toJson()),
    );
  }

  Future<UserPreference> loadPreference() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(AppStorageKeys.preference);
    if (raw == null || raw.isEmpty) {
      return UserPreference.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return UserPreference.empty();
      }
      return UserPreference.fromJson(
        decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } catch (_) {
      return UserPreference.empty();
    }
  }

  Future<void> resetAll() async {
    final prefs = await _prefsFuture;
    await prefs.remove(AppStorageKeys.noticeCache);
    await prefs.remove(AppStorageKeys.studentInfo);
    await prefs.remove(AppStorageKeys.preference);
  }
}
