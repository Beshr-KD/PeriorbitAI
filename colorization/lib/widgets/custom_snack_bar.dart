import 'package:flutter/material.dart';
enum SnackBarType{
  success,
  error
}
void showCustomSnackBar(BuildContext context , String message , String type){
  SnackBarType snackBarType = SnackBarType.error;
  if (type.contains('success')) {
    snackBarType = SnackBarType.success;
  }
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: snackBarType == SnackBarType.success ? Colors.green : Colors.red.shade900,
        dismissDirection: DismissDirection.endToStart,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 6,
        // margin: EdgeInsets.only(
        //     bottom: MediaQuery.of(context).size.height - 100,
        //     right: 20,
        //     left: 20),
      )
  );
}
