import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';

import 'dart:io';

import 'package:password_manager/src/accounts_feature/accounts_login_view.dart';
import 'package:provider/provider.dart';
import 'package:password_manager/src/token_model.dart';

import 'package:password_manager/src/information_feature/information_list_view.dart';

class CreateAccountsPage extends StatefulWidget {
  final bool isFirstTime;

  const CreateAccountsPage({Key? key, required this.isFirstTime})
    : super(key: key);

  @override
  State<CreateAccountsPage> createState() => _CreateAccountsPageState();
}

class _CreateAccountsPageState extends State<CreateAccountsPage> {
  final _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailAddressController = TextEditingController();

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _emailAddressController.dispose();
    super.dispose();
  }

  var map = <String, dynamic>{};
  var userName = '';
  var password = '';
  var websiteName = '';
  var message = '';
  var token = '';
  bool isToken = false;

  var borderColor = const Color.fromARGB(255, 44, 82, 119);
  var submitBtnColor = const Color.fromARGB(255, 9, 55, 92);

  bool isFetchedRandomPassword = false;
  bool isPasswordVisible = false;
  bool _isAutoLoginChecked = false;

  Future<String>? futureRandomPassword;

  Future<SnackBar> postFormAcc() async {
    final client = IOClient(HttpClient());
    final tokenModel = Provider.of<TokenModel>(context, listen: false);
    final token = tokenModel.token;

    final map = {
      'username': _userNameController.text,
      'password': _passwordController.text,
      'email': _emailAddressController.text,
    };

    final response = await client.post(
      Uri.parse('http://10.0.2.2:8000/create-user/'),
      headers: <String, String>{
        'Authorization': 'Token $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: map,
    );

    if (response.statusCode == 201) {
      return const SnackBar(content: Text('Your new Account is created!'));
    } else {
      return const SnackBar(content: Text('Sorry, Something went wrong!'));
    }
  }

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

  Future<dynamic> fetchRandomPassword() async {
    final client = IOClient(HttpClient());
    final response = await client.get(
      Uri.parse('http://10.0.2.2:8000/information/randomPassword/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get a random password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        //shadowColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginForm(
                  onLogin: (username, password) {},
                  isFirstTime: false,
                ),
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
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
        margin: const EdgeInsets.only(top: 25),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 90),
                const Text(
                  style: TextStyle(
                    color: Color.fromARGB(199, 38, 58, 92),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'PTSansNarrow',
                  ),
                  'Accounts',
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(top: 20),
                        child: const Text(
                          style: TextStyle(color: Colors.white70),
                          'Username:',
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
                              return 'username is required';
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
                          'Password:',
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
                                  return 'Password is required';
                                } else if (isFetchedRandomPassword == false) {
                                  _passwordController.text = value;
                                }

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
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              182,
                              10,
                              1,
                            ),
                          ),
                          onPressed: () {
                            fetchRandomPassword().then((value) {
                              isFetchedRandomPassword = true;
                              _passwordController.text = value;
                            });
                          },
                          child: const Text('Generate Random Password'),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(top: 20),
                        child: const Text(
                          style: TextStyle(color: Colors.white70),
                          'Email Address:',
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(bottom: 50),
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailAddressController,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email address is required';
                            } else {
                              websiteName = value;
                            }
                            return null;
                          },
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          'Automatically login and bring me to the main page',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _isAutoLoginChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isAutoLoginChecked = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
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
                          child: const Text('Create New Account'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (_isAutoLoginChecked == false) {
                                postFormAcc().then((value) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(value);
                                });
                              }
                              if (_isAutoLoginChecked == true) {
                                postFormAcc().then((value) {
                                  postFormLogin().then((value) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(value);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const InformationListView(),
                                      ),
                                    );
                                  });
                                });
                              }
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
                      final tokenModel = Provider.of<TokenModel>(
                        context,
                        listen: false,
                      );
                      if (tokenModel.userName == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login first')),
                        );
                      } else {
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
