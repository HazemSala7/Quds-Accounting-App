import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as Path;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:async/async.dart';

class EditProductData extends StatefulWidget {
  final id,
      name,
      qty,
      invoiceID,
      discount,
      bonus1,
      bonus2,
      notes,
      product_id,
      ID;
  var price;

  EditProductData(
      {Key? key,
      this.id,
      this.invoiceID,
      this.ID,
      this.product_id,
      this.notes,
      this.bonus2,
      this.bonus1,
      this.discount,
      this.name,
      this.qty,
      required this.price})
      : super(key: key);

  @override
  State<EditProductData> createState() => _EditProductDataState();
}

class _EditProductDataState extends State<EditProductData> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  File imageFile = File('');
  final picker = ImagePicker();

  chooseImage(ImageSource source) async {
    final pickedFile = await picker.getImage(source: source);
    setState(() {
      imageFile = File(pickedFile!.path);
    });
    Navigator.pop(context);
  }

  setContrllers() {
    nameController.text = widget.name;
    priceController.text = widget.price.toString();
  }

  @override
  void initState() {
    super.initState();

    setContrllers();
  }

  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          appBar: PreferredSize(
              child: AppBarBack(
                title: "تعديل صنف",
              ),
              preferredSize: Size.fromHeight(50)),
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "أسم المنتج",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        controller: nameController,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "أسم الصنف",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "سعر المنتج",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        onChanged: (hazem) {
                          setState(() {
                            priceController.text = hazem.toString();
                          });
                        },
                        controller: priceController,
                        obscureText: false,
                        keyboardType: TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "السعر",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, top: 25),
                    child: Row(
                      children: [
                        Text(
                          "صورة المنتج",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              actions: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: InkWell(
                                    onTap: () {
                                      chooseImage(ImageSource.gallery);
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Main_Color,
                                      ),
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          "اختيار صورة من الأستوديو",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: InkWell(
                                    onTap: () {
                                      chooseImage(ImageSource.camera);
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Main_Color,
                                      ),
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          "اختيار صورة من الكاميرا",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Main_Color,
                                      ),
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          "حسنا",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color(0xffD6D3D3), width: 2)),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 20, top: 5, bottom: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 120,
                                  height: 35,
                                  child: Center(
                                    child: Text(
                                      "اضافة صورة",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white),
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                      color: Main_Color,
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ],
                            ),
                          )),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, top: 15),
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(image: FileImage(imageFile)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 25, left: 25, top: 35, bottom: 30),
                    child: MaterialButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      height: 50,
                      minWidth: double.infinity,
                      color: Color(0xff34568B),
                      textColor: Colors.white,
                      child: Text(
                        "تعديل صنف",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Center(
                                      child: CircularProgressIndicator())),
                            );
                          },
                        );
                        addProduct();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> updateProductImageLocally(
      String productId, String imagePath, int companyId) async {
    final db = await CartDatabaseHelper().database;

    await db!.update(
      'products_images',
      {
        'productImage': imagePath,
        'company_id': companyId,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> insertOrUpdateProductImage(
      String productId, String imagePath, int companyId) async {
    final db = await CartDatabaseHelper().database;

    final existing = await db!.query(
      'products_images',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (existing.isNotEmpty) {
      await updateProductImageLocally(productId, imagePath, companyId);
    } else {
      await db.insert('products_images', {
        'id': productId,
        'productImage': imagePath,
        'company_id': companyId,
      });
    }
  }

  addProduct() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    File newImage = File(imageFile.path);
    await insertOrUpdateProductImage(
        widget.id.toString(), newImage.path, int.parse(company_id.toString()));

    var headers = {
      'Content-Type': 'application/json;charset=UTF-8',
      'Charset': 'utf-8'
    };

    var request = http.MultipartRequest(
      "POST",
      Uri.parse(AppLink.editProductData),
    );

    request.fields['product_id'] = widget.product_id.toString();
    request.fields['company_id'] = company_id.toString();
    request.headers.addAll(headers);

    File finalImageFile;
    print("request.fields");
    print(request.fields);

    // ✅ Check if user selected an image
    if (imageFile.existsSync()) {
      print("1.1");
      finalImageFile = imageFile;
    } else {
      print("1.2");
      // ✅ Load asset image as byte data
      final byteData = await rootBundle.load('assets/quds_logo.jpeg');

      // ✅ Create temp file and write the bytes into it
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/default_image.jpg');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      finalImageFile = tempFile;
    }
    // ✅ Convert to multipart file
    var stream =
        http.ByteStream(DelegatingStream.typed(finalImageFile.openRead()));
    var length = await finalImageFile.length();
    var multipartFile = http.MultipartFile("images", stream, length,
        filename: Path.basename(finalImageFile.path));
    request.files.add(multipartFile);

    // ✅ Send request
    var response = await request.send();
    response.stream.transform(utf8.decoder).listen((value) {
      Map valueMap = json.decode(value);

      Navigator.of(context, rootNavigator: true).pop();

      if (valueMap['status'].toString() == 'true') {
        Fluttertoast.showToast(msg: "تم اضافة صورة لهذا المنتج بنجاح");
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: "حدث خطأ ما");
      }
    });
  }
}
