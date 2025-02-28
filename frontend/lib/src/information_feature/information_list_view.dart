import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:http/io_client.dart';

import 'dart:io';

import 'package:argon2/argon2.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:password_manager/src/settings/settings_view.dart';
import 'package:password_manager/src/information_feature/information.dart';
import 'package:password_manager/src/information_feature/information_details_view.dart';
import 'package:password_manager/src/information_feature/information_create_view.dart';
import 'package:password_manager/src/accounts_feature/accounts_login_view.dart';
import 'package:password_manager/src/token_model.dart';

class InformationListView extends StatefulWidget {
  const InformationListView({super.key});

  static const routeName = '/';

  @override
  State<InformationListView> createState() => _InformationListViewState();
}

class _InformationListViewState extends State<InformationListView> {
  // Declare variables to hold the future information, message, and encryption key
  late Future<List<Information>> futureInfo;
  var message = '';
  var encryptionKey = '';

  // Define a function to fetch information
  Future<List<Information>> fetchInfos() async {
    // Create an IOClient with a bad certificate callback
    final client = IOClient(HttpClient());

    // Get the token and password from the token model
    final tokenModel = Provider.of<TokenModel>(context, listen: false);
    final token = tokenModel.token;
    final password = tokenModel.password;

    // Print the password and token for debugging purposes
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
    print("encryption key: $encryptionKey");

    // Use a fixed-length substring of the encryption key as the encryption password
    var encryptionPassword = encryptionKey.substring(0, 32);

    // Print the encryption password for debugging purposes
    print("encryption Password: $encryptionPassword");

    // Make a GET request to the server to fetch information
    final response = await client.get(
      Uri.parse('http://10.0.2.2:8000/information/'),
      headers: <String, String>{
        'Authorization': 'Token $token',
        'Encryption-Password': encryptionPassword,
      },
    );

    // A function that converts a response body into a List<Information>.
    List<Information> parseInfos(String responseBody) {
      final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

      return parsed
          .map<Information>((json) => Information.fromJson(json))
          .toList();
    }

    // Decrypt the information on the client.
    final decryptedResponse = await compute(parseInfos, response.body);

    // Decrypt the values of the userName, password, and website fields.
    final key = encrypt.Key.fromUtf8(encryptionPassword);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    for (var information in decryptedResponse) {
      information.userName = encrypter.decrypt64(information.userName, iv: iv);
      information.password = encrypter.decrypt64(information.password, iv: iv);
      // The website field is not encrypted.
    }

    return decryptedResponse;
  }

  // Define a function to delete an account
  Future<SnackBar> deleteAccount(String? accountUsername) async {
    try {
      // Create an IOClient with a bad certificate callback
      final client = IOClient(HttpClient());

      // Get the token from the token model
      final tokenModel = Provider.of<TokenModel>(context, listen: false);
      final token = tokenModel.token;

      // Make a DELETE request to the server to delete the user account
      final response = await client.delete(
        Uri.parse('http://10.0.2.2:8000/delete-user/$accountUsername/'),
        headers: {'Authorization': 'Token $token'},
      );

      // Check the response status code
      if (response.statusCode == 204) {
        // If the status code is 204, the account was successfully deleted
        message = 'Your account was successfully removed!';
        return SnackBar(content: Text(message));
      } else {
        // If the status code is not 204, something went wrong
        message = 'Sorry, Something went wrong...';
        return SnackBar(content: Text(message));
      }
    } catch (e) {
      // If an exception is thrown, something went wrong
      return const SnackBar(content: Text('Something went wrong...'));
    }
  }

  @override
  void initState() {
    super.initState();
    futureInfo = fetchInfos();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokenModel = Provider.of<TokenModel>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: Text(
            '${tokenModel.userName}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: "PTSansNarrow",
            ),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 35),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            InkWell(
              onTap: () => setState(() {
                futureInfo = fetchInfos();
              }),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Icon(Icons.refresh, color: Colors.white, size: 35),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 12, 55, 90),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: Text(
                          '${tokenModel.userName?[0].toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.supervised_user_circle_outlined,
                      ),
                      title: const Text(
                        'Manage Users',
                        style: TextStyle(fontSize: 15),
                      ),
                      onTap: () {
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
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text(
                        'How to use',
                        style: TextStyle(fontSize: 15),
                      ),
                      onTap: () {
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
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text(
                        'Settings',
                        style: TextStyle(fontSize: 15),
                      ),
                      onTap: () {
                        Navigator.restorablePushNamed(
                          context,
                          SettingsView.routeName,
                        );
                      },
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Warning'),
                        content: const Text(
                          'Are you sure you want to delete your account? it will be removed forever and all your information will be lost.',
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              deleteAccount(tokenModel.userName).then((value) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(value);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginForm(
                                      isFirstTime: true,
                                      onLogin: (username, password) {},
                                    ),
                                  ),
                                );
                              });
                            },
                            child: const Text('DELETE'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InformationListView(),
                                ),
                              );
                            },
                            child: const Text('No'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Delete My Account'),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 10, right: 10, left: 10),
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Information>>(
                    future: futureInfo,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('An error has occurred!'),
                        );
                      } else if (snapshot.hasData) {
                        return InfosList(infos: snapshot.data!);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: FloatingActionButton(
            //ExampleExpandableFab(),
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CreateInfoPage()),
              );
            },
          ),
        ),
      ),
    );
  }
}

class InfosList extends StatefulWidget {
  const InfosList({super.key, required this.infos});

  final List<Information> infos;

  @override
  State<InfosList> createState() => _InfosListState();
}

class _InfosListState extends State<InfosList> {
  //final _listTileBgColor = const Color.fromARGB(175, 59, 82, 108);

  // This line declares a variable named `message` and initializes it to an empty string
  var message = '';

  // This line defines a function named `deleteInfo` that takes an `infoId` parameter and returns a `Future` that completes with a `SnackBar`
  Future<SnackBar> deleteInfo(int infoId) async {
    // This line creates an `IOClient` with a bad certificate callback
    final client = IOClient(HttpClient());

    // This line gets the token from the token model
    final tokenModel = Provider.of<TokenModel>(context, listen: false);
    final token = tokenModel.token;

    // This line makes a DELETE request to the server to delete the information with the specified `infoId`
    final response = await client.delete(
      Uri.parse('http://10.0.2.2:8000/information/$infoId'),
      headers: {'Authorization': 'Token $token'},
    );

    // This line checks if the response status code is 204
    if (response.statusCode == 204) {
      // If the status code is 204, the information was successfully deleted
      message = 'Your item was successfully removed!';
      var snackBar = SnackBar(content: Text(message));
      return snackBar;
    } else {
      // If the status code is not 204, something went wrong
      message = 'Sorry, Something went wrong...';
      var snackBar = SnackBar(content: Text(message));
      return snackBar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      restorationId: 'InformationListView',
      itemCount: widget.infos.length,
      itemBuilder: (BuildContext context, int index) {
        final item = widget.infos[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InformationDetailsView(information: item),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
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
            height: 105,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  flex: 90,
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(20),
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          color: Color.fromARGB(255, 146, 146, 146),
                          size: 38,
                          Icons.person,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 250,
                            child: Text(
                              item.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              width: 250,
                              child: Text(
                                item.website,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Warning'),
                                content: const Text(
                                  'Are you sure you want to delete this item?',
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      deleteInfo(item.id).then((value) {
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
                                    },
                                    child: const Text('DELETE'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const InformationListView(),
                                        ),
                                      );
                                    },
                                    child: const Text('No'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
