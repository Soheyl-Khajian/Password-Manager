import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/io_client.dart';

import 'dart:io';

import 'package:argon2/argon2.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'information_list_view.dart';
import 'information.dart';

import 'package:password_manager/src/token_model.dart';

class InformationDetailsView extends StatefulWidget {
  const InformationDetailsView({super.key, required this.information});

  final Information information;
  static const routeName = '/info_item';

  @override
  State<InformationDetailsView> createState() => _InformationDetailsViewState();
}

class _InformationDetailsViewState extends State<InformationDetailsView> {
  static int _infoId = 0;

  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();

  // This line indicates that the following method overrides a method with the same name in a superclass
  @override
  // This line defines the `initState` method, which is a lifecycle method in Flutter's `State` class
  void initState() {
    // This line calls the `initState` method in the superclass, which is required when overriding this method
    super.initState();
    // This line calls the `_fetchInfo` method with the `id` of the `information` property of the `widget`
    _fetchInfo(widget.information.id);
  }

  @override
  // This line defines the `dispose` method, which is a lifecycle method in Flutter's `State` class
  void dispose() {
    // These lines call the `dispose` method on the `TextEditingController` objects to release their resources
    _userNameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    // This line calls the `dispose` method in the superclass, which is required when overriding this method
    super.dispose();
  }

  var message = '';
  var encryptionKey = '';

  // This line defines a function named `_fetchInfo` that takes an `infoId` parameter and returns a `Future` that completes with void
  Future<void> _fetchInfo(int infoId) async {
    // This line creates an `IOClient` with a bad certificate callback
    final client = IOClient(HttpClient());

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
      return Future.value([]);
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

    // Make a GET request to the server to fetch information with the specified `infoId`
    final response = await client.get(
      Uri.parse('http://10.0.2.2:8000/information/$infoId'),
      headers: {
        'Authorization': 'Token $token',
        'Encryption-Password': encryptionPassword,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Decrypt the values of the userName and password fields.
      final key = encrypt.Key.fromUtf8(encryptionPassword);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decryptedUserName = encrypter.decrypt64(data['userName'], iv: iv);
      final decryptedPassword = encrypter.decrypt64(data['password'], iv: iv);

      setState(() {
        _infoId = data['id'];
        _userNameController.text = decryptedUserName;
        _passwordController.text = decryptedPassword;
        _websiteController.text = data['website'];
      });
    }
  }

  // This line defines a function named `updateInfo` that takes an `infoId` parameter and returns a `Future` that completes with a `SnackBar`
  Future<SnackBar> updateInfo(int infoId) async {
    // This line creates an `IOClient` with a bad certificate callback
    final client = IOClient(HttpClient());

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
    final encryptedUserName = encrypter.encrypt(
      _userNameController.text,
      iv: iv,
    );
    final encryptedPassword = encrypter.encrypt(
      _passwordController.text,
      iv: iv,
    );

    // Create a map with the encrypted values of the userName and password fields and the value of the website field
    final map = {
      'userName': encryptedUserName.base64,
      'password': encryptedPassword.base64,
      'website': _websiteController.text,
    };

    // Make a PUT request to the server to update information with the specified `infoId`
    final response = await client.put(
      Uri.parse('http://10.0.2.2:8000/information/$infoId'),
      headers: <String, String>{
        'Authorization': 'Token $token',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Encryption-Password': encryptionPassword,
      },
      body: map,
    );

    // Set the message based on whether the request was successful or not
    message = (response.statusCode == 200)
        ? 'Your information is updated now!'
        : 'Sorry, Something went wrong!';

    // Return a SnackBar with the message
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
      throw Exception('Failed to send website.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Username :',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: Colors.white),
                      controller: _userNameController,
                      decoration: InputDecoration(
                        suffixIcon: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            border: Border.all(width: 1, color: Colors.white),
                          ),
                          child: IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.copy),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _userNameController.text),
                              );
                            },
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  const Text(
                    'Password :',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: Colors.white),
                      controller: _passwordController,
                      decoration: InputDecoration(
                        suffixIcon: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            border: Border.all(width: 1, color: Colors.white),
                          ),
                          child: IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.copy),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _passwordController.text),
                              );
                            },
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(100, 5, 14, 199),
                      ),
                      onPressed: () {
                        fetchRandomPassword().then((value) {
                          _passwordController.text = value;
                        });
                      },
                      child: const Text('Generate Random Password'),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Website Address :',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: Colors.white),
                      controller: _websiteController,
                      decoration: InputDecoration(
                        suffixIcon: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            border: Border.all(width: 1, color: Colors.white),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _websiteController.text),
                              );
                            },
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.maxFinite,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 122, 12, 12),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: "PTSansNarrow",
                          fontSize: 20,
                        ),
                      ),
                      child: const Text('Save'),
                      onPressed: () {
                        updateInfo(_infoId).then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(value);
                        });
                      },
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
      ),
    );
  }
}
