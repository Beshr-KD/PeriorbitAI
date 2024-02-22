import 'dart:convert';
import 'dart:typed_data';
import 'package:colorization/providers/auth.dart';
import 'package:image/image.dart' as img_lib;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HistoryImageItem with ChangeNotifier{
  // final String id;
  final String imageName;
  // final Uint8List originalBytes;
  final Uint8List coloredBytes;
  bool isSaved;
  // final DateTime sendDate;

  HistoryImageItem({
    // required this.id,
    required this.imageName,
    // required this.originalBytes,
    required this.coloredBytes,
    this.isSaved = false
    // required this.sendDate
  });

  String get imgName {
    return imageName;
  }

  Future<bool> saveImage() async {

    bool result = false;
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
      if(await Permission.storage.isDenied){
        result = false;
      }
    }
    // if(isSaved){
      try {
        var temp = await ImageGallerySaver.saveImage(coloredBytes,name: imageName,quality: 100 , isReturnImagePathOfIOS: true);
        isSaved = true;
        result = true;
        // imagePath = path.absolute(temp['filePath']).replaceAll('%20', ' ').replaceFirst('/file://', '');
      } catch (e) {
        notifyListeners();
        result = false;
      }
      // result = true;
    // }else{
    //   result = false;
    // }
    return result;
  }


}

class HistoryImages with ChangeNotifier {
  List<HistoryImageItem>? historyItems = [];
  String? authToken;
  String? userId;
  HistoryImages({this.authToken,
    this.userId , this.historyItems});

  List<HistoryImageItem> get items {
    return [...?historyItems];
  }



  Future<Uint8List> decryptImage(String imageUrl) async {
    var headers = {
      // 'Content-Type': 'image/jpeg',
      'Authorization': 'Bearer $authToken',};
    var encodedImagePath = Uri.encodeQueryComponent(imageUrl);
    final url = 'https://firebasestorage.googleapis.com/v0/b/Bucket URL/o/$encodedImagePath?alt=media';
    final response = await http.get(Uri.parse(url), headers: headers);
    // print('Response file : ${response.body}');
    final decodedBytes = base64Decode(response.body);
    return decodedBytes;
  }

  Future<void> fetchAndSetImages(BuildContext context) async{
    // [bool filterByUser = false]
    // final filterString = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var auth = Provider.of<Auth>(context,listen: false);
    String? authToken = auth.token;
    String? userId = auth.userId;
    var url = 'https://firebasestorage.googleapis.com/v0/b/Bucket URL/o?prefix=users/history/$userId/';
    var headers = {'Authorization': 'Bearer $authToken',};
    var response = await http.get(Uri.parse(url),headers: headers);
    // print('Response Body :${response.body}');
    var extractedData = jsonDecode(response.body)['items'] as List<dynamic>;
    // print(extractedData);
    try{
      final List<HistoryImageItem> loadedImages = [];
      for(int i = 0; i < extractedData.length; i++){
        // print('ExtractedData Lenght : ${extractedData.length}');
        var imagePath = extractedData[i]['name'].toString();
        // print('Image Path :$imagePath');
        Uint8List decodedImage = await decryptImage(imagePath);
        img_lib.Image? image = img_lib.decodeImage(decodedImage);
        image = img_lib.grayscale(image!);
        Uint8List originalBytes = img_lib.encodeJpg(image);
        loadedImages.add(
          HistoryImageItem(imageName: basename(imagePath), coloredBytes: decodedImage,)
        );
      }
      historyItems = loadedImages;
      notifyListeners();
    }catch(error){
      print(error);
      rethrow;
    }
  }

  Future<void> logout() async {
    historyItems = [];
  }


}
