# UniFlow: A campus info gathering and feeding platform

## Domains of interest And how to deal with them

### 学校官方
| 网址 | 内容 | 授权情况 | 解析方式 |
| ---- | ---- | ---- | ---- |
| bw.xjtu.edu.cn | 保卫处 |  |  |
| dean.xjtu.edu.cn | 教务处 | Open | [dean.json](./Backend/Site-scripts/School-offical/dean.json) |
| info.xjtu.edu.cn | 交大综合信息 |  |  |
| nic.xjtu.edu.cn | 网络信息中心 |  |  |
| tuanwei.xjtu.edu.cn | 团委 |  |  |
| pec.xjtu.edu.cn/cxcy/js.htm| 竞赛  |  |  |
| pec.xjtu.edu.cn/cxcy/dcxm.htm | 大创比赛 |  |  |
| oa.xjtu.edu.cn | OA平台 |  |  |

### 书院门户
| 网址 | 内容 | 授权情况 | 解析方式 |
| ---- | ---- | ---- | ---- |
| [bjb.xjtu.edu.cn](https://bjb.xjtu.edu.cn/xydt/tzgg.htm) | 钱学森学院 | Open | [bjb.json](./Backend/Site-scripts/Academy-portal/bjb.json) |
| [cy.xjtu.edu.cn](http://cy.xjtu.edu.cn/xwdt/tzgg.htm) | 仲英书院 |  |  |
| [pksy.xjtu.edu.cn](https://pksy.xjtu.edu.cn/tzgg.htm) | 彭康书院 |  |  |
| [sfs.xjtu.edu.cn](https://sfs.xjtu.edu.cn/glfw/tzgg.htm) | 外国语学院 | 这个其实没啥东西但是看到金秋外语节故保留 |  |
| [zlsy.xjtu.edu.cn](https://zlsy.xjtu.edu.cn/tzgg.htm) | 宗濂书院 | 医学部，这个可以不做，但是考虑公用，所以保留 |  |
| [nanyang.xjtu.edu.cn](https://nanyang.xjtu.edu.cn/xwtz/tzgg.htm) | 南洋书院 | 也没啥东西 但是有腾飞杯所以保留 |  |
| [lizhi.xjtu.edu.cn](https://lizhi.xjtu.edu.cn/xwtz/tzgg.htm) | 励志书院 | 理由同上 |  |

### 活动
| 网址 | 内容 |
| ---- | ---- |
|one.xjtu.edu.cn/EIP/nonlogin/queryLargeActivityList.htm?pageIndex=1&pageSize=10|校级活动|
|ss.xjtu.edu.cn/xsfw/sys/swmsyxsfzapp/ykHdController/getActivityList.do|所有活动|

## Repo map:
```
UniFlow
├── Backend                 The backend logic.
│   ├── backend.md
│   └── Site-scripts        Json formatted scripts for site-processing.
│       ├── bjb.json
│       └── site-scripts.md
├── doi.md                  Domains of interest.
├── readme.md               This Readme file.
└── Urls.txt
```