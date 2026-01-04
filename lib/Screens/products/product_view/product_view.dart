import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/components/product-widget-quds/product-widget-quds.dart';

class ProductView extends StatelessWidget {
  String image;
  ProductView({
    Key? key,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("image");
    print(image);
    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                  child: isOnline
                      ? Image.network(
                          image,
                          fit: BoxFit.fill,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                backgroundColor: Main_Color,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset("assets/quds_logo.jpeg",
                                  fit: BoxFit.cover),
                        )
                      : ProductCardQuds.buildImage(image)),
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey),
                    child: Center(
                        child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    )),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
