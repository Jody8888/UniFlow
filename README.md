# UniFlow:高效的校园信息聚合平台

## TODOs and Workflow [todos.md](./todos.md)
| Task | Description | Readme file | Assigned to |
| ----- | ----------- | ----------- | ----------- |
| - [x] [Backend] Html fetcher | 爬取原生Html内容 | [README.MD](./backend/fetch/README.MD) | jung233 Jody Thusci  |
| - [x] [Backend] AI processor | 转发原始文本至Qwen2.5-7B-Instruct进行结构化处理后存入服务端Postgres数据库 | [README.md](./backend/store/README.md) | Thusci |
| - [ ] [Backend] Notification api | 基于 FastAPI面向前端和小程序提供的 RESTful 接口。 | [readme.md](./backend/api/README.md) | Jody |
| - [ ] [Backend] CalDAV Service | 基于CalDAV实现的日历推送 | [PENDING] | [PENDING] |
| - [ ] [Frontend] Android frontend | 事件日历与待办功能 | [PENDING] | [PENDING] |
| - [ ] [Frontend] iOS frontend | 事件日历与待办功能 | [PENDING] | [PENDING] |
| - [x] [Frontend & Backend] Feed management site | 管理爬取/推送流程 | [Webmin] | [Webmin] |

## [支持的网站](./doi.md)

## Repo map:
```
├── README.md                               #Uniflow程序文档
├── requirements.txt                        #Python组件表
├── doi.md                                  #目前支持的域名
├── .updateignore                           #服务端自动更新忽略文件列表
├── backend                                 #后端部分
│   ├── api                                 #FastAPI推送
│   │   ├── main.py                             #FastAPI主程序
│   │   └── README.md                           #FastAPI文档
│   ├── fetch                               #HTML爬取器
│   │   ├── README.MD                           #爬取器文档
│   │   ├── api_fetcher.py                      #独立的 JSON API 数据源抓取模块，处理无法用 HTML + XPath 抓取的数据源
│   │   ├── config_json                         #各个网站对应的json配置文件
│   │   │   ├── bjb.xjtu.edu.cn.json                #钱学森书院
│   │   │   ├── bw.xjtu.edu.cn.json                 #保卫处
│   │   │   ├── cy.xjtu.edu.cn.json                 #仲英书院
│   │   │   ├── dean.xjtu.edu.cn.json               #教务处
│   │   │   ├── jwc.xjtu.edu.cn.1.json              #教务处
│   │   │   ├── jwc.xjtu.edu.cn.2.json              #教务处
│   │   │   ├── lizhi.xjtu.edu.cn.json              #励志书院
│   │   │   ├── nanyang.xjtu.edu.cn.json            #南洋书院
│   │   │   ├── nic.xjtu.edu.cn.json                #网信中心
│   │   │   ├── oa.xjtu.edu.cn.json                 #办公系统
│   │   │   ├── pec.xjtu.edu.cn.dcxm.json           #
│   │   │   ├── pec.xjtu.edu.cn.js.json             #实践教学中心（工程坊）
│   │   │   ├── pksy.xjtu.edu.cn.json               #彭康书院
│   │   │   ├── sfs.xjtu.edu.cn.json                #外国语学院
│   │   │   └── zlsy.xjtu.edu.cn.json               #宗濂书院
│   │   ├── config.py                           #配置文件载入器
│   │   ├── fetcher.py                          #爬取器
│   │   ├── http_client.py                      #HTTP客户端（承担网页访问）
│   │   ├── __init__.py                         #
│   │   ├── main.py                             #仅用于开发调试的单配置运行入口（非业务集成方式）
│   │   ├── parser.py                           #XPath/文本/链接解析工具
│   │   └── test_all.py                         #
│   └── store                               #存储到数据库
│       ├── README.md                           #存入功能文档
└─      └── store.py                            #存入功能主程序

```
