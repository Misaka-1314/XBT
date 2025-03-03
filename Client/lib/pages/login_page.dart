import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbt_client/utils/constants.dart';
import 'package:xbt_client/utils/dio.dart';
import 'package:xbt_client/utils/encode.dart';
import 'package:xbt_client/utils/local_json.dart';

class LoginPage extends StatefulWidget {
  final showBack;
  const LoginPage({super.key, this.showBack = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    TextEditingController _passwordController = TextEditingController();
    TextEditingController _mobileController = TextEditingController();
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        body: SafeArea(
          child: Center(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "学不通",
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.4, color: Theme.of(context).colorScheme.primary, shadows: [
                        Shadow(
                          color: Color.fromRGBO(0, 0, 0, 0.2),
                          offset: Offset(1, 1),
                          blurRadius: 18,
                        )
                      ]),
                    ),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: "手机号", hintText: "请输入手机号"),
                    ),
                    TextField(
                      obscureText: true,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "密码",
                        hintText: "请输入学不(习)通密码",
                      ),
                    ),
                    Text("注册即代表同意本软件收集您的第三方网站隐私信息。其中包括: 姓名，手机号，密码，课程信息等。您的密码将仅用于登录第三方网站，已经过非对称加密处理，本软件保证您的密码不会进行明文存储以及传输。"),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      margin: EdgeInsets.only(top: 32),
                      height: 44,
                      width: double.infinity,
                      child: MaterialButton(
                        onPressed: () async {
                          String mobile = _mobileController.text;
                          String password = _passwordController.text;
                          SmartDialog.showLoading(msg: "登录中...");
                          String token = await encodeToken(mobile, password);
                          var resp = await dio.post(baseURL + "/login", data: {
                            "token": token,
                          });
                          SmartDialog.dismiss();
                          if (!resp.data["suc"]) {
                            SmartDialog.showNotify(msg: resp.data["msg"], notifyType: NotifyType.failure);
                            return;
                          }
                          var localUserList = await LocalJson.getItem("localUserList")!;
                          for (var i = 0; i < localUserList.length; i++) {
                            if (localUserList[i]["mobile"] == mobile) {
                              localUserList.removeAt(i);
                              break;
                            }
                          }
                          localUserList.insert(0, {
                            "token": token,
                            "mobile": mobile,
                            "uid": resp.data["data"]["uid"],
                            "name": resp.data["data"]["name"],
                            "avatar": resp.data["data"]["avatar"],
                          });
                          await prefs.clear();
                          await prefs.setString("token", token);
                          await LocalJson.setItem("localUserList", localUserList);
                          Navigator.maybePop(context);
                          SmartDialog.showNotify(msg: "登录成功", notifyType: NotifyType.success);
                          if (localUserList.length > 1) {
                            Restart.restartApp();
                          }
                        },
                        child: Text("登录 / 注册", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                    if (widget.showBack)
                      TextButton(
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                          child: Text("返回")),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
