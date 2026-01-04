// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';

// class InternetService {
//   final Connectivity _connectivity = Connectivity();
//   final InternetConnectionChecker _connectionChecker =
//       InternetConnectionChecker();
//   StreamSubscription<ConnectivityResult>? _subscription;
//   bool isOnline = false;

//   InternetService() {
//     _checkInitialConnection();
//     _listenToChanges();
//   }

//   /// Check internet on app start
//   Future<void> _checkInitialConnection() async {
//     isOnline = await InternetConnectionChecker().hasConnection;
//   }

//   /// Listen to internet status in real-time
//   void _listenToChanges() {
//     _subscription = _connectivity.onConnectivityChanged.listen((result) async {
//       isOnline = await InternetConnectionChecker().hasConnection;
//     });
//   }

//   /// Check before running any function
//   Future<bool> checkInternet() async {
//     return await InternetConnectionChecker().hasConnection;
//   }

//   /// Stop listener when app is closed
//   void dispose() {
//     _subscription?.cancel();
//   }
// }
