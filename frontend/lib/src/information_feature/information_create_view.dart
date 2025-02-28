import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:argon2/argon2.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:provider/provider.dart';
import 'package:http/io_client.dart';

import 'dart:io';

import 'package:password_manager/src/token_model.dart';

import 'information_list_view.dart';

class CreateInfoPage extends StatefulWidget {
  const CreateInfoPage({super.key});

  @override
  State<CreateInfoPage> createState() => _CreateInfoPageState();
}

class _CreateInfoPageState extends State<CreateInfoPage> {
  // This line defines a global key for the form state
  final _formKey = GlobalKey<FormState>();

  // This line defines a text editing controller for the password field
  final passwordController = TextEditingController();

  // This line indicates that the following method overrides a method with the same name in a superclass
  @override
  // This line defines the `dispose` method, which is a lifecycle method in Flutter's `State` class
  void dispose() {
    // This line calls the `dispose` method on the password controller to release its resources
    passwordController.dispose();
    // This line calls the `dispose` method in the superclass, which is required when overriding this method
    super.dispose();
  }

  // These lines define several variables to hold various data
  var map = <String, dynamic>{};
  var userName = '';
  var password = '';
  var websiteName = '';
  var message = '';

  // These lines define constant color values for the border and submit button
  var borderColor = const Color.fromARGB(255, 44, 82, 119);
  var submitBtnColor = const Color.fromARGB(255, 9, 55, 92);

  // These lines define boolean flags to track whether a random password has been fetched and whether the password is visible
  bool isFetchedRandomPassword = false;
  bool isPasswordVisible = false;

  // This line defines a future that completes with a random password
  Future<String>? futureRandomPassword;
  var encryptionKey = '';

  // This line defines a function named `postForm` that returns a `Future` that completes with a `SnackBar`
  Future<SnackBar> postForm() async {
    // These lines get the token and password from the token model
    final tokenModel = Provider.of<TokenModel>(context, listen: false);
    final token = tokenModel.token;
    final password = tokenModel.password;

    // These lines print the password and token for debugging purposes
    print("password: $password");
    print("token: $token");

    // Check if the token or userName is null
    if (token == null || password == null) {
      // Handle the error
      // For example, show an error message to the user
      message = 'Error: token or userName or password is null';
      return Future.value(
        const SnackBar(
          content: Text('Error: token or userName or password is null'),
        ),
      );
    }

    // Generate the encryption key using Argon2
    var salt = Uint8List.fromList(utf8.encode(token));
    var parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_i,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_10,
      iterations: 2,
      memoryPowerOf2: 16,
    );
    var argon2 = Argon2BytesGenerator();
    argon2.init(parameters);
    var passwordBytes = Uint8List.fromList(utf8.encode(password));
    var result = Uint8List(32);
    argon2.generateBytes(passwordBytes, result, 0, result.length);

    // Convert the encryption key to a string
    encryptionKey = base64.encode(result);

    // Print the encryption key for debugging purposes
    print(encryptionKey);

    // Use a fixed-length substring of the encryption key as the encryption password
    var encryptionPassword = encryptionKey.substring(0, 32);

    // Create an encrypter with the specified key and IV
    final key = encrypt.Key.fromUtf8(encryptionPassword);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Encrypt the values of the userName and password fields
    final encryptedUserName = encrypter.encrypt(userName, iv: iv);
    final encryptedPassword = encrypter.encrypt(
      passwordController.text,
      iv: iv,
    );

    // Create a map with the encrypted values of the userName and password fields and the value of the website field
    final plainText = jsonEncode({
      'userName': encryptedUserName.base64,
      'password': encryptedPassword.base64,
      'website': websiteName,
    });

    // Send a GET request to the server to obtain the CSRF token
    final client = IOClient(HttpClient());
    final response = await client.get(
      Uri.parse('http://10.0.2.2:8000/information/'),
    );
    final setCookieHeader = response.headers['set-cookie'];

    var csrfToken = '';
    if (setCookieHeader != null) {
      csrfToken = setCookieHeader
          .split(';')
          .firstWhere((element) => element.startsWith('csrftoken='))
          .substring('csrftoken='.length);
    }

    // Make a POST request to the server to create new information with the specified `infoId`
    final postResponse = await client.post(
      Uri.parse('http://10.0.2.2:8000/information/'),
      headers: <String, String>{
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Encryption-Password': encryptionPassword,
        'X-CSRFToken': csrfToken,
      },
      body: plainText,
    );

    // Set the message based on whether the request was successful or not
    if (postResponse.statusCode == 201) {
      return const SnackBar(
        content: Text('Your new information is saved now!'),
      );
    } else {
      return const SnackBar(content: Text('Sorry, Something went wrong!'));
    }
  }

  Future<dynamic> fetchRandomPassword() async {
    final client = IOClient(HttpClient());
    final response = await client.get(
      Uri.parse('http://10.0.2.2:8000/information/randomPassword/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send to website.');
    }
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
                  'Information',
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
                          'Please type in the email address or username which you want to store:',
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(bottom: 50),
                        child: TextFormField(
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
                          'Please type in the password which you want to store:',
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextFormField(
                              style: const TextStyle(color: Colors.white),
                              controller: passwordController,
                              obscureText: isPasswordVisible == false
                                  ? true
                                  : false,
                              obscuringCharacter: '*',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required!';
                                } else if (isFetchedRandomPassword == false) {
                                  passwordController.text = value;
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
                              passwordController.text = value;
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
                          'Please type in the website\'s login page address which you want to store:',
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(bottom: 50),
                        child: TextFormField(
                          keyboardType: TextInputType.url,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Website address is required!';
                            } else {
                              websiteName = value;
                            }
                            return null;
                          },
                        ),
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
                          child: const Text('Submit'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              postForm().then((value) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(value);
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InformationListView(),
                        ),
                      );
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
