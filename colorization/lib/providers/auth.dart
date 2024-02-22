import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colorization/models/http_exception.dart';

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;

  bool getIsAuth(){
    // print(_token);
    return token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId{
    return _userId;
  }

  Future<void> _authentication(String email, String password, String mode) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$mode?key=Firebase API Key');
    try {
      final response = await http.post(url,
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(message: responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now()
          .add(Duration(days: int.parse(responseData['expiresIn'])));
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({'token' : _token , 'userID' : _userId , 'expiryDate':_expiryDate?.toIso8601String()});
      prefs.setString('userData', userData);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    return _authentication(email, password, 'signUp');
  }

  Future<void> signIn(String email, String password) async {
    return _authentication(email, password, 'signInWithPassword');
  }

  Future<bool> autoLogin()async{
    try{
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) {
        return false;
      } else{
        final userData = json.decode(prefs.getString('userData')as String) as Map<String , dynamic>;
        _expiryDate = DateTime.parse(userData['expiryDate']!.toString());
        if (_expiryDate!.isBefore(DateTime.now())) {
          return false;
        }
        _token = userData['token'];
        _userId = userData['userID'];
        notifyListeners();
        // print(_userId);
        return true;
      }
    }catch(error){
      return false;
    }
  }

  Future<void> logout()async{
    _token = null;
    _userId = null;
    _expiryDate = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  

}
