import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Server/server.dart' as globals;
import 'package:quds_yaghmour/Services/data_downloader/data_downloader.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';

class ImportExportPage extends StatefulWidget {
  @override
  _ImportExportPageState createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool isOnline = globals.isOnline;

  DataDownloader dataDownloader = DataDownloader();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update the isOnline status every time the page is pushed or popped
    setState(() {
      isOnline = globals.isOnline; // Or re-check connectivity here if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Visibility(
        visible: !isOnline,
        child: Material(
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Color.fromRGBO(83, 89, 219, 1),
                Color.fromRGBO(32, 39, 160, 0.6),
              ]),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      final List<ConnectivityResult> connectivityResult =
                          await (Connectivity().checkConnectivity());

                      // if (connectivityResult
                      //     .contains(ConnectivityResult.wifi)) {
                      await syncData(context);
                      // } else {
                      //   Fluttertoast.showToast(msg: "لا يوجد اتصال بالانترنت");
                      // }
                    },
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload, color: Colors.white),
                          Text(
                            "تصدير",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      final dbHelper = CartDatabaseHelper();
                      List<CatchModel> receipts =
                          await dbHelper.getUnuploadedCatchReceipts();
                      List<CatchVansaleModel> receiptsVansale =
                          await dbHelper.getUnuploadedCatchReceiptsVansale();
                      List<Map<String, dynamic>> localOrders =
                          await dbHelper.getPendingOrders();
                      List<Map<String, dynamic>> localOrdersVansale =
                          await dbHelper.getPendingOrdersVansale();

                      if (receipts.isEmpty &&
                          receiptsVansale.isEmpty &&
                          localOrders.isEmpty &&
                          localOrdersVansale.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Text(
                                  'هل أنت متأكد انك تريد مزامنة البيانات ؟ '),
                              actions: <Widget>[
                                ButtonWidget(
                                  name: "نعم",
                                  height: 40,
                                  width: 100,
                                  BorderColor: globals.Main_Color,
                                  FontSize: 16,
                                  OnClickFunction: () async {
                                    if (!globals.isOnline) {
                                      ValueNotifier<String> message =
                                          ValueNotifier<String>("Starting...");
                                      ValueNotifier<double> progress =
                                          ValueNotifier<double>(0.0);
                                      showProgressDialog(
                                          context, message, progress);
                                      try {
                                        await dataDownloader
                                            .downloadAndSaveData(
                                                progress, message);
                                      } catch (e) {
                                        print("error");
                                        print(e);
                                        Fluttertoast.showToast(
                                            msg: 'Failed to download data');
                                        Navigator.pop(context);
                                      } finally {
                                        if (Navigator.canPop(context)) {
                                          // Ensure there is an open dialog before closing
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                          Navigator.pop(context);
                                        }
                                      }
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: Text(
                                                'لا يمكن مزامنة البيانات حتى يكون وضع العمل محليا مفعل'),
                                            actions: <Widget>[
                                              ButtonWidget(
                                                name: "حسنا",
                                                height: 40,
                                                width: 100,
                                                BorderColor: globals.Main_Color,
                                                FontSize: 16,
                                                OnClickFunction: () {
                                                  Navigator.of(context).pop();
                                                },
                                                BorderRaduis: 10,
                                                ButtonColor: globals.Main_Color,
                                                NameColor: Colors.white,
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  BorderRaduis: 10,
                                  ButtonColor: globals.Main_Color,
                                  NameColor: Colors.white,
                                ),
                                ButtonWidget(
                                  name: "لا",
                                  height: 40,
                                  width: 100,
                                  BorderColor: globals.Main_Color,
                                  FontSize: 16,
                                  OnClickFunction: () {
                                    Navigator.of(context).pop();
                                  },
                                  BorderRaduis: 10,
                                  ButtonColor: globals.Main_Color,
                                  NameColor: Colors.white,
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Text(
                                  'يوجد بيانات محلية , الرجاء تصدير البيانات ثم قم باستيراد البيانات'),
                              actions: <Widget>[
                                ButtonWidget(
                                  name: "حسنا",
                                  height: 40,
                                  width: 100,
                                  BorderColor: globals.Main_Color,
                                  FontSize: 16,
                                  OnClickFunction: () {
                                    Navigator.pop(context);
                                  },
                                  BorderRaduis: 10,
                                  ButtonColor: globals.Main_Color,
                                  NameColor: Colors.white,
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, color: Colors.white),
                          Text(
                            "استيراد",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
