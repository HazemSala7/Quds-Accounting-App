// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/Screens/invoice/invoice_card/invoice_card.dart';
// import 'package:flutter_application_1/Screens/invoice_details/invoice_details_card/invoice_details_card.dart';
// import 'package:flutter_application_1/Screens/total_receivables/total_card/total_card.dart';
// import 'package:flutter_application_1/Services/AppBar/appbar_back.dart';

// import '../../Server/server.dart';
// import '../../Services/AppBar/appbar.dart';
// import '../../Services/Drawer/drawer.dart';

// class InvoiceDetails extends StatefulWidget {
//   final date;
//   const InvoiceDetails({Key? key, this.date}) : super(key: key);

//   @override
//   State<InvoiceDetails> createState() => _InvoiceDetailsState();
// }

// class _InvoiceDetailsState extends State<InvoiceDetails> {
//   @override
//   final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
//   Widget build(BuildContext context) {
//     return Container(
//       color: Main_Color,
//       child: SafeArea(
//           child: Scaffold(
//         key: _scaffoldState,
//         drawer: DrawerMain(),
//         appBar: PreferredSize(
//             child: AppBarBack(
//               title: "تفاصيل الطلبية",
//             ),
//             preferredSize: Size.fromHeight(50)),
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   "تفاصيل الفاتورة ",
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(
//                     right: 15, left: 15, top: 15, bottom: 15),
//                 child: Row(
//                   children: [
//                     Text(
//                       "التاريخ :",
//                       style:
//                           TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//                     ),
//                     SizedBox(
//                       width: 10,
//                     ),
//                     Text(
//                       widget.date,
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 20,
//                           color: Main_Color),
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(right: 15, left: 15, top: 30),
//                 child: Container(
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 1,
//                             child: Center(
//                               child: Text(
//                                 "المجموع",
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 16),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             flex: 2,
//                             child: Center(
//                               child: Text(
//                                 "الصنف",
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 16),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             flex: 1,
//                             child: Center(
//                               child: Text(
//                                 "الخصم",
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 16),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             flex: 1,
//                             child: Center(
//                               child: Text(
//                                 "بونص",
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 16),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             flex: 1,
//                             child: Center(
//                               child: Text(
//                                 "السعر",
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 16),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 10),
//                         child: Container(
//                           width: double.infinity,
//                           height: 2,
//                           color: Color(0xffD6D3D3),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//               ListView.builder(
//                 itemCount: 15,
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemBuilder: (context, index) {
//                   return InvoiceDetailsCard(
//                     total: "100",
//                     price: "200",
//                     ponus: "540",
//                     discount: "asdasd",
//                     name: "IPhone 13 pro max",
//                   );
//                 },
//               )
//             ],
//           ),
//         ),
//       )),
//     );
//   }
// }
