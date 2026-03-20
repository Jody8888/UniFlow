# UniFlow Front

西安交通大学校园通知个性化客户端，基于 Flutter 实现，支持安卓、iOS 和其他 Flutter 平台。

当前项目已经包含：
- 通知列表展示
- 通知详情查看
- 基于学生信息和用户偏好的纯客户端个性化排序
- 已读状态管理
- 不感兴趣类型屏蔽
- 本地缓存与离线兜底
- 个人信息编辑
- 设置页权重调整与数据重置

## 技术栈

- Flutter 3.0+
- Dart 3.0+
- Provider
- Dio
- shared_preferences
- pull_to_refresh
- flutter_html
- url_launcher
- intl

## 目录结构

```text
lib/
├── main.dart
├── models/
│   ├── notice_model.dart
│   ├── student_info.dart
│   └── user_preference.dart
├── services/
│   ├── api_service.dart
│   ├── sort_service.dart
│   └── storage_service.dart
├── providers/
│   ├── notice_provider.dart
│   └── user_provider.dart
├── pages/
│   ├── home/notice_list_page.dart
│   ├── notice/notice_detail_page.dart
│   ├── user/user_info_page.dart
│   └── setting/setting_page.dart
├── widgets/
│   ├── notice_card.dart
│   ├── loading_widget.dart
│   └── empty_widget.dart
└── utils/
    ├── constants.dart
    └── date_utils.dart
```

### 各层职责

- `models`：数据模型与 JSON 解析
- `services`：接口请求、本地存储、排序算法
- `providers`：全局状态管理
- `pages`：页面 UI
- `widgets`：可复用组件
- `utils`：常量、主题、日期工具

## 运行方式

1. 安装依赖

```powershell
flutter pub get
```

2. 启动应用

```powershell
flutter run
```

## 当前数据来源

项目默认使用内置 mock 数据，保证无后端也能直接运行演示。

- 首次启动时，应用会先读取本地缓存
- 随后 `ApiService` 会返回内置 mock 通知列表
- 通知、个人信息、偏好设置都会写入 `SharedPreferences`
- 如果网络不可用，列表会回退到本地缓存

相关文件：
- [`api_service.dart`](lib/services/api_service.dart)
- [`storage_service.dart`](lib/services/storage_service.dart)
- [`notice_provider.dart`](lib/providers/notice_provider.dart)

## 如何切换到真实 API

当前接口配置在 [`constants.dart`](lib/utils/constants.dart) 和 [`api_service.dart`](lib/services/api_service.dart)。

### 1. 修改接口地址

在 [`constants.dart`](lib/utils/constants.dart) 中修改：

```dart
static const String apiBaseUrl = 'https://your-domain.com';
static const String noticePath = '/api/notices';
static const bool useMockData = false;
```

### 2. 接口返回格式

前端支持以下几种常见返回结构：
- `List`
- `{ data: List }`
- `{ list: List }`
- `{ data: { list: List } }`

每条通知建议符合这些字段：

- `uuid` 或 `id`
- `title`
- `genre`
- `importance`
- `source`
- `review`
- `keywords`
- `timeline`
- `attachment`
- `original_text`
- `link`
- `fetch_time`

### 3. 示例返回

```json
[
  {
    "id": "notice-001",
    "title": "示例通知",
    "genre": "教务",
    "importance": 8,
    "source": "教务处",
    "review": "一句话摘要",
    "keywords": "#教务;#考试",
    "timeline": [
      { "发布时间": "2026-03-20 09:00:00" },
      { "报名截止": "2026-03-24 18:00:00" }
    ],
    "attachment": [
      { "附件.pdf": "https://example.com/file.pdf" }
    ],
    "original_text": "<p>HTML 正文</p>",
    "link": "https://example.com/detail",
    "fetch_time": "2026-03-20T09:10:00"
  }
]
```

## 个性化排序说明

前端排序完全在本地完成，不依赖后端排序结果。

最终公式：

```text
最终得分 = 基础分 × (1 + 个性化总系数) + 时间分 - 惩罚分
```

### 评分规则

- `基础分`：通知 `importance`
- `个性化总系数`：由学院、书院、年级、专业、校级来源、年级偏好、已读同类型、屏蔽类型、自定义权重组成
- `时间分`：按发布时间和截止时间加分，最高 5 分
- `惩罚分`：过期通知和完全无关内容扣分

实现位置：
- [`sort_service.dart`](lib/services/sort_service.dart)
- [`date_utils.dart`](lib/utils/date_utils.dart)

## 页面说明

### 首页通知列表

- 下拉刷新
- 上拉加载更多
- 通知卡片展示标题、摘要、来源、类型、发布时间、已读、过期标记
- 长按或更多按钮可屏蔽当前类型

### 通知详情页

- 展示标题、摘要、HTML 正文、时间线、附件
- 正文链接与附件链接支持外部浏览器打开
- 右上角可跳转原文链接

### 个人信息页

- 编辑入学年份、学院、书院、专业、年级
- 保存后本地持久化，并立即影响排序

### 设置页

- 调整每个通知类型的自定义权重，范围 `-0.5 ~ +0.5`
- 管理已屏蔽类型
- 清除通知缓存
- 重置全部设置

## 本地存储

使用 `shared_preferences` 保存三类数据：

- 通知缓存
- 学生个人信息
- 用户偏好

对应 key 在 [`constants.dart`](lib/utils/constants.dart) 的 `AppStorageKeys` 中定义。

## 开发提示

- 当前项目默认 `useMockData = true`，适合直接演示与调试
- 如果你要接真实后端，建议先确认后端 JSON 字段命名与页面里使用的模型一致
- 如果接口字段有细微差异，可以优先在 [`NoticeModel.fromJson`](lib/models/notice_model.dart) 做兼容

## 常用命令

```powershell
flutter pub get
flutter run
```

如果需要检查代码：

```powershell
dart analyze lib test
```

## 备注

项目中已经内置一批 mock 通知，方便在没有后端时直接查看列表、详情、排序、筛选和缓存流程。
