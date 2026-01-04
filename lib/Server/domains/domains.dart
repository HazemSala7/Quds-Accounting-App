class AppLink {
  static const String server = "https://yaghm.com/admin/api/";
// ================================= Auth ========================== //
  static const String signUp = "${server}register";
  static const String login = "${server}login";
  static const String loginViaDeviceID = "${server}login-via-device-id";
  static const String sentOtp = "${server}send-otp";
  static const String contactUs = "${server}contact-us";
  static const String logout = "${server}logout";

  static const String ordersWithUserID =
      "${server}get_orders_depend_on_user_id";

// ================================= general ========================== //

// ================================= Begin Customer ========================== //
  static const String customers = "${server}customers";
  static const String editCustomerName = "${server}edit_customer_name";
// ================================= End Customer ========================== //

// ================================= Begin Prices ========================== //
  static const String prices = "${server}prices";
  static const String lastPrices = "${server}last_prices";
// ================================= End Prices ========================== //

// ================================= Begin Categories ========================== //
  static const String categories = "${server}categories";
// ================================= End Categories ========================== //

// ================================= Begin Orders Quds ========================== //
  static const String addOrderQuds = "${server}add_order";
  static const String addMultipleOrders = "${server}add-multiple-order";
  static const String orders = "${server}orders";
  static const String ordersDetails = "${server}orderdetails";
  static const String allOrdersDetailsQuds = "${server}all_order_details";
  static const String getMaxFatoraNumberQuds =
      "${server}getMaxFatoraNumberQuds";
// ================================= End Orders Quds ========================== //

// ================================= Begin Catches Quds ========================== //
  static const String addCatchReceiptQuds = "${server}add_catch_receipt";
  static const String addMultipleCatchReceiptQuds =
      "${server}add-multiple-catch-receipts";
  static const String CatchesReceiptQabdQuds = "${server}quds_qabds";
  static const String AllCatchesReceiptQabdQuds = "${server}all_quds_qabds";
  static const String CatchesReceiptSarfQuds = "${server}quds_sarfs";
  static const String filterCatchesReceiptSarfQuds =
      "${server}filter_sarfs_quds";
// ================================= End Catches Quds ========================== //

// ================================= Begin Product Quds ========================== //
  static const String allProductsProducts = "${server}allProducts";
  static const String editProductData = "${server}edit_product_image_v_1";
  static const String allProductsQudsLocal =
      "${server}get_all_products_quds_local";
  static const String productsQudsImages = "${server}products_quds_images";
  static const String productsByCategoryID = "${server}products_by_category_id";
// ================================= End Product Quds ========================== //

// ================================= Begin Product Vansale ========================== //
  static const String allProductsVansaleProducts =
      "${server}all_products_vansale_products";
  static const String allProductsVansaleProductsLocal =
      "${server}all_products_vansale_products_local";
// ================================= End Product Vansale ========================== //

  static const String homeData = "${server}homepagetalabat";
  static const String storeDetails = "${server}restaurants";
  static const String addOrder = "${server}add_order_talabat";
  static const String qabds = "${server}qabds";

  // ================================= Begin Qabds Vansale ========================== //
  static const String vansaleQabds = "${server}vansale_qabds";
  static const String addMultipleCatchReceiptVansale =
      "${server}add-multiple-catch-receipts-vansale";
  static const String updateCatchReceiptPrintedValue =
      "${server}update_catch_receipt_printed_value";
  static const String vansaleFilterQabds = "${server}filter_qabds_vansale";
  static const String vansaleSarfs = "${server}vansale_sarfs";
  static const String vansaleFilterSarfs = "${server}filter_sarfs_vansale";
  // ================================= End Qabds Vansale ========================== //

  // ================================= Begin Fawater Vansale ========================== //
  static const String ordersVansale = "${server}orders_vansale";
  static const String allOrdersDetailsVansale =
      "${server}all_orderdetails_orders_vansale";
  static const String getMaxFatoraNumber = "${server}getMaxFatoraNumber";
  static const String updatePrintedValue = "${server}update_printed_value";
  static const String ordersFilterVansale = "${server}filter_orders_vansale";
  static const String addOrderVansale = "${server}add_order_vansale";
  static const String restoreOrderVansale = "${server}restore_order_vansale";
  static const String addMultipleOrderVansale =
      "${server}add-multiple-orders-vansale";
  // ================================= End Fawater Vansale ========================== //

  static const String vansaleAddCatchReceipt =
      "${server}vansale_add_catch_receipt";
  static const String addHistory = "${server}add_history";
  static const String addMultipleHistories = "${server}histories/multiple";
  static const String totalSales = "${server}total_sales";
}
