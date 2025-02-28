import 'package:flutter/foundation.dart';

class TokenModel extends ChangeNotifier {
  String? _token;
  String? _userName;
  String? _password;

  String? get token => _token;
  String? get userName => _userName;
  String? get password => _password;

  set token(String? value) {
    _token = value;
    notifyListeners();
  }

  set userName(String? value) {
    _userName = value;
    notifyListeners();
  }

  set password(String? value) {
    _password = value;
    notifyListeners();
  }
}
