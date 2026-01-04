import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quds_yaghmour/l10n/app_localizations.dart';
import 'package:quds_yaghmour/LocalDB/Provider/refresh-provider.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LocalDB/Provider/CartProvider.dart';
import 'Screens/login_screen/login_page.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Highly recommended to avoid manifest/runtime font loading issues
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(Quds());
}

Locale locale = Locale("ar", "AE");
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

bool cur = false;

class Quds extends StatefulWidget {
  const Quds({Key? key}) : super(key: key);

  @override
  State<Quds> createState() => _QudsState();

  static _QudsState? of(BuildContext context) =>
      context.findAncestorStateOfType<_QudsState>();
}

class _QudsState extends State<Quds> {
  bool isLogin = false;
  var customersList = [];
  setController() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool? _isLogin = await prefs.getBool('login') ?? false;
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var headers = {'ContentType': 'application/json'};
    var url = '${AppLink.customers}/$company_id/$salesman_id';
    var response = await http.get(Uri.parse(url), headers: headers);
    var res = jsonDecode(response.body)['customers'];
    String _just = await prefs.getString('just') ?? "no";
    if (_just == "no") {
      setState(() {
        JUST = true;
      });
    } else {
      setState(() {
        JUST = false;
      });
    }
    setState(() {
      isLogin = _isLogin;
      customersList = res;
    });
  }

  @override
  void initState() {
    setController();
    super.initState();
  }

  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => RefreshProvider()),
        ],
        child: MaterialApp(
          navigatorObservers: [routeObserver],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale("ar", "AE"),
            Locale("en", ""),
          ],
          locale: locale,
          theme: ThemeData(
            fontFamily: 'Cairo',
            scaffoldBackgroundColor: Colors.white,
            textTheme: ThemeData.light().textTheme.apply(
                  fontFamily: 'Cairo',
                  bodyColor: Colors.black,
                  displayColor: Colors.black,
                ),
          ),
          debugShowCheckedModeBanner: false,
          title: 'Quds',
          home:
              //  isLogin
              //     ? Customers(CustomersArray: customersList)
              //     :
              LoginScreen(),
        ));
  }
}
