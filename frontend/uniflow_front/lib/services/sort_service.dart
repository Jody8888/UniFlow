import '../models/notice_model.dart';
import '../models/student_info.dart';
import '../models/user_preference.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class SortService {
  List<NoticeModel> sortNotices({
    required List<NoticeModel> notices,
    required StudentInfo? studentInfo,
    required UserPreference preference,
  }) {
    final visibleNotices = notices
        .where((notice) => !preference.dislikedGenres.contains(notice.genre))
        .toList();

    switch (preference.homeSortMode) {
      case AppSortModes.latest:
        visibleNotices.sort(_compareByLatest);
        break;
      case AppSortModes.importance:
        visibleNotices.sort(_compareByImportance);
        break;
      case AppSortModes.deadline:
        visibleNotices.sort(_compareByDeadline);
        break;
      case AppSortModes.personalized:
      default:
        visibleNotices.sort((left, right) {
          final rightScore = calculateScore(
            notice: right,
            allNotices: notices,
            studentInfo: studentInfo,
            preference: preference,
          );
          final leftScore = calculateScore(
            notice: left,
            allNotices: notices,
            studentInfo: studentInfo,
            preference: preference,
          );

          if (rightScore == leftScore) {
            return _compareByLatest(left, right);
          }
          return rightScore.compareTo(leftScore);
        });
    }

    return visibleNotices;
  }

  double calculateScore({
    required NoticeModel notice,
    required List<NoticeModel> allNotices,
    required StudentInfo? studentInfo,
    required UserPreference preference,
  }) {
    final baseScore = notice.importance.toDouble();
    var personalization = 0.0;

    if (studentInfo != null) {
      if ((studentInfo.college?.isNotEmpty ?? false) &&
          notice.source == studentInfo.college) {
        personalization += 0.4;
      }
      if ((studentInfo.academy?.isNotEmpty ?? false) &&
          notice.source == studentInfo.academy) {
        personalization += 0.3;
      }
      if ((studentInfo.gradeYear?.isNotEmpty ?? false) &&
          notice.keywords.contains(studentInfo.gradeYear ?? '')) {
        personalization += 0.15;
      }
      if ((studentInfo.major?.isNotEmpty ?? false) &&
          notice.keywords.contains(studentInfo.major ?? '')) {
        personalization += 0.15;
      }

      final gradeWeights =
          AppConstants.defaultGenreWeights[studentInfo.gradeYear] ?? const <String, double>{};
      personalization += gradeWeights[notice.genre] ?? 0;
    }

    if (AppConstants.schoolLevelSources.contains(notice.source)) {
      personalization += 0.1;
    }

    final readGenres = allNotices
        .where((item) => preference.readNoticeIds.contains(item.id))
        .map((item) => item.genre)
        .toSet();
    if (readGenres.contains(notice.genre)) {
      personalization += 0.2;
    }

    if (preference.dislikedGenres.contains(notice.genre)) {
      personalization -= 0.5;
    }

    personalization += preference.customWeights[notice.genre] ?? 0;
    final personalizationScore = _clampDouble(personalization, min: 0, max: 1);

    final timeScore = _calculateTimeScore(notice);

    var penalty = 0.0;
    final expired = AppDateUtils.isExpired(notice);
    if (expired) {
      penalty += 10;
    }
    if (_isCompletelyIrrelevant(
      notice: notice,
      studentInfo: studentInfo,
      preference: preference,
    )) {
      penalty += 2;
    }

    var finalScore = baseScore * (1 + personalizationScore) + timeScore - penalty;
    if (expired && finalScore > 2) {
      finalScore = 2;
    }
    return finalScore;
  }

  int _compareByLatest(NoticeModel left, NoticeModel right) {
    final rightTime = AppDateUtils.extractPublishedTime(right)?.millisecondsSinceEpoch ?? 0;
    final leftTime = AppDateUtils.extractPublishedTime(left)?.millisecondsSinceEpoch ?? 0;
    return rightTime.compareTo(leftTime);
  }

  int _compareByImportance(NoticeModel left, NoticeModel right) {
    final importance = right.importance.compareTo(left.importance);
    if (importance != 0) {
      return importance;
    }
    return _compareByLatest(left, right);
  }

  int _compareByDeadline(NoticeModel left, NoticeModel right) {
    final leftDeadline = AppDateUtils.extractLatestBusinessTime(left);
    final rightDeadline = AppDateUtils.extractLatestBusinessTime(right);
    if (leftDeadline == null && rightDeadline == null) {
      return _compareByLatest(left, right);
    }
    if (leftDeadline == null) {
      return 1;
    }
    if (rightDeadline == null) {
      return -1;
    }
    final compare = leftDeadline.compareTo(rightDeadline);
    if (compare != 0) {
      return compare;
    }
    return _compareByLatest(left, right);
  }

  double _calculateTimeScore(NoticeModel notice) {
    var total = 0.0;
    final now = DateTime.now();
    final publishedTime = AppDateUtils.extractPublishedTime(notice);
    if (publishedTime != null) {
      final difference = now.difference(publishedTime).inDays;
      if (difference <= 7) {
        total += 3;
      } else if (difference <= 14) {
        total += 2;
      } else if (difference <= 30) {
        total += 1;
      }
    }

    final deadline = AppDateUtils.extractLatestBusinessTime(notice);
    if (deadline != null && deadline.isAfter(now)) {
      final days = deadline.difference(now).inDays;
      if (days <= 3) {
        total += 3;
      } else if (days <= 7) {
        total += 2;
      } else if (days <= 15) {
        total += 1;
      }
    }

    return _clampDouble(total, min: 0, max: 5);
  }

  bool _isCompletelyIrrelevant({
    required NoticeModel notice,
    required StudentInfo? studentInfo,
    required UserPreference preference,
  }) {
    if (studentInfo == null || !studentInfo.isComplete) {
      return false;
    }

    final collegeMatched = notice.source == studentInfo.college;
    final academyMatched = notice.source == studentInfo.academy;
    final gradeMatched = notice.keywords.contains(studentInfo.gradeYear ?? '');
    final majorMatched = notice.keywords.contains(studentInfo.major ?? '');
    final schoolLevel = AppConstants.schoolLevelSources.contains(notice.source);
    final weightMatched =
        ((AppConstants.defaultGenreWeights[studentInfo.gradeYear] ?? const <String, double>{})[
                        notice.genre] ??
                    0) >
                0 ||
            (preference.customWeights[notice.genre] ?? 0) > 0;

    return !collegeMatched &&
        !academyMatched &&
        !gradeMatched &&
        !majorMatched &&
        !schoolLevel &&
        !weightMatched &&
        notice.importance <= 3;
  }

  double _clampDouble(double value, {required double min, required double max}) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}
