import 'dart:async';

import 'package:dio/dio.dart';

import '../models/notice_model.dart';
import '../utils/constants.dart';

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
            headers: <String, String>{'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.next(options),
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) => handler.next(error),
      ),
    );
  }

  final Dio _dio;

  Future<List<NoticeModel>> fetchNotices({
    required int page,
    required int pageSize,
  }) async {
    //如果使用Mock数据开启，则读取本地预置
    if (AppConstants.useMockData) {
      return _fetchMockNotices(page: page, pageSize: pageSize);
    }

    try {
      final response = await _dio.get<dynamic>(
        AppConstants.noticePath,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
        },
      );
      final rawList = _extractList(response.data);
      return rawList.map(NoticeModel.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException(_dioErrorMessage(error));
    } catch (error) {
      throw ApiException('通知接口解析失败：$error');
    }
  }

  Future<List<NoticeModel>> _fetchMockNotices({
    required int page,
    required int pageSize,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= _mockNoticeJson.length) {
      return <NoticeModel>[];
    }
    final endIndex = startIndex + pageSize > _mockNoticeJson.length
        ? _mockNoticeJson.length
        : startIndex + pageSize;
    return _mockNoticeJson
        .sublist(startIndex, endIndex)
        .map(NoticeModel.fromJson)
        .toList();
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map>().map(_toMap).toList();
    }
    if (payload is Map<String, dynamic>) {
      final directList = payload['data'];
      if (directList is List) {
        return directList.whereType<Map>().map(_toMap).toList();
      }
      final nestedList = payload['list'];
      if (nestedList is List) {
        return nestedList.whereType<Map>().map(_toMap).toList();
      }
      final nestedData = payload['data'];
      if (nestedData is Map<String, dynamic>) {
        final innerList = nestedData['list'];
        if (innerList is List) {
          return innerList.whereType<Map>().map(_toMap).toList();
        }
      }
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _toMap(Map raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  String _dioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请稍后重试';
      case DioExceptionType.sendTimeout:
        return '请求发送超时，请检查网络';
      case DioExceptionType.receiveTimeout:
        return '服务响应超时，请稍后再试';
      case DioExceptionType.badResponse:
        return '服务返回异常：${error.response?.statusCode ?? '未知状态'}';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '当前网络不可用，请稍后再试';
      case DioExceptionType.unknown:
        return '请求失败：${error.message ?? '未知异常'}';
      case DioExceptionType.badCertificate:
        return '证书校验失败';
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

final List<Map<String, dynamic>> _mockNoticeJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 'notice-001',
    'title': '2026年春季学期本科生期中考试安排通知',
    'genre': '考试',
    'importance': 9,
    'source': '教务处',
    'review': '公布期中考试时间、考场安排与缓考申请要求。',
    'keywords': '#考试;#大二;#人工智能;#期中',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-16 09:00:00'},
      <String, String>{'缓考申请截止': '2026-03-24 18:00:00'},
      <String, String>{'考试开始': '2026-03-28 08:00:00'},
    ],
    'attachment': <Map<String, String>>[
      <String, String>{
        '考场安排表.pdf': 'https://example.com/attachments/exam-arrangement.pdf',
      },
    ],
    'original_text':
        '<p>各位同学：</p><p>2026年春季学期期中考试安排已发布，请及时查看附件中的考场信息。</p><p>如需缓考，请在规定时间内提交申请。</p>',
    'link': 'https://example.com/notices/notice-001',
    'fetch_time': '2026-03-16T09:10:00',
  },
  <String, dynamic>{
    'id': 'notice-002',
    'title': '人工智能学院科研训练营报名通知',
    'genre': '竞赛',
    'importance': 8,
    'source': '人工智能学院',
    'review': '面向本科生开放科研训练营报名，优先录取有项目基础学生。',
    'keywords': '#竞赛;#人工智能;#大二;#科研训练',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-18 11:30:00'},
      <String, String>{'报名截止': '2026-03-25 23:59:59'},
      <String, String>{'开营时间': '2026-03-30 14:00:00'},
    ],
    'attachment': <Map<String, String>>[
      <String, String>{
        '报名说明.docx': 'https://example.com/attachments/ai-camp.docx'
      },
    ],
    'original_text':
        '<p>人工智能学院将举办本科生科研训练营，欢迎同学们报名参加。</p><p><a href="https://example.com/apply/ai-camp">点击填写报名表</a></p>',
    'link': 'https://example.com/notices/notice-002',
    'fetch_time': '2026-03-18T11:40:00',
  },
  <String, dynamic>{
    'id': 'notice-003',
    'title': '彭康书院社区文化节志愿者招募公告',
    'genre': '活动',
    'importance': 6,
    'source': '彭康书院',
    'review': '招募文化节现场志愿者，服务时长可计入第二课堂。',
    'keywords': '#活动;#大一;#大二;#彭康书院;#志愿',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-12 10:00:00'},
      <String, String>{'报名截止': '2026-03-21 20:00:00'},
      <String, String>{'举办时间': '2026-03-23 09:00:00'},
    ],
    'attachment': <Map<String, String>>[],
    'original_text': '<p>彭康书院社区文化节即将举行，现面向全院招募志愿者。</p>',
    'link': 'https://example.com/notices/notice-003',
    'fetch_time': '2026-03-12T10:05:00',
  },
  <String, dynamic>{
    'id': 'notice-004',
    'title': '关于2026年暑期海外访学项目宣讲会的通知',
    'genre': '国际',
    'importance': 7,
    'source': '国际教育学院',
    'review': '暑期访学项目宣讲开放报名，含奖学金政策说明。',
    'keywords': '#国际;#大二;#大三;#宣讲会;#英语',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-19 08:30:00'},
      <String, String>{'报名截止': '2026-03-26 17:30:00'},
      <String, String>{'举办时间': '2026-03-27 19:00:00'},
    ],
    'attachment': <Map<String, String>>[
      <String, String>{
        '项目手册.pdf': 'https://example.com/attachments/global-program.pdf'
      },
    ],
    'original_text': '<p>国际教育学院将举办2026年暑期海外访学项目宣讲会。</p>',
    'link': 'https://example.com/notices/notice-004',
    'fetch_time': '2026-03-19T08:40:00',
  },
  <String, dynamic>{
    'id': 'notice-005',
    'title': '南洋书院宿舍用电安全专项检查提醒',
    'genre': '后勤',
    'importance': 5,
    'source': '南洋书院',
    'review': '宿舍用电专项检查将于本周开展，请提前整理违禁电器。',
    'keywords': '#后勤;#宿舍;#大一;#大二',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-17 15:20:00'},
      <String, String>{'检查时间': '2026-03-22 19:00:00'},
    ],
    'attachment': <Map<String, String>>[],
    'original_text': '<p>为保障学生公寓安全，南洋书院将开展宿舍用电安全检查。</p>',
    'link': 'https://example.com/notices/notice-005',
    'fetch_time': '2026-03-17T15:25:00',
  },
  <String, dynamic>{
    'id': 'notice-006',
    'title': '管理学院创新创业学分认定材料提交通知',
    'genre': '教务',
    'importance': 8,
    'source': '管理学院',
    'review': '符合条件的学生需按时提交学分认定材料，逾期不再受理。',
    'keywords': '#教务;#大三;#创新创业;#学分',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-10 13:00:00'},
      <String, String>{'提交截止': '2026-03-22 18:00:00'},
    ],
    'attachment': <Map<String, String>>[
      <String, String>{
        '认定模板.zip': 'https://example.com/attachments/credit-template.zip'
      },
    ],
    'original_text': '<p>请各位同学按学院要求提交创新创业学分认定材料。</p>',
    'link': 'https://example.com/notices/notice-006',
    'fetch_time': '2026-03-10T13:20:00',
  },
  <String, dynamic>{
    'id': 'notice-007',
    'title': '电信学部电子设计竞赛校内选拔报名通知',
    'genre': '竞赛',
    'importance': 7,
    'source': '电信学部',
    'review': '电子设计竞赛校赛启动，报名队伍需在截止前提交方案。',
    'keywords': '#竞赛;#大二;#大三;#电子设计',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-11 09:30:00'},
      <String, String>{'报名截止': '2026-03-24 23:00:00'},
      <String, String>{'举办时间': '2026-03-29 08:30:00'},
    ],
    'attachment': <Map<String, String>>[
      <String, String>{
        '竞赛章程.pdf': 'https://example.com/attachments/competition-rules.pdf'
      },
    ],
    'original_text': '<p>欢迎同学们报名参加电子设计竞赛校内选拔。</p>',
    'link': 'https://example.com/notices/notice-007',
    'fetch_time': '2026-03-11T09:35:00',
  },
  <String, dynamic>{
    'id': 'notice-008',
    'title': '体育学院春季体测补测安排公告',
    'genre': '其他',
    'importance': 4,
    'source': '体育学院',
    'review': '春季体测补测时间已确定，请未完成项目的学生按时参加。',
    'keywords': '#体测;#补测;#大一;#大二;#大三',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-14 16:00:00'},
      <String, String>{'补测时间': '2026-03-21 08:00:00'},
    ],
    'attachment': <Map<String, String>>[],
    'original_text': '<p>体育学院将组织春季体测补测，请相关学生按时参加。</p>',
    'link': 'https://example.com/notices/notice-008',
    'fetch_time': '2026-03-14T16:20:00',
  },
  <String, dynamic>{
    'id': 'notice-009',
    'title': '关于学籍异动学生信息核验的紧急通知',
    'genre': '教务',
    'importance': 10,
    'source': '教务处',
    'review': '涉及休学复学转专业学生的信息核验，直接影响学籍状态。',
    'keywords': '#教务;#学籍;#大二;#大三;#人工智能',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-20 09:10:00'},
      <String, String>{'核验截止': '2026-03-23 12:00:00'},
    ],
    'attachment': <Map<String, String>>[
      <String, String>{
        '学籍核验流程.pdf': 'https://example.com/attachments/student-status.pdf'
      },
    ],
    'original_text': '<p>请相关学生尽快完成学籍异动信息核验，以免影响后续培养环节。</p>',
    'link': 'https://example.com/notices/notice-009',
    'fetch_time': '2026-03-20T09:15:00',
  },
  <String, dynamic>{
    'id': 'notice-010',
    'title': '团委关于校园马拉松活动报名开启的通知',
    'genre': '活动',
    'importance': 5,
    'source': '团委',
    'review': '校园马拉松活动开放报名，完成赛事可获得志愿时长。',
    'keywords': '#活动;#团委;#大一;#大二;#体育',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-13 10:20:00'},
      <String, String>{'报名截止': '2026-03-28 18:00:00'},
      <String, String>{'举办时间': '2026-03-30 07:30:00'},
    ],
    'attachment': <Map<String, String>>[],
    'original_text': '<p>2026年校园马拉松活动报名正式开启，欢迎大家积极参与。</p>',
    'link': 'https://example.com/notices/notice-010',
    'fetch_time': '2026-03-13T10:25:00',
  },
  <String, dynamic>{
    'id': 'notice-011',
    'title': '钱学森学院拔尖人才培养论坛预告',
    'genre': '活动',
    'importance': 6,
    'source': '钱学森学院',
    'review': '拔尖人才培养论坛即将举行，欢迎各学院学生报名旁听。',
    'keywords': '#活动;#论坛;#大一;#大二;#大三',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-09 17:00:00'},
      <String, String>{'报名截止': '2026-03-22 12:00:00'},
      <String, String>{'举办时间': '2026-03-24 19:00:00'},
    ],
    'attachment': <Map<String, String>>[],
    'original_text': '<p>钱学森学院将举办拔尖人才培养论坛，邀请多位导师参与分享。</p>',
    'link': 'https://example.com/notices/notice-011',
    'fetch_time': '2026-03-09T17:20:00',
  },
  <String, dynamic>{
    'id': 'notice-012',
    'title': '化学学院实验室开放日活动安排',
    'genre': '活动',
    'importance': 4,
    'source': '化学学院',
    'review': '重点实验室开放日面向全校开放，欢迎预约参观。',
    'keywords': '#活动;#化学;#实验室;#大一',
    'timeline': <Map<String, String>>[
      <String, String>{'发布时间': '2026-03-08 09:00:00'},
      <String, String>{'预约截止': '2026-03-18 18:00:00'},
      <String, String>{'举办时间': '2026-03-19 14:30:00'},
    ],
    'attachment': <Map<String, String>>[],
    'original_text': '<p>化学学院重点实验室开放日活动安排如下，请提前预约参观。</p>',
    'link': 'https://example.com/notices/notice-012',
    'fetch_time': '2026-03-08T09:05:00',
  },
];
