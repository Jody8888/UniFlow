import '../utils/constants.dart';

class UserPreference {
  UserPreference({
    Set<String>? readNoticeIds,
    Set<String>? dislikedGenres,
    Map<String, double>? customWeights,
  })  : readNoticeIds = readNoticeIds ?? <String>{},
        dislikedGenres = dislikedGenres ?? <String>{},
        customWeights = _normalizeWeights(customWeights);

  final Set<String> readNoticeIds;
  final Set<String> dislikedGenres;
  final Map<String, double> customWeights;

  factory UserPreference.empty() {
    return UserPreference(
      readNoticeIds: <String>{},
      dislikedGenres: <String>{},
      customWeights: <String, double>{
        for (final genre in AppConstants.noticeGenres) genre: 0,
      },
    );
  }

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      readNoticeIds: _readStringSet(json['readNoticeIds']),
      dislikedGenres: _readStringSet(json['dislikedGenres']),
      customWeights: _readDoubleMap(json['customWeights']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'readNoticeIds': readNoticeIds.toList(),
      'dislikedGenres': dislikedGenres.toList(),
      'customWeights': customWeights,
    };
  }

  UserPreference copyWith({
    Set<String>? readNoticeIds,
    Set<String>? dislikedGenres,
    Map<String, double>? customWeights,
  }) {
    return UserPreference(
      readNoticeIds: readNoticeIds ?? this.readNoticeIds,
      dislikedGenres: dislikedGenres ?? this.dislikedGenres,
      customWeights: customWeights ?? this.customWeights,
    );
  }

  static Map<String, double> _normalizeWeights(Map<String, double>? weights) {
    final normalized = <String, double>{
      for (final genre in AppConstants.noticeGenres) genre: 0,
    };
    if (weights == null) {
      return normalized;
    }
    for (final entry in weights.entries) {
      if (AppConstants.noticeGenres.contains(entry.key)) {
        normalized[entry.key] = _clampWeight(entry.value);
      }
    }
    return normalized;
  }

  static Set<String> _readStringSet(dynamic value) {
    if (value is! List) {
      return <String>{};
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static Map<String, double> _readDoubleMap(dynamic value) {
    if (value is! Map) {
      return <String, double>{};
    }
    final result = <String, double>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (!AppConstants.noticeGenres.contains(key)) {
        continue;
      }
      final raw = entry.value;
      if (raw is num) {
        result[key] = _clampWeight(raw.toDouble());
        continue;
      }
      final parsed = double.tryParse(raw?.toString() ?? '');
      if (parsed != null) {
        result[key] = _clampWeight(parsed);
      }
    }
    return result;
  }

  static double _clampWeight(double value) {
    if (value < -0.5) {
      return -0.5;
    }
    if (value > 0.5) {
      return 0.5;
    }
    return value;
  }
}
