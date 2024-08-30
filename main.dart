import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'dart:html';

Dio dio = Dio();

Future<void> main() async {
  runApp(
    MyApp(),
  );
}

var globalconfig = {};

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: '导入B站收藏夹到Listen1 by:谢必安_玄',
        // theme: ThemeData(
        //   colorScheme: lightColorScheme ?? _defaultLightColorScheme,
        //   useMaterial3: true,
        // ),
        // darkTheme: ThemeData(
        //   colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
        //   useMaterial3: true,
        // ),
        themeMode: ThemeMode.light,
        home: TakePictureScreen(),
      );
    });
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key});

  // final List cameras;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

Future<bool> loadConfigFromFile() async {
  Completer<bool> completer = Completer<bool>();
  // 创建一个文件选择器
  FileUploadInputElement input = FileUploadInputElement()..accept = '.json';
  input.click(); // 触发文件选择器

  // 监听文件选择器的变化
  input.onChange.listen((e) {
    // 获取用户选择的文件列表
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;

      // 创建一个FileReader来读取文件
      FileReader reader = FileReader();
      reader.readAsText(file); // 读取文件内容为文本

      // 当文件读取完成时
      reader.onLoadEnd.listen((e) {
        // 解析并加载配置数据
        final String content = reader.result as String;
        final dynamic configData = jsonDecode(content);
        // 假设你有一个全局变量来存储配置数据
        globalconfig = configData;

        // print('配置数据已加载: $configData');
        //读取数据重的所有以playlist开头的键值对
        playlists.clear();
        globalconfig.forEach((key, value) {
          if (key.toString().startsWith('myplaylist')) {
            playlists
                .add({'key': key.toString(), 'name': value['info']['title']});
          }
        });
        isLoaded = true;
        print('歌单列表: $playlists');
        completer.complete(true);
      });
    } else {
      completer.complete(false);
    }
  });
  return completer.future;
}

Future<String> downloadJsonFile() async {
  if (globalconfig.isEmpty) {
    return '配置数据为空';
  }
  // 将全局JSON变量转换为字符串
  String jsonString = jsonEncode(globalconfig);
  // 创建Blob对象
  final blob = html.Blob([jsonString], 'application/json');
  // 创建对象URL
  final url = html.Url.createObjectUrlFromBlob(blob);
  // 创建一个用于下载的a标签
  html.AnchorElement(href: url)
    ..setAttribute("download", "listen1_backup_output.json") // 设置下载文件名
    ..click(); // 触发点击事件以下载文件
  // 清理创建的对象URL以避免内存泄漏
  html.Url.revokeObjectUrl(url);
  return '';
}

// List<Map<String, String>> playlists = [];
List<Map<String, dynamic>> playlists = [];
String selectlist = '';
String selectlistname = '';
String opt = '覆盖现有';
bool selectcreateorcol = true;
int selectmid = 0;
String selectmidname = '';
bool isLoaded = false;
bool b1 = false;
var cookie = '';
var bilibiliData = {};
var bilibiliData2 = [];
Future<String> fetchBilibiliData() async {
  b1 = false;
  // final url = 'https://api.bilibili.com/x/v3/fav/folder/list4navigate';
  // String url = 'http://192.168.31.84:8888/test';
  String url = 'https://b2l.040905.xyz/test';
  var headers = {
    'content-type': 'application/json',
    'coo': cookie,
  };

  try {
    print(headers);
    final response = await Dio().get(url, options: Options(headers: headers));
    print(response.statusCode);
    print(response.data);
    bilibiliData = response.data;
    // url = 'http://192.168.31.84:8888/test1';
    url = 'https://b2l.040905.xyz/test1';
    // http://192.168.31.84:8888/test1?pn=1&ps=20&up_mid=329020925&platform=web
    // buvid3=2E53FCF7-DDBC-0AF0-2711-04C3C861A73129068infoc; SESSDATA=8b32066e%2C1740563528%2C6a350%2A81CjCBfwm_peWfk-hJ9bD8eeXdMA6VcOvtiRZ4HP4mdA_om3csi1-GM9AnTEmbu5244dYSVkh1T2JKc083SHJZMzVqZlJQME43U0hQZy0xXzM2Q3hEOUhfY2Y0bVBkWVoyMjZDT2dFU05YS3RWWXJ2YmZ4ZEdPZVBTWXo2M3NsWjNzc0lsNjg4dVF3IIEC; bili_jct=f971a1e75b31f198a365a8ffeee95fdc; DedeUserID=329020925; DedeUserID__ckMd5=4e06cdb3faeabccd; sid=8gk3dj7l
    String up_mid = cookie.split('DedeUserID=')[1].split(';')[0];
    String turl = url + '?pn=1&ps=20&up_mid=' + up_mid + '&platform=web';
    var response2 = await Dio().get(turl);
    var res2 = response2.data;
    bilibiliData2.clear();
    res2['data']['list'].forEach((element) {
      bilibiliData2.add(element);
    });
    if (res2['data']['has_more']) {
      var pn = 2;
      do {
        turl = url + '?pn=$pn&ps=20&up_mid=' + up_mid + '&platform=web';
        response2 =
            await dio.get(turl, options: Options(headers: {'cookie': cookie}));
        res2 = response2.data;
        res2['data']['list'].forEach((element) {
          bilibiliData2.add(element);
        });
        pn++;
      } while (res2['data']['has_more']);
    }
    return ''; // 请求成功，返回空字符串
  } on DioException catch (e) {
    print('请求失败: ${e.message}');
    if (e.response != null) {
      print('响应数据: ${e.response?.data}');
      print('响应头: ${e.response?.headers}');
      print('请求信息: ${e.response?.requestOptions}');
    } else {
      print('请求未发送: ${e.requestOptions}');
      print('错误信息: ${e.message}');
    }
    return '请求失败: ${e.message}'; // 请求失败，返回错误信息
  } catch (e) {
    print('未知错误: $e');
    return '未知错误: $e'; // 请求失败，返回错误信息
  }
}

