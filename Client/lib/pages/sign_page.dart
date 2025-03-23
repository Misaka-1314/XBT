import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:coordtransform_dart/coordtransform_dart.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gesture_password/gesture_view.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // 替换为 mobile_scanner
import 'package:xbt_client/main.dart';
import 'package:xbt_client/pages/sign_progress_page.dart';
import 'package:xbt_client/utils/constants.dart';
import 'package:xbt_client/utils/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SignPage extends StatefulWidget {
  final Map<String, dynamic>? signData;
  final Map<String, dynamic>? courseData;
  const SignPage({super.key, this.signData, this.courseData});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> with RouteAware {
  Map<String, dynamic>? locationData;
  String code = '';
  List<Map<String, dynamic>> classmates = [];
  bool isSigning = false;

  // MobileScanner 相关变量
  late MobileScannerController _scannerController;
  Barcode? result;

  // 添加缩放控制相关变量
  double _currentZoom = 0.0; // 改为0.0作为最小值，与slider 0-100%对应
  double _baseZoom = 0.0; // 基准缩放值，在开始缩放手势时保存
  double _minZoom = 0.0;
  double _maxZoom = 1.0; // 最大值为1.0，表示100%
  bool _isZoomInitialized = false;
  bool _isCameraStarted = false; // 添加相机启动状态标志
  
  // 添加上次设置的缩放值记录
  double _lastSetZoom = 1.0;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _scannerController.stop();
      _isCameraStarted = false; // 重置相机状态
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyApp.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    isSigning = false;
  }

  @override
  void initState() {
    updateClassmates();
    // 使用简单的初始化方式，参考官方示例
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.qrCode], // 仅限QR码提高性能
    );
    // 简化初始化流程
    _initializeCamera();
    super.initState();
  }

  // 简化相机初始化流程
  void _initializeCamera() async {
    try {
      // 启动相机
      await _scannerController.start();
      _isCameraStarted = true;
      _isZoomInitialized = true;
      if (mounted) setState(() {});
    } catch (e) {
      print('初始化相机失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('相机初始化失败，请检查相机权限或重启应用')),
        );
      }
    }
  }
  
  // 简化重置缩放方法
  void _resetZoom() {
    if (!_isCameraStarted) return;
    
    setState(() {
      _currentZoom = 0.0;
      _baseZoom = 0.0;
      _scannerController.setZoomScale(0.0);
    });
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    _scannerController.dispose(); // 释放资源
    super.dispose();
  }

  void updateClassmates() async {
    SmartDialog.showLoading(msg: "获取同学中...");
    var resp = await dio.post(baseURL + '/getClassmates', data: {
      "courseId": widget.signData!['courseId'],
      'classId': widget.signData!['classId']
    });
    classmates = List<Map<String, dynamic>>.from(resp.data['data']);
    for (int i = 0; i < classmates.length; i++)
      classmates[i]['isSelected'] = true;
    setState(() {
      classmates = classmates;
    });
    SmartDialog.dismiss();
  }

  void sign(Map<String, dynamic> args, SignType signType) async {
    if (isSigning) return;
    isSigning = true;
    Map<String, dynamic> fixedParams = {
      "courseId": widget.courseData!['courseId'],
      "classId": widget.courseData!['classId'],
      "activeId": widget.signData!['activeId'],
      "ifRefreshEwm": widget.signData!['ifRefreshEwm'],
      "uid": widget.signData!['uid'],
    };
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: SignProgressPage(
              fixedParams: fixedParams,
              specialParams: args,
              classmates: classmates,
              signType: signType,
              signState: (v) {
                isSigning = v;
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(SignType.fromId(widget.signData!["signType"]).name),
        elevation: 3,
        shadowColor: Theme.of(context).colorScheme.shadow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "签到信息: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                "签到标题: ${widget.signData!["name"]}\n开始时间: ${DateTime.fromMillisecondsSinceEpoch(widget.signData!["startTime"]).toString().substring(0, 19)}\n结束时间: ${widget.signData!["endTime"] == 64060559999000 ? '手动结束' : DateTime.fromMillisecondsSinceEpoch(widget.signData!["endTime"]).toString().substring(0, 19)}",
                style: TextStyle(height: 1.15, color: Colors.grey[900]),
              ),
            ),
            if (widget.signData!["signType"] == SignType.location.id)
              Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          locationData == null
                              ? '点击选择位置'
                              : locationData!['name']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 18),
                        ),
                        subtitle: locationData == null
                            ? null
                            : Text(
                                locationData!['description']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14),
                              ),
                        leading: Icon(SignType.location.icon,
                            color: Theme.of(context).colorScheme.primary),
                        onTap: () async {
                          var res = await showConfirmationDialog(
                            context: context,
                            title: "请选择位置",
                            okLabel: "确定",
                            cancelLabel: "取消",
                            contentMaxHeight: 400,
                            actions: [
                              for (int i = 0; i < locationPreset.length; i++)
                                AlertDialogAction(
                                    key: i, label: locationPreset[i]['name'])
                            ],
                          );
                          if (res == null) return;
                          setState(() {
                            locationData = locationPreset[res];
                          });
                        },
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      Container(
                        width: double.infinity,
                        height: 40,
                        color: locationData == null
                            ? Colors.grey[500]
                            : Theme.of(context).colorScheme.primary,
                        child: MaterialButton(
                          onPressed: () {
                            if (locationData == null) {
                              SmartDialog.showNotify(
                                  msg: "请先选择位置",
                                  notifyType: NotifyType.warning);
                              return;
                            }
                            sign({
                              'longitude': locationData!['lng'],
                              'latitude': locationData!['lat'],
                              'description': locationData!['description'],
                            }, SignType.location);
                          },
                          child: Text(
                            "签到",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.signData!["signType"] == SignType.gesture.id)
              Card(
                elevation: 4,
                child: LayoutBuilder(builder: (context, constraints) {
                  return Center(
                    child: GestureView(
                      width: constraints.maxWidth * 0.6,
                      height: 222,
                      listener: (arr) {
                        String signCode = arr.map((v) => v + 1).join('');
                        sign({"signCode": signCode}, SignType.gesture);
                      },
                    ),
                  );
                }),
              ),
            if (widget.signData!["signType"] == SignType.code.id)
              Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "签到码",
                            hintText: "请输入签到码",
                            icon: Icon(
                              Icons.password,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              code = value;
                            });
                          },
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      Container(
                        width: double.infinity,
                        height: 40,
                        color: code.length < 4 || code.length > 8
                            ? Colors.grey[500]
                            : Theme.of(context).colorScheme.primary,
                        child: MaterialButton(
                          onPressed: () {
                            sign({"signCode": code}, SignType.code);
                          },
                          child: Text(
                            "签到",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.signData!["signType"] == SignType.qrCode.id)
              Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(builder: (context, constraints) {
                  return SizedBox(
                    height: constraints.maxWidth,
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Container(
                        width: 1000,
                        height: 1000,
                        child: GestureDetector(
                          onScaleStart: (ScaleStartDetails details) {
                            if (!_isCameraStarted || !_isZoomInitialized) return;
                            // 记录缩放开始时的基准值
                            _baseZoom = _currentZoom;
                          },
                          onScaleUpdate: (ScaleUpdateDetails details) {
                            if (!_isCameraStarted) return;
                            
                            // 计算新的缩放值
                            double newZoom = _baseZoom * details.scale;
                            newZoom = newZoom.clamp(_minZoom, _maxZoom);
                            
                            // 只在有明显变化时更新
                            if ((newZoom - _currentZoom).abs() > 0.1) {
                              // 一步完成状态更新和缩放设置
                              setState(() {
                                _currentZoom = newZoom;
                                _scannerController.setZoomScale(newZoom);
                              });
                            }
                          },
                          onScaleEnd: (ScaleEndDetails details) {
                            if (!_isCameraStarted || !_isZoomInitialized) return;
                            // 缩放结束，更新基准值
                            _baseZoom = _currentZoom;
                          },
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: (BarcodeCapture capture) {
                                  final List<Barcode> barcodes =
                                      capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if (barcode.rawValue == null) continue;
                                    if (barcode.rawValue!.indexOf(
                                            'mobilelearn.chaoxing.com') == -1) {
                                      SmartDialog.showNotify(
                                          msg: "请扫描学习通签到二维码",
                                          notifyType: NotifyType.warning);
                                      return;
                                    }
                                    SmartDialog.showNotify(
                                        msg: "扫描成功",
                                        notifyType: NotifyType.success);
                                    String enc = barcode.rawValue!
                                        .split('&enc=')[1]
                                        .split('&')[0];
                                    String c = barcode.rawValue!
                                        .split('&c=')[1]
                                        .split('&')[0];
                                    print('enc: $enc, c: $c');
                                    sign({"enc": enc, "c": c}, SignType.qrCode);
                                    setState(() {
                                      result = barcode;
                                    });
                                    break; // 只处理第一个有效二维码
                                  }
                                },
                              ),
                              // 添加重置缩放按钮
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.restart_alt, color: Colors.white),
                                    onPressed: _resetZoom,
                                  ),
                                ),
                              ),
                              // 添加缩放滑动条
                              Positioned(
                                bottom: 16, // 调整位置到底部
                                left: 16,
                                right: 16,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.zoom_out, color: Colors.white, size: 20),
                                      Expanded(
                                        child: Slider(
                                          value: _currentZoom,
                                          min: _minZoom,
                                          max: _maxZoom,
                                          onChanged: (value) {
                                            if (!_isCameraStarted) return;
                                            
                                            // 直接在setState中设置缩放值
                                            setState(() {
                                              _currentZoom = value;
                                              _baseZoom = value;
                                              _scannerController.setZoomScale(value);
                                            });
                                          },
                                        ),
                                      ),
                                      Icon(Icons.zoom_in, color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            if (widget.signData!["signType"] == SignType.normal.id)
              Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(builder: (context, constraints) {
                  return SizedBox(
                    height: constraints.maxWidth * 0.6,
                    width: constraints.maxWidth * 0.6,
                    child: Center(
                      child: Container(
                        width: constraints.maxWidth * 0.6 * 0.5,
                        height: constraints.maxWidth * 0.6 * 0.5,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          borderRadius: BorderRadius.circular(
                              constraints.maxWidth * 0.6 * 0.5 / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(160),
                              offset: Offset(1, 1),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: () {
                            sign({}, SignType.normal);
                          },
                          child: Text(
                            "签到",
                            style: TextStyle(
                                fontSize: constraints.maxWidth * 0.6 * 0.1,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            Text(
              "你将为以下同学代签: ",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, height: 3),
            ),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < classmates.length; i++) ...[
                          ListTile(
                            title: Text(classmates[i]['name']),
                            subtitle: Text(classmates[i]['mobile']
                                .toString()
                                .replaceRange(3, 7, "****")),
                            leading: ExtendedImage.network(
                              classmates[i]['avatar'],
                              width: 48,
                              height: 48,
                              borderRadius: BorderRadius.circular(8),
                              headers: IMAGEHEADER,
                              shape: BoxShape.rectangle,
                              loadStateChanged: (state) {
                                return loadStateChangedfunc(state);
                              },
                            ),
                            onTap: () {
                              setState(() {
                                classmates[i]['isSelected'] =
                                    !classmates[i]['isSelected'];
                              });
                            },
                            trailing: Checkbox(
                              value: classmates[i]['isSelected'],
                              onChanged: (v) {
                                setState(() {
                                  classmates[i]['isSelected'] = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
