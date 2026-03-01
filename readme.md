# UniFlow: A campus info gathering and feeding platform
## TODOs and Workflow [todos.md](./todos.md)
| Task | Description | Readme file | Assigned to |
| ----- | ----------- | ----------- | ----------- |
| - [x] [Backend] Html fetcher | 爬取原生Html内容 | [README.MD](./backend/fetch/README.MD) |  |
| - [x] [Backend] AI processor | 转发原始文本至Qwen2.5-7B-Instruct进行结构化处理后存入服务端Postgres数据库 | [README.md](./backend/store/README.md) | Thusci |
| - [ ] [Backend] Notification api | 基于 FastAPI面向前端和小程序提供的 RESTful 接口。 | [readme.md](./backend/api/README.md) | [PENDING] Jody |
| - [ ] [Frontend] Android frontend | 事件日历与待办功能 | [PENDING] | [PENDING] |
| - [ ] [Frontend] iOS frontend | 事件日历与待办功能 | [PENDING] | [PENDING] |
| - [ ] [Frontend & Backend] Feed management site | 管理爬取/推送流程 | [PENDING] | [PENDING] |

### 学校官方
| 网址 | 内容 | 授权情况 | 解析方式 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| bw.xjtu.edu.cn | 保卫处 |  |  |  |
| dean.xjtu.edu.cn | 教务处 | Open |  |  |
| jwc.xjtu.edu.cn | 教务处 | Open | [Channel 1](./backend/fetch/config_json/jwc.xjtu.edu.cn.1.json) [Channel 2](./backend/fetch/config_json/jwc.xjtu.edu.cn.2.json) |  |
| info.xjtu.edu.cn | 交大综合信息 |  |  |  |
| nic.xjtu.edu.cn | 网络信息中心 |  |  |  |
| tuanwei.xjtu.edu.cn | 团委 |  |  |  |
| pec.xjtu.edu.cn/cxcy/js.htm| 竞赛  |  |  |  |
| pec.xjtu.edu.cn/cxcy/dcxm.htm | 大创比赛 |  |  |  |
| oa.xjtu.edu.cn | OA平台 | Open | [oa.xjtu.edu.cn.json](./backend/fetch/config_json/oa.xjtu.edu.cn.json) |  |

### 书院门户
| 网址 | 内容 | 授权情况 | 解析方式 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| [bjb.xjtu.edu.cn](https://bjb.xjtu.edu.cn/xydt/tzgg.htm) | 钱学森学院 | Open | [bjb.xjtu.edu.cn.json](./backend/fetch/config_json/bjb.xjtu.edu.cn.json) |  |
| [cy.xjtu.edu.cn](http://cy.xjtu.edu.cn/xwdt/tzgg.htm) | 仲英书院 | Open | [cy.xjtu.edu.cn.json](./backend/fetch/config_json/cy.xjtu.edu.cn.json) | 托管于微信公众号平台 |
| [pksy.xjtu.edu.cn](https://pksy.xjtu.edu.cn/tzgg.htm) | 彭康书院 | Open | [pksy.xjtu.edu.cn.json](./backend/fetch/config_json/pksy.xjtu.edu.cn.json) |  |
| [sfs.xjtu.edu.cn](https://sfs.xjtu.edu.cn/glfw/tzgg.htm) | 外国语学院 | Open | [sfs.xjtu.edu.cn.json](./backend/fetch/config_json/sfs.xjtu.edu.cn.json) | 这个其实没啥东西但是看到金秋外语节故保留 |
| [zlsy.xjtu.edu.cn](https://zlsy.xjtu.edu.cn/tzgg.htm) | 宗濂书院 | Open | [zlsy.xjtu.edu.cn.json](./backend/fetch/config_json/zlsy.xjtu.edu.cn.json) | 医学部，这个可以不做，但是考虑公用，所以保留 |
| [nanyang.xjtu.edu.cn](https://nanyang.xjtu.edu.cn/xwtz/tzgg.htm) | 南洋书院 | Open | [nanyang.xjtu.edu.cn.json](./backend/fetch/config_json/nanyang.xjtu.edu.cn.json) | 托管于微信公众号平台,也没啥东西 但是有腾飞杯所以保留 |
| [lizhi.xjtu.edu.cn](https://lizhi.xjtu.edu.cn/xwtz/tzgg.htm) | 励志书院 | Open | [lizhi.xjtu.edu.cn.json](./backend/fetch/config_json/lizhi.xjtu.edu.cn.json) | 理由同上 |

### 活动
| 网址 | 内容 |
| ---- | ---- |
|one.xjtu.edu.cn/EIP/nonlogin/queryLargeActivityList.htm?pageIndex=1&pageSize=10|校级活动|
|ss.xjtu.edu.cn/xsfw/sys/swmsyxsfzapp/ykHdController/getActivityList.do|所有活动|

## Repo map:
```
├── backend                     #Backend logic of UniFlow
│   ├── fetch                   #Fetcher -- Handler of flows
│   │   ├── config_json         #Directory for site-fetch scripts
│   │   │   ├──
│   │   ├── config.py
│   │   ├── fetcher.py
│   │   ├── http_client.py
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── parser.py
│   │   ├── README.MD           #Readme for fetcher
│   │   └── requirements.txt
│   └── readme.md
├── doi.md                      #[Deserted]Domains of interest
├── readme.md                   #This readme file
└── Urls.txt
```
