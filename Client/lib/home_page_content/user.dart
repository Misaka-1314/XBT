import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbt_client/main.dart';
import 'package:xbt_client/pages/login_page.dart';
import 'package:xbt_client/utils/constants.dart';
import 'package:xbt_client/utils/local_json.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> with RouteAware {
  List users = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyApp.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    refreshPage();
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void initState() {
    refreshPage();
    super.initState();
  }

  refreshPage() async {
    var localUserList = await LocalJson.getItem("localUserList")!;
    setState(() {
      users.clear();
      for (var user in localUserList) {
        users.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("用户"),
        elevation: 3,
        shadowColor: Theme.of(context).colorScheme.shadow,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return LoginPage();
            }),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "当前用户:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 3),
                ),
                if (users.length > 0)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: ExtendedImage.network(users[0]["avatar"],
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(8),
                          headers: IMAGEHEADER,
                          shape: BoxShape.rectangle, loadStateChanged: (state) {
                        return loadStateChangedfunc(state);
                      }),
                      title: Text(users[0]["name"]),
                      subtitle: Text(users[0]["mobile"].toString().replaceRange(3, 7, "****")),
                      trailing: TextButton(
                          onPressed: () {
                            showOkCancelAlertDialog(context: context, title: "退出登录", message: "是否退出登录?", okLabel: "退出", cancelLabel: "取消").then((res) async {
                              if (res == OkCancelResult.cancel) return;
                              var localUserList = await LocalJson.getItem("localUserList");
                              localUserList.removeAt(0);
                              await prefs.clear();
                              await LocalJson.setItem("localUserList", localUserList);
                              if (localUserList.length > 0) {
                                await prefs.setString("token", localUserList[0]["token"]);
                              }
                              refreshPage();
                              SmartDialog.showNotify(msg: "退出成功", notifyType: NotifyType.success);
                              Restart.restartApp();
                            });
                          },
                          child: Text("退出登录")),
                    ),
                  ),
                if (users.length > 1)
                  Text(
                    "其它用户:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 3),
                  ),
                for (int i = 1; i < users.length; i++)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Text(users[i]["name"]),
                      subtitle: Text(users[i]["mobile"].toString().replaceRange(3, 7, "****")),
                      leading: ExtendedImage.network(users[i]["avatar"],
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(8),
                          headers: IMAGEHEADER,
                          shape: BoxShape.rectangle, loadStateChanged: (state) {
                        return loadStateChangedfunc(state);
                      }),
                      onTap: () async {
                        var res = await showOkCancelAlertDialog(context: context, title: "切换用户", message: "是否切换到该用户?", okLabel: "切换", cancelLabel: "取消");
                        if (res == OkCancelResult.cancel) return;
                        var localUserList = await LocalJson.getItem("localUserList");
                        var tmp = localUserList[i];
                        localUserList.removeAt(i);
                        localUserList.insert(0, tmp);
                        await prefs.clear();
                        await LocalJson.setItem("localUserList", localUserList);
                        await prefs.setString("token", localUserList[0]['token']);
                        refreshPage();
                        SmartDialog.showNotify(msg: "切换成功", notifyType: NotifyType.success);
                        Restart.restartApp();
                      },
                      trailing: TextButton(
                          onPressed: () {
                            showOkCancelAlertDialog(context: context, title: "删除用户", message: "是否删除该用户?", okLabel: "删除", cancelLabel: "取消").then((res) async {
                              if (res == OkCancelResult.cancel) return;
                              var localUserList = await LocalJson.getItem("localUserList");
                              localUserList.removeAt(i);
                              await LocalJson.setItem("localUserList", localUserList);
                              refreshPage();
                              SmartDialog.showNotify(msg: "删除成功", notifyType: NotifyType.success);
                            });
                          },
                          child: Text("删除")),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