Future<String> getbllistdata() async {
  if (selectlist.isEmpty) {
    return '未选择L1歌单';
  }
  if (selectmid == 0) {
    return '未选择B站收藏夹';
  }
  if (selectcreateorcol) {
    var url =
        'https://b2l.040905.xyz/test3?pn=1&ps=20&season_id=';
        // 'http://192.168.31.84:8888/test3?pn=1&ps=20&season_id=';
    var turl = url + selectmid.toString();
    final headers = {
      'content-type': 'application/json',
    };
    var medias = [];
    try {
      // print(headers);
      var response = await Dio().get(turl, options: Options(headers: headers));
      // print(response.statusCode);
      // print(response.data);
      var res = response.data;
      print('转码成功');
      res["data"]['medias'].forEach((element) {
        medias.add(element);
      });
      if (medias.length == res["data"]['info']['media_count']) {
        var tlist = globalconfig[selectlist]["tracks"];
        if (opt == '覆盖现有') {
          medias.forEach((element) {
            var temp = {
              "id": "bitrack_v_" + element['bvid'],
              "title": element['title'],
              "artist": element['upper']['name'],
              "artist_id": "biartist_v_" + element['upper']['mid'].toString(),
              "source": "bilibili",
              "source_url": "https://www.bilibili.com/" + element['bvid'],
              "img_url": element['cover'],
              "sourceName": "哔哩",
              "disabled": false,
              "playNow": false,
              "platform": "bilibili",
              "platformText": "哔哩"
            };
            var flag = false;
            for (var i = 0; i < tlist.length; i++) {
              if (tlist[i]['id'] == temp['id']) {
                tlist[i] = temp;
                flag = true;
                break;
              }
            }
            if (!flag) {
              tlist.add(temp);
            }
          });
        } else if (opt == '加到末尾') {
          medias.forEach((element) {
            var temp = {
              "id": "bitrack_v_" + element['bvid'],
              "title": element['title'],
              "artist": element['upper']['name'],
              "artist_id": "biartist_v_" + element['upper']['mid'].toString(),
              "source": "bilibili",
              "source_url": "https://www.bilibili.com/" + element['bvid'],
              "img_url": element['cover'],
              "sourceName": "哔哩",
              "disabled": false,
              "playNow": false,
              "platform": "bilibili",
              "platformText": "哔哩"
            };
            tlist.add(temp);
          });
        }
        globalconfig[selectlist]["tracks"] = tlist;
        return '';
      } else {
        return '获取失败';
      }
    } on DioException catch (e) {
      print('请求失败: ${e.message}');
      if (e.response != null) {
        print('响应数据: ${e.response?.data}');
        print('响应头: ${e.response?.headers}');
        print('请求信息: ${e.response?.requestOptions}');
      } else {
        print('请求未发送: ${e.requestOptions}');
        print('错误信息: ${e.message}');
      }
      return '请求失败: ${e.message}'; // 请求失败，返回错误信息
    } catch (e) {
      print('未知错误: $e');
      return '未知错误: $e'; // 请求失败，返回错误信息
    }
  } else {
    var url =
        'https://b2l.040905.xyz/test2?ps=20&keyword&order=mtime&type=0&tid=0&platform=web&';
        // 'http://192.168.31.84:8888/test2?ps=20&keyword&order=mtime&type=0&tid=0&platform=web&';
    var turl = url + 'pn=1&media_id=' + selectmid.toString();
    final headers = {
      'content-type': 'application/json',
      'coo': cookie,
    };
    var medias = [];
    try {
      // print(headers);
      var response = await Dio().get(turl, options: Options(headers: headers));
      // print(response.statusCode);
      // print(response.data);
      var res = response.data;
      print('转码成功');
      res["data"]['medias'].forEach((element) {
        medias.add(element);
      });
      if (res["data"]['has_more']) {
        var pn = 2;
        do {
          turl = url + 'pn=$pn&media_id=' + selectmid.toString();
          response = await dio.get(turl,
              options: Options(headers: {'cookie': cookie}));
          // res = jsonDecode(response.data);
          res = response.data;
          res["data"]['medias'].forEach((element) {
            medias.add(element);
          });
          pn++;
        } while (res["data"]['has_more']);
      }
      if (medias.length == res["data"]['info']['media_count']) {
        var t = {
          "id": 1905501752,
          "type": 2,
          "title": "【洛天依V3+V4+V5原创曲】再生【阿良良木健】",
          "cover":
              "http://i2.hdslb.com/bfs/archive/bbb1092c2c16bebd664fc8590acdf82f29c3fbce.jpg",
          "intro":
              "在第12个生日到来的一个月前\n在这缤纷的「再生之夏」揭幕之时\n尘封两年 《再生》姗姗来迟\n\n这首歌的投稿 完全是出于意外\n但我想 也是时候了\n是时候 让更多的人听到这一首\n由三个时空 三种音色 三代的洛天依 共同吟唱的旋律\n也希望 带给你们 不止三倍的感动\n愿我们缤纷的梦 能永远「再生」\n\n原曲收录自2022年起点计划出品\n中文VOCALOID同人原创专辑《拾》BV1Gv4y1K7hG\n\n（间奏选取自Johann Pachelbel所作《Canon in D》）\n\n作词：@St_色太  \n作曲·编曲·调校",
          "page": 1,
          "duration": 253,
          "upper": {
            "mid": 112428,
            "name": "阿良良木健",
            "face":
                "https://i0.hdslb.com/bfs/face/da441327b01b8ca98b97496f0a3e67431cd19a8f.jpg"
          },
          "attr": 0,
          "cnt_info": {
            "collect": 13678,
            "play": 147610,
            "danmaku": 490,
            "vt": 0,
            "play_switch": 0,
            "reply": 0,
            "view_text_1": "14.8万"
          },
          "link": "bilibili://video/1905501752",
          "ctime": 1718118342,
          "pubtime": 1718118342,
          "fav_time": 1718204781,
          "bv_id": "BV1SS411K7Dx",
          "bvid": "BV1SS411K7Dx",
          "season": null,
          "ogv": null,
          "ugc": {"first_cid": 1578747690},
          "media_list_link":
              "bilibili://music/playlist/playpage/3178913425?page_type=3&oid=1905501752&otype=2"
        };
//           import json
// with open('input.json','r',encoding='utf-8') as f:
//     data=json.load(f)
// data=data['data']['medias']
// output=[]
// for i in data:
//     temp={}
//     temp['id']="bitrack_v_"+i['bvid']
//     temp['title']=i['title']
//     temp['artist']=i['upper']['name']
//     temp['artist_id']="biartist_v_"+str(i['upper']['mid'])
//     temp['source']="bilibili"
//     temp['source_url']="https://www.bilibili.com/"+i['bvid']
//     temp['img_url']=i['cover']
//     temp['sourceName']="哔哩"
//     temp['disabled']=False
//     temp['playNow']=False
//     temp['platform']="bilibili"
//     temp['platformText']="哔哩"
//     output.append(temp)
// with open('output.txt','w',encoding='utf-8') as f:
//     json.dump(output,f,ensure_ascii=False,indent=4)
        var tlist = globalconfig[selectlist]["tracks"];
        if (opt == '覆盖现有') {
          medias.forEach((element) {
            var temp = {
              "id": "bitrack_v_" + element['bvid'],
              "title": element['title'],
              "artist": element['upper']['name'],
              "artist_id": "biartist_v_" + element['upper']['mid'].toString(),
              "source": "bilibili",
              "source_url": "https://www.bilibili.com/" + element['bvid'],
              "img_url": element['cover'],
              "sourceName": "哔哩",
              "disabled": false,
              "playNow": false,
              "platform": "bilibili",
              "platformText": "哔哩"
            };
            var flag = false;
            for (var i = 0; i < tlist.length; i++) {
              if (tlist[i]['id'] == temp['id']) {
                tlist[i] = temp;
                flag = true;
                break;
              }
            }
            if (!flag) {
              tlist.add(temp);
            }
          });
        } else if (opt == '加到末尾') {
          medias.forEach((element) {
            var temp = {
              "id": "bitrack_v_" + element['bvid'],
              "title": element['title'],
              "artist": element['upper']['name'],
              "artist_id": "biartist_v_" + element['upper']['mid'].toString(),
              "source": "bilibili",
              "source_url": "https://www.bilibili.com/" + element['bvid'],
              "img_url": element['cover'],
              "sourceName": "哔哩",
              "disabled": false,
              "playNow": false,
              "platform": "bilibili",
              "platformText": "哔哩"
            };
            tlist.add(temp);
          });
        }
        globalconfig[selectlist]["tracks"] = tlist;
        return '';
      } else {
        return '获取失败';
      }
    } on DioException catch (e) {
      print('请求失败: ${e.message}');
      if (e.response != null) {
        print('响应数据: ${e.response?.data}');
        print('响应头: ${e.response?.headers}');
        print('请求信息: ${e.response?.requestOptions}');
      } else {
        print('请求未发送: ${e.requestOptions}');
        print('错误信息: ${e.message}');
      }
      return '请求失败: ${e.message}'; // 请求失败，返回错误信息
    } catch (e) {
      print('未知错误: $e');
      return '未知错误: $e'; // 请求失败，返回错误信息
    }
  }
}

