import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;

  changePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? access_token = prefs.getString('access_token');
    print("access_token");
    print(access_token);
    String _authToken = "Bearer $access_token";
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print("_authToken");
      print(_authToken);
      final response = await http.post(
        Uri.parse('https://yaghm.com/admin/api/change-password'),
        headers: {
          'Authorization': _authToken,
        },
        body: {
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
          'new_password_confirmation': _confirmNewPasswordController.text,
        },
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'فشلت عملية تغيير كلمة المررو , الرجاء المحاولة فيما بعد')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Color.fromRGBO(83, 89, 219, 1),
            Color.fromRGBO(32, 39, 160, 0.6),
          ])),
        ),
        title: Text(
          'تغيير كلمة المرور',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
          iconSize: 25,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                label: 'كلمة المرور الحالية',
                controller: _currentPasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء ادخال كلمة المرور الحالية';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildPasswordField(
                label: 'كلمة المرور الجديدة',
                controller: _newPasswordController,
                validator: (value) {},
              ),
              SizedBox(height: 16),
              _buildPasswordField(
                label: 'تأكيد كلمة المرور الجديدة',
                controller: _confirmNewPasswordController,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'الرجاء التأكد من كلمة المرور';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Center(
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : ButtonWidget(
                          name: "تغيير كلمة المرور",
                          height: 50,
                          width: double.infinity,
                          BorderColor: Main_Color,
                          FontSize: 18,
                          OnClickFunction: () {
                            changePassword();
                          },
                          BorderRaduis: 10,
                          ButtonColor: Main_Color,
                          NameColor: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }
}
