class StudentInfo {
  const StudentInfo({
    this.grade,
    this.college,
    this.academy,
    this.major,
    this.gradeYear,
  });

  final int? grade;
  final String? college;
  final String? academy;
  final String? major;
  final String? gradeYear;

  bool get isComplete {
    return grade != null &&
        (college?.trim().isNotEmpty ?? false) &&
        (academy?.trim().isNotEmpty ?? false) &&
        (major?.trim().isNotEmpty ?? false) &&
        (gradeYear?.trim().isNotEmpty ?? false);
  }

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      grade: _parseInt(json['grade']),
      college: _parseString(json['college']),
      academy: _parseString(json['academy']),
      major: _parseString(json['major']),
      gradeYear: _parseString(json['gradeYear']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'grade': grade,
      'college': college,
      'academy': academy,
      'major': major,
      'gradeYear': gradeYear,
    };
  }

  StudentInfo copyWith({
    int? grade,
    String? college,
    String? academy,
    String? major,
    String? gradeYear,
  }) {
    return StudentInfo(
      grade: grade ?? this.grade,
      college: college ?? this.college,
      academy: academy ?? this.academy,
      major: major ?? this.major,
      gradeYear: gradeYear ?? this.gradeYear,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
