import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
import 'package:quds_yaghmour/Screens/customer_details/customer_details.dart';
import 'package:quds_yaghmour/Screens/customers/customer_card/customer_card.dart';
import 'package:quds_yaghmour/Screens/kashf_hesab/kashf_hesab.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Server/server.dart' as globals;
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/Services/data_downloader/data_downloader.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';
import 'package:quds_yaghmour/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../Services/Drawer/drawer.dart';

class Customers extends StatefulWidget {
  List CustomersArray;
  var companiesArray;
  Customers({
    Key? key,
    required this.CustomersArray,
    this.companiesArray,
  }) : super(key: key);

  @override
  State<Customers> createState() => _CustomersState();
}

class _CustomersState extends State<Customers> with RouteAware {
  @override
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _showMicOverlay = false;
  final TextEditingController _areaSearchCtrl = TextEditingController();

  void _filterByNameAndArea(String nameInput, String areaInput) {
    final name = nameInput.trim();
    final area = areaInput.trim();

    if (name.isEmpty && area.isEmpty) {
      setState(() => filteredCustomers = widget.CustomersArray);
      return;
    }

    setState(() {
      filteredCustomers = widget.CustomersArray.where((customer) {
        final cName = (customer['c_name'] ?? '').toString();
        final cArea = (customer['c_area_name'] ?? '').toString();

        final nameOK = name.isEmpty
            ? true
            : (cName.toLowerCase().contains(name.toLowerCase()) ||
                cName.contains(name));

        final areaOK = area.isEmpty
            ? true
            : (cArea.toLowerCase().contains(area.toLowerCase()) ||
                cArea.contains(area));

        return nameOK && areaOK;
      }).toList();
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _showMicOverlay = true;
      });

      _speech.listen(
        localeId: 'ar',
        listenMode: stt.ListenMode.dictation,
        onResult: (result) async {
          if (result.finalResult) {
            String command = result.recognizedWords;
            print("Command: $command");

            setState(() {
              _isListening = false;
              _showMicOverlay = false;
            });

            await _processCommand(command);
          }
        },
        onSoundLevelChange: (level) {
          // Optional: you can add animation intensity using sound level
        },
        cancelOnError: true,
      );
    } else {
      Fluttertoast.showToast(msg: "الميكروفون غير متاح");
    }
  }

  Future<void> _processCommand(String command) async {
    if (command.contains("كشف حساب")) {
      String name = command.split("كشف حساب").last.trim();

      // 1. Exact contains match
      var customer = widget.CustomersArray.firstWhere(
        (c) => c['c_name'].toString().contains(name),
        orElse: () => null,
      );

      if (customer == null) {
        // 2. Try startsWith
        customer = widget.CustomersArray.firstWhere(
          (c) => c['c_name'].toString().startsWith(name),
          orElse: () => null,
        );
      }

      if (customer == null) {
        // 3. Fuzzy match using string similarity
        List<Map<String, dynamic>> sortedCustomers = [...widget.CustomersArray];

        sortedCustomers.sort((a, b) {
          double aSim = StringSimilarity.compareTwoStrings(
            name,
            a['c_name'].toString(),
          );
          double bSim = StringSimilarity.compareTwoStrings(
            name,
            b['c_name'].toString(),
          );
          return bSim.compareTo(aSim); // highest similarity first
        });

        // Use top 1 match only if similarity > 0.3
        if (sortedCustomers.isNotEmpty) {
          double bestScore = StringSimilarity.compareTwoStrings(
            name,
            sortedCustomers.first['c_name'].toString(),
          );

          if (bestScore > 0.3) {
            customer = sortedCustomers.first;
          }
        }
      }

      if (customer != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KashfHesab(
              balance: customer["c_balance"].toString(),
              name: customer["c_name"].toString(),
              customer_id: customer["id"].toString(),
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "لم يتم العثور على الزبون '$name'");
      }
    } else {
      Fluttertoast.showToast(msg: "يرجى قول: 'كشف حساب الزبون [اسم]'");
    }
  }

  bool search = false;
  var filteredCustomers = [];
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  TextEditingController qrCodeController = TextEditingController();
  Widget build(BuildContext context) {
    return Container(
      color: globals.Main_Color,
      child: SafeArea(
          child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Scaffold(
            key: _scaffoldState,
            drawer: DrawerMain(),
            appBar: PreferredSize(
                child: AppBarMain(), preferredSize: Size.fromHeight(50)),
            body: SingleChildScrollView(
                child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 10, top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: const Color(0xffE9E9E9)),
                    ),
                    child: Column(
                      children: [
                        // ===== Row 1: Name + Area =====
                        Row(
                          children: [
                            // Name search (same behavior as before)
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  onChanged: (searchInput) {
                                    if (searchInput.isEmpty &&
                                        _areaSearchCtrl.text.isEmpty) {
                                      setState(() => filteredCustomers =
                                          widget.CustomersArray);
                                    } else {
                                      _filterByNameAndArea(
                                          searchInput, _areaSearchCtrl.text);
                                    }
                                  },
                                  textInputAction: TextInputAction.search,
                                  textAlign: TextAlign.start,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: 'بحث عن أسم الزبون',
                                    hintStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400),
                                    filled: true,
                                    fillColor: const Color(0xffF9F9FB),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          width: 1.5, color: Color(0xffE5E5EC)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          width: 2.0,
                                          color: globals.Main_Color),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Area search (c_are_name)
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: _areaSearchCtrl,
                                  onChanged: (areaInput) {
                                    _filterByNameAndArea('', areaInput);
                                  },
                                  textInputAction: TextInputAction.search,
                                  textAlign: TextAlign.start,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    prefixIcon:
                                        const Icon(Icons.location_on_outlined),
                                    hintText: 'بحث من خلال المنطقة',
                                    hintStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400),
                                    filled: true,
                                    fillColor: const Color(0xffF9F9FB),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          width: 1.5, color: Color(0xffE5E5EC)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          width: 2.0,
                                          color: globals.Main_Color),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ===== Row 2: QR + Button =====
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: qrCodeController,
                                  textInputAction: TextInputAction.done,
                                  textAlign: TextAlign.start,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    prefixIcon:
                                        const Icon(Icons.qr_code_2_rounded),
                                    hintText: 'بحث من خلال QR',
                                    hintStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                    filled: true,
                                    fillColor: const Color(0xffF9F9FB),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          width: 1.5, color: Color(0xffE5E5EC)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          width: 2.0,
                                          color: globals.Main_Color),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 50,
                              child: InkWell(
                                onTap: () {
                                  var customer =
                                      widget.CustomersArray.firstWhere(
                                    (c) =>
                                        c['id'].toString() ==
                                        qrCodeController.text.trim(),
                                    orElse: () => null,
                                  );
                                  if (customer != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerDetails(
                                          edit: customer["c_name"].toString() ==
                                              "زبون جديد",
                                          balance: customer["c_balance"],
                                          lattitude:
                                              customer["latitude"] ?? 0.0,
                                          longitude:
                                              customer["longitude"] ?? 0.0,
                                          id: customer["id"],
                                          name: customer["c_name"],
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('No customer found')),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromRGBO(83, 89, 219, 1),
                                        Color.fromRGBO(32, 39, 160, 0.6),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.deepPurple.withOpacity(0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text('بحث',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _startListening,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(83, 89, 219, 1),
                                Color.fromRGBO(32, 39, 160, 0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.4),
                                spreadRadius: 5,
                                blurRadius: 20,
                              )
                            ],
                          ),
                          child: Center(
                            child:
                                Icon(Icons.mic, size: 40, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "تحدث لرؤية كشف حساب الزبون",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(
                    height: 40,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15, left: 15),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                  border: Border.all(color: Colors.white)),
                              child: Center(
                                child: Text(
                                  "الرقم",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                  border: Border.all(color: Colors.white)),
                              child: Center(
                                child: Text(
                                  "أسم الزبون",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                  border: Border.all(color: Colors.white)),
                              child: Center(
                                child: Text(
                                  "رقم الهاتف",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                  border: Border.all(color: Colors.white)),
                              child: Center(
                                child: Text(
                                  "المنطقة",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemCount: filteredCustomers.length,
                  itemBuilder: (BuildContext context, int index) {
                    return CustomerCard(
                      lattitude: filteredCustomers[index]['latitude'] ?? 0.0,
                      longitude: filteredCustomers[index]['longitude'] ?? 0.0,
                      index: index,
                      id: filteredCustomers[index]['id'] ?? 0,
                      name: filteredCustomers[index]['c_name'] ?? "",
                      area: filteredCustomers[index]['c_area'] ?? "-",
                      cash: filteredCustomers[index]['cash'] ?? "",
                      balance: filteredCustomers[index]['c_balance'].toString(),
                      price_code: filteredCustomers[index]['price_code'] ?? "",
                      phone: filteredCustomers[index]['phone1'] ?? " - ",
                    );
                  },
                ),
              ],
            )),
          ),
          if (_showMicOverlay)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.redAccent, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "جاري الاستماع...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          Visibility(
            visible: !globals.isOnline,
            child: Material(
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                  Color.fromRGBO(83, 89, 219, 1),
                  Color.fromRGBO(32, 39, 160, 0.6),
                ])),
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
                            //   Fluttertoast.showToast(
                            //       msg: "لا يوجد اتصال بالانترنت");
                            // }
                          },
                          child: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload,
                                  color: Colors.white,
                                ),
                                Text(
                                  "تصدير",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white),
                                )
                              ],
                            ),
                          ),
                        )),
                    Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            final dbHelper = CartDatabaseHelper();
                            List<CatchModel> receipts =
                                await dbHelper.getUnuploadedCatchReceipts();
                            List<CatchVansaleModel> receiptsVansale =
                                await dbHelper
                                    .getUnuploadedCatchReceiptsVansale();

                            List<Map<String, dynamic>> localOrders =
                                await dbHelper.getUnUploadedOrders();

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
                                                  ValueNotifier<String>(
                                                      "Starting...");
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
                                                    msg:
                                                        'Failed to download data');
                                                Navigator.pop(context);
                                              } finally {
                                                if (Navigator.canPop(context)) {
                                                  // ✅ Ensure there is an open dialog before closing
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                  Navigator.pop(context);
                                                }
                                              }
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    content: Text(
                                                        'لا يمكن مزامنة البيانات حتى يكون وضع العمل محليا مفعل'),
                                                    actions: <Widget>[
                                                      ButtonWidget(
                                                          name: "حسنا",
                                                          height: 40,
                                                          width: 100,
                                                          BorderColor: globals
                                                              .Main_Color,
                                                          FontSize: 16,
                                                          OnClickFunction: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          BorderRaduis: 10,
                                                          ButtonColor: globals
                                                              .Main_Color,
                                                          NameColor:
                                                              Colors.white)
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          },
                                          BorderRaduis: 10,
                                          ButtonColor: globals.Main_Color,
                                          NameColor: Colors.white),
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
                                          NameColor: Colors.white)
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
                                          OnClickFunction: () async {
                                            Navigator.pop(context);
                                          },
                                          BorderRaduis: 10,
                                          ButtonColor: globals.Main_Color,
                                          NameColor: Colors.white),
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
                                Icon(
                                  Icons.download,
                                  color: Colors.white,
                                ),
                                Text(
                                  "استيراد",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white),
                                )
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          )
        ],
      )),
    );
  }

  DataDownloader dataDownloader = DataDownloader();
  @override
  void initState() {
    super.initState();
    filteredCustomers = widget.CustomersArray;
    _loadOnlineStatus();
    _refreshSettings();
    _speech = stt.SpeechToText();
    _areaSearchCtrl.addListener(() {
      _filterByNameAndArea('', _areaSearchCtrl.text);
    });
  }

  void _loadOnlineStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      globals.isOnline = prefs.getBool('isOnline') ?? true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _areaSearchCtrl.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!isOnline) {
      _refreshSettings();
      _refreshCustomers(); // reload customer list if store changed
    }
  }

  void _refreshSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? store_id_order = prefs.getString('store_id');
    setState(() {
      globals.isOnline = prefs.getBool('isOnline') ?? true;
      globals.productStyleTwo = prefs.getBool('productStyleTwo') ?? false;
      globals.ponus1 = prefs.getBool('ponus1') ?? false;
      globals.desc = prefs.getBool('desc') ?? false;
      globals.ponus2 = prefs.getBool('ponus2') ?? false;
      globals.notes = prefs.getBool('notes') ?? false;
      globals.discountSetting = prefs.getBool('discount') ?? false;
      globals.existed_qty = prefs.getBool('existed_qty') ?? false;
      globals.order_kashf_from_new_to_old =
          prefs.getBool('order_kashf_from_new_to_old') ?? false;
      globals.store_id = prefs.getString('store_id') ?? "";
      globals.deliveryDate = prefs.getBool('deliveryDate') ?? false;
      globals.hideProductLessThan0 =
          prefs.getBool('hideProductLessThan0') ?? false;
    });
  }

  void _refreshCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? companyId = prefs.getInt("company_id");
    int? salesmanId = prefs.getInt("salesman_id");

    if (companyId != null && salesmanId != null) {
      try {
        var response = await http.get(Uri.parse(
            'https://yaghm.com/admin/api/customers/$companyId/$salesmanId'));
        var decoded = jsonDecode(response.body);
        setState(() {
          filteredCustomers = decoded['customers'];
        });
      } catch (e) {
        Fluttertoast.showToast(msg: "فشل تحميل الزبائن");
      }
    }
  }
}