class TakePictureScreenState extends State<TakePictureScreen> {
  @override
  void initState() {
    super.initState();
    // connectToWebSocket();
    // camera = widget.cameras;
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入B站收藏夹到L1'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            String ok = await downloadJsonFile();
            if (ok != '') {
              throw ok;
            }
            // 弹出提示信息
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('配置文件已保存'),
            ));
          } catch (e) {
            print(e);
            // 弹出提示信息
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('配置文件保存失败: $e'),
            ));
          }
        },
        child: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
          child: Center(
              child: Column(
        children: [
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 20),
                        width: MediaQuery.of(context).size.width / 2.5,
                        child: ElevatedButton(
                          child: Text('打开cookie获取页面',
                              style: TextStyle(fontSize: 20)),
                          onPressed: () async {
                            // await storeGlobalVariable();
                            // downloadJsonFile();
                            try {
                              await html.window.open(
                                  'https://mashir0-bilibili-qr-login.hf.space/',
                                  'bilibili');
                              // 弹出提示信息
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('打开成功'),
                              ));
                            } catch (e) {
                              print(e);
                              // 弹出提示信息
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('打开失败'),
                              ));
                            }
                          },
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        margin: EdgeInsets.symmetric(vertical: 30),
                        child: ElevatedButton(
                          child: Text('读取listen1的备份文件',
                              style: TextStyle(fontSize: 20)),
                          onPressed: () async {
                            try {
                              bool ret = await loadConfigFromFile();
                              if (!ret) {
                                throw '文件读取失败';
                              }
                              setState(() {});
                              //弹出提示信息
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('配置已加载'),
                              ));
                            } catch (e) {
                              print(e);
                              // 弹出提示信息
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('配置加载失败'),
                              ));
                            }
                            // setState(() {});
                          },
                        ),
                      ),
                    ]),
                Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height / 4,
                                ),
                                child: TextField(
                                  maxLines: null, // 允许多行输入
                                  decoration: InputDecoration(
                                    labelText: '输入Cookie',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    // 处理输入的cookie值
                                    // print('输入的Cookie: $value');
                                    cookie = value;
                                  },
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            child:
                                Text('查询B站歌单', style: TextStyle(fontSize: 20)),
                            onPressed: () async {
                              // await storeGlobalVariable();
                              // downloadJsonFile();
                              try {
                                String ret =
                                    await fetchBilibiliData(); // 使用 await 等待异步函数完成
                                if (ret.isNotEmpty) {
                                  throw ret; // 如果返回值不为空，抛出错误信息
                                }
                                b1 = true;
                                setState(() {
                                  // 更新界面
                                });
                                // 弹出提示信息
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('查询成功'),
                                ));
                              } catch (e) {
                                print(e);
                                // 弹出提示信息
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('查询失败: $e'),
                                ));
                              }
                            },
                          ),
                        ])),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 30),
                  child: ElevatedButton(
                    child: Text('执行', style: TextStyle(fontSize: 20)),
                    onPressed: () async {
                      // await storeGlobalVariable();
                      // downloadJsonFile();
                      try {
                        String res = await getbllistdata(); // 使用 await 等待异步函数完成
                        if (res.isNotEmpty) {
                          throw res; // 如果返回值不为空，抛出错误信息
                        }
                        // 弹出提示信息
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('执行成功'),
                        ));
                      } catch (e) {
                        print(e);
                        // 弹出提示信息
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('执行失败: $e'),
                        ));
                      }
                    },
                  ),
                ),
                Container(
                    margin: EdgeInsets.symmetric(vertical: 30),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 3,
                          alignment: Alignment.center,
                          child: Text(selectmidname,
                              style: TextStyle(fontSize: 20)),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 3,
                          alignment: Alignment.center,
                          child: Column(children: [
                            ListTile(
                              title: const Text('覆盖现有',
                                  style: TextStyle(fontSize: 20)),
                              onTap: () {
                                setState(() {
                                  opt = '覆盖现有';
                                });
                              },
                              leading: Radio<String>(
                                value: '覆盖现有',
                                groupValue: opt,
                                onChanged: (String? value) {
                                  setState(() {
                                    opt = value!;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('加到末尾',
                                  style: TextStyle(fontSize: 20)),
                              onTap: () {
                                setState(() {
                                  opt = '加到末尾';
                                });
                              },
                              leading: Radio<String>(
                                value: '加到末尾',
                                groupValue: opt,
                                onChanged: (String? value) {
                                  setState(() {
                                    opt = value!;
                                  });
                                },
                              ),
                            ),
                          ]),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 3,
                          alignment: Alignment.center,
                          child: Text(selectlistname,
                              style: TextStyle(fontSize: 20)),
                        )
                      ],
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // if (false)
                    Container(
                      width: MediaQuery.of(context).size.width / 2,
                      child: SingleChildScrollView(
                        child: Column(
                          children: b1
                              ? [
                                  ...(bilibiliData["data"][0]
                                          ["mediaListResponse"]["list"] as List)
                                      .map<Widget>((playlist) {
                                    return ListTile(
                                      title: Text(playlist['title'],
                                          style: TextStyle(fontSize: 20)),
                                      onTap: () {
                                        setState(() {
                                          selectcreateorcol = false;
                                          selectmid = playlist['id'];
                                          selectmidname = playlist['title'];
                                        });
                                      },
                                    );
                                  }).toList(),
                                  ...bilibiliData2.map<Widget>((playlist) {
                                    return ListTile(
                                      title: Text(playlist['title'],
                                          style: TextStyle(fontSize: 20)),
                                      onTap: () {
                                        setState(() {
                                          selectcreateorcol = true;
                                          selectmid = playlist['id'];
                                          selectmidname = playlist['title'];
                                        });
                                      },
                                    );
                                  }).toList(),
                                ]
                              : [Text('请先查询B站歌单')],
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 2,
                      child: SingleChildScrollView(
                        child: Column(
                          children: isLoaded
                              ? playlists.map((playlist) {
                                  return ListTile(
                                    title: Text(playlist['name'],
                                        style: TextStyle(fontSize: 20)),
                                    onTap: () {
                                      setState(() {
                                        selectlist = playlist['key'];
                                        selectlistname = playlist['name'];
                                      });
                                    },
                                  );
                                }).toList()
                              : [Text('请先加载listen1的备份文件')],
                        ),
                      ),
                    )
                  ],
                )
              ]),
        ],
      ))),
    );
  }
}
