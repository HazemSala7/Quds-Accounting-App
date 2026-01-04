import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quds_yaghmour/Screens/kashf_hesab/kashf_hesab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../customer_details/customer_details.dart';

class TotalCard extends StatefulWidget {
  final name, phone, balance, id, lattitude, longitude;
  int index;
  TotalCard(
      {Key? key,
      required this.index,
      required this.id,
      required this.lattitude,
      required this.longitude,
      this.name,
      this.phone,
      required this.balance})
      : super(key: key);

  @override
  State<TotalCard> createState() => _TotalCardState();
}

class _TotalCardState extends State<TotalCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => KashfHesab(
                      balance: widget.balance.toString(),
                      customer_id: widget.id,
                      name: widget.name.toString(),
                    )));
      },
      child: Container(
        height: 40,
        color: widget.index % 2 == 0 ? Colors.white : Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(right: 15, left: 15),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xffDFDFDF),
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      "${widget.id}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      "${widget.balance}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xffDFDFDF),
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      widget.name,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CustomerDetails(
                                    lattitude: widget.lattitude,
                                    longitude: widget.longitude,
                                    edit: false,
                                    balance: widget.balance,
                                  )));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xffD6D3D3))),
                      child: Center(
                        child: Text(
                          widget.phone,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Main_Color),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: InkWell(
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      int? _index = await prefs.getInt('company_index') ?? 0;
                      String? store_name = _index == 0
                          ? prefs.getString('store_name_1')
                          : _index == 1
                              ? prefs.getString('store_name_2')
                              : prefs.getString('store_name_3');
                      String message =
                          " السيد ${widget.name.toString()}        نعلمكم بان رصيدكم الحالي لدينا    ${widget.balance.toString()} مع تحيات شركة ${store_name}";
                      if (widget.phone.toString().length > 10) {
                        (
                          Uri.parse(
                              'https://wa.me/${widget.phone}?text=$message'),
                          mode: LaunchMode.externalApplication
                        );
                      } else if (widget.phone == "") {
                        Fluttertoast.showToast(msg: "لا يوجد هاتف لهذا الزبون");
                      } else {
                        launchUrl(
                            Uri.parse(
                                'https://wa.me/972${widget.phone}?text=$message'),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xffD6D3D3))),
                      child: Center(child: FaIcon(FontAwesomeIcons.whatsapp)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
