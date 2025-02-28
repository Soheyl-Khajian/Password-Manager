import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';

import 'dart:io';

import 'package:password_manager/src/information_feature/information_list_view.dart';
import 'package:password_manager/src/accounts_feature/accounts_create_view.dart';
import 'package:password_manager/src/token_model.dart';

class LoginForm extends StatefulWidget {
  final void Function(String username, String password) onLogin;
  final bool isFirstTime;

  const LoginForm({Key? key, required this.onLogin, required this.isFirstTime})
    : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  var map = <String, dynamic>{};
  var userName = '';
  var password = '';
  var message = '';
  var token = '';
  bool isToken = false;

  var borderColor = const Color.fromARGB(255, 44, 82, 119);
  var submitBtnColor = const Color.fromARGB(255, 9, 55, 92);

  bool isPasswordVisible = false;

  Future<SnackBar> postFormLogin() async {
    final client = IOClient(HttpClient());
    final tokenModel = Provider.of<TokenModel>(context, listen: false);

    final tokenResponse = await client.post(
      Uri.parse('http://10.0.2.2:8000/api-token-auth/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _userNameController.text,
        'password': _passwordController.text,
      }),
    );

    if (tokenResponse.statusCode == 200) {
      token = jsonDecode(tokenResponse.body)['token'];
      tokenModel.token = token;
      tokenModel.userName = _userNameController.text;
      tokenModel.password = _passwordController.text;

      isToken = true;
      message = 'You are now logged in as ${_userNameController.text}!';
    } else {
      isToken = false;
      message = 'Nope, No luck...';
      //print('Error obtaining token: ${tokenResponse.body}');
    }

    return SnackBar(content: Text(message));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: double.maxFinite,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              //Colors.black87,
              //Color.fromARGB(180, 62, 84, 109),
              //Color.fromARGB(255, 62, 84, 109),
              //Color.fromARGB(120, 47, 65, 85),
              theme.colorScheme.primary, theme.colorScheme.secondary,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 110),
                SizedBox(
                  //height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        style: TextStyle(
                          color: Color.fromARGB(199, 38, 58, 92),
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'PTSansNarrow',
                        ),
                        'Accounts',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: IconButton(
                          iconSize: 45,
                          icon: const Icon(Icons.person_add_alt_1),
                          color: const Color.fromARGB(255, 148, 161, 184),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateAccountsPage(
                                  isFirstTime: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          style: TextStyle(color: Colors.white70),
                          'Your username or Email address:',
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(bottom: 50),
                        child: TextFormField(
                          controller: _userNameController,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email address or username is required!';
                            } else {
                              userName = value;
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(top: 20),
                        child: const Text(
                          style: TextStyle(color: Colors.white70),
                          'Your password',
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextFormField(
                              style: const TextStyle(color: Colors.white),
                              controller: _passwordController,
                              obscureText: isPasswordVisible == false
                                  ? true
                                  : false,
                              obscuringCharacter: '*',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required!';
                                }
                                _passwordController.text = value;

                                return null;
                              },
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isPasswordVisible == false) {
                                      isPasswordVisible = true;
                                    } else {
                                      isPasswordVisible = false;
                                    }
                                  });
                                },
                                child: const Icon(Icons.remove_red_eye),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.maxFinite,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: submitBtnColor,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: "PTSansNarrow",
                              fontSize: 20,
                            ),
                          ),
                          child: const Text('Login'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              postFormLogin().then((value) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(value);
                                if (isToken == true) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const InformationListView(),
                                    ),
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 10,
                  ),
                  height: 50,
                  width: double.maxFinite,
                  child: OutlinedButton(
                    style: ElevatedButton.styleFrom(),
                    onPressed: () {
                      if (widget.isFirstTime == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login first')),
                        );
                      }
                      if (widget.isFirstTime == false) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InformationListView(),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      style: TextStyle(color: Colors.white),
                      'Home Page',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
