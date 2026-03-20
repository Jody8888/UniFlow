class ApiSourceConfig {
  const ApiSourceConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.noticePath,
    required this.useMockData,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String noticePath;
  final bool useMockData;

  factory ApiSourceConfig.mock() {
    return const ApiSourceConfig(
      id: 'mock-default',
      name: '内置 Mock 数据',
      baseUrl: 'https://example.com',
      noticePath: '/api/events',
      useMockData: true,
    );
  }

  factory ApiSourceConfig.fromJson(Map<String, dynamic> json) {
    return ApiSourceConfig(
      id: json['id']?.toString().trim().isNotEmpty == true
          ? json['id'].toString().trim()
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : '未命名数据源',
      baseUrl: json['baseUrl']?.toString().trim() ?? '',
      noticePath: json['noticePath']?.toString().trim().isNotEmpty == true
          ? json['noticePath'].toString().trim()
          : '/api/events',
      useMockData: json['useMockData'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'noticePath': noticePath,
      'useMockData': useMockData,
    };
  }

  ApiSourceConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? noticePath,
    bool? useMockData,
  }) {
    return ApiSourceConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      noticePath: noticePath ?? this.noticePath,
      useMockData: useMockData ?? this.useMockData,
    );
  }

  String get displayUrl {
    if (useMockData) {
      return '使用内置 Mock 数据';
    }
    return '$baseUrl$noticePath';
  }
}
