import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Screens/show_order/order_card/order_card.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../LocalDB/Models/CartModel.dart';
import '../../LocalDB/Provider/CartProvider.dart';
import '../../Services/Drawer/drawer.dart';
import '../add_order/add_order.dart';

class ShowOrder extends StatefulWidget {
  const ShowOrder({Key? key, this.id, this.name}) : super(key: key);

  final id, name;

  @override
  State<ShowOrder> createState() => _ShowOrderState();
}

class _ShowOrderState extends State<ShowOrder> {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  String type = "";

  Future<void> setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final _type = prefs.getString('type') ?? "";
    if (!mounted) return;
    setState(() {
      type = _type;
    });
  }

  @override
  void initState() {
    setControllers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.cartItems;

    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Scaffold(
              key: _scaffoldState,
              drawer: DrawerMain(),
              appBar: const PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: AppBarBack(title: "عرض الطلبية"),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // اسم الزبون
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 15, left: 15, top: 15, bottom: 15),
                      child: Row(
                        children: [
                          const Text(
                            "أسم الزبون : ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.name ?? "",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Main_Color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // بطاقة الملخّص (مجاميع الكميات والبونص)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      child: _TotalsCard(
                        qtyTotal: sumQty(items),
                        bonus1Total: sumBonus1(items),
                        bonus2Total: sumBonus2(items),
                      ),
                    ),

                    // العناصر
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, _) {
                        final cartItems = cartProvider.cartItems;

                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];

                            double total = 0.0;
                            if (item.discount == 0.0) {
                              total = item.price * item.quantity;
                            } else {
                              total = item.quantity *
                                  item.price *
                                  (1 - (item.discount / 100));
                            }

                            return OrderCard(
                              ponus_one: item.ponus1,
                              color: item.color,
                              editProduct: () {
                                _editCartItem(cartProvider, item);
                              },
                              notes: item.notes,
                              product_id: item.productId,
                              id: 2,
                              ItemCart: item,
                              invoice_id: 0,
                              ponus_two: item.ponus2,
                              discount: item.discount,
                              total: total,
                              price: item.price,
                              name: item.name,
                              qty: item.quantity,
                              removeProduct: () {
                                cartProvider.removeFromCart(item);
                                setState(() {});
                              },
                              image: item.image,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 100), // مساحة لأسفل الشاشة
                  ],
                ),
              ),
            ),

            // الشريط السفلي للمجموع وزر الحفظ
            BottomContainer(
              total: calculateTotal(items),
              fatora_id: "0",
              cartItems: items,
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers: Totals =====
  double calculateTotal(List<CartItem> cartItems) {
    double total = 0;
    for (final item in cartItems) {
      final subTotal = (item.discount == 0.0)
          ? item.price * item.quantity
          : item.quantity * item.price * (1 - (item.discount / 100));
      total += subTotal;
    }
    return total;
  }

  double sumQty(List<CartItem> cartItems) {
    double total = 0;
    for (final item in cartItems) {
      total += item.quantity;
    }
    return total;
  }

  double sumBonus1(List<CartItem> cartItems) {
    double total = 0;
    for (final item in cartItems) {
      total += double.parse(item.ponus1.toString());
    }
    return total;
  }

  double sumBonus2(List<CartItem> cartItems) {
    double total = 0;
    for (final item in cartItems) {
      total += double.parse(item.ponus2.toString());
    }
    return total;
  }

  // (اختياري) مجموع المتاح بالمخزن إن أردت عرضه لاحقاً
  double calculateTotalQuantityExist(List<CartItem> cartItems) {
    double total = 0;
    for (final item in cartItems) {
      total += item.quantityexists;
    }
    return total;
  }

  // ===== Bottom Bar =====
  Widget BottomContainer(
      {var total, var fatora_id, List<CartItem>? cartItems}) {
    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "المجموع : ",
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  "₪${total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(2)}",
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Main_Color,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            Card(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddOrder(
                        total:
                            "${total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(2)}",
                        id: widget.id,
                        fatora_id: fatora_id,
                        customer_name: widget.name,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(colors: [
                      Color.fromRGBO(83, 89, 219, 1),
                      Color.fromRGBO(32, 39, 160, 0.6),
                    ]),
                  ),
                  child: Center(
                    child: Text(
                      type.toString() == "quds"
                          ? "حفظ الطلبية"
                          : "حفظ الفاتورة",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ===== Edit Item Dialog =====
  void _editCartItem(CartProvider cartProvider, CartItem item) {
    final TextEditingController nameController =
        TextEditingController(text: item.name);
    final TextEditingController colorController =
        TextEditingController(text: item.color);
    final TextEditingController priceController =
        TextEditingController(text: item.price.toString());
    final TextEditingController ponus1Controller =
        TextEditingController(text: item.ponus1.toString());
    final TextEditingController ponus2Controller =
        TextEditingController(text: item.ponus2.toString());
    final TextEditingController discontController =
        TextEditingController(text: item.discount.toString());
    final TextEditingController qtyController =
        TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل بيانات المنتج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'أسم المنتج'),
              ),
              TextField(
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: priceController,
                decoration: const InputDecoration(labelText: 'سعر المنتج'),
              ),
              Visibility(
                visible: ponus1, // متغيّرات الظهور لديك كما كانت
                child: TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  controller: ponus1Controller,
                  decoration: const InputDecoration(labelText: 'بونص 1'),
                ),
              ),
              Visibility(
                visible: ponus2,
                child: TextField(
                  controller: ponus2Controller,
                  decoration: const InputDecoration(labelText: 'بونص 2'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              Visibility(
                visible: discountSetting,
                child: TextField(
                  controller: discontController,
                  decoration: const InputDecoration(labelText: 'الخصم'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'الكمية'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('خروج'),
            ),
            TextButton(
              onPressed: () {
                if (double.parse(qtyController.text) > 0.0 &&
                    double.parse(priceController.text) == 0.0) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: const Text(
                          'الكمية أكبر من 1 و السعر يساوي صفر , لا يمكن',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        actions: <Widget>[
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 100,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Main_Color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  "حسنا",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  final price = double.parse(priceController.text);
                  final quantity = double.parse(qtyController.text);
                  final discount = double.parse(discontController.text);
                  final ponus1final = int.parse(ponus1Controller.text);

                  cartProvider.updateCartItem(
                    item.copyWith(
                      discount: discount,
                      name: nameController.text,
                      price: price,
                      quantity: quantity,
                      ponus1: ponus1final.toString(),
                    ),
                  );
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
              child: const Text('حفظ البيانات'),
            ),
          ],
        );
      },
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final double qtyTotal;
  final double bonus1Total;
  final double bonus2Total;

  const _TotalsCard({
    Key? key,
    required this.qtyTotal,
    required this.bonus1Total,
    required this.bonus2Total,
  }) : super(key: key);

  String _fmt(num v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            _StatBox(title: "مجموع الكميات", value: _fmt(qtyTotal)),
            const SizedBox(width: 8),
            _StatBox(title: "مجموع بونص 1", value: _fmt(bonus1Total)),
            const SizedBox(width: 8),
            _StatBox(title: "مجموع بونص 2", value: _fmt(bonus2Total)),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
