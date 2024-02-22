import 'dart:convert';
import 'dart:typed_data';
import 'package:colorization/providers/auth.dart';
import 'package:colorization/models/custom_image.dart';
import 'package:colorization/models/uploading.dart';
import 'package:colorization/providers/history_image.dart';
import 'package:colorization/widgets/app_drawer.dart';
import 'package:colorization/widgets/before_after.dart';
import 'package:colorization/widgets/image_by_network.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cancellation_token_http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class OverviewScreen extends StatefulWidget {
  static const routeName = "/overview";

  const OverviewScreen({super.key});

  @override
  OverviewScreenState createState() => OverviewScreenState();
}

class OverviewScreenState extends State<OverviewScreen> {
  File? selectedImage;
  Uint8List? received;
  Uint8List? temp;
  String? imageName;
  bool isUploading = false;
  late http.CancellationToken token;

  void showError() {
    if (mounted) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        dismissDirection: DismissDirection.endToStart,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        elevation: 5,
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Colors.red.shade800,
        content: const Text(
          'Something went wrong , please try again !',
        ),
      ));
    }
  }

  Future<void> onUploadImage() async {
    token = http.CancellationToken();
    if (selectedImage == null) {
      return;
    }
    bool isProcessing = await customAlert(context, 'Preprocess', 'Do you want to preprocess the image ?');
    setState(() {
      isUploading = true;
    });
    // https://colorize-aspu-pieg.onrender.com
    // https://api.deepai.org/api/colorizer
    var userInfo = Provider.of<Auth>(context,listen: false);
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('Your API endpoint'),
    );
    Map<String, String> headers = {
      "Content-type": "multipart/form-data",
      "Connection": "keep-alive",
      "Preprocess": isProcessing ? "pre" : "",
      "User-id": '${userInfo.userId}',
      "Auth-Token": '${userInfo.token}',
      "image-name":imageName!
    };
    request.headers.addAll(headers);
    imageName = '${path.basenameWithoutExtension(selectedImage!.path)}_colored';
    // bool isPNG = false;
    // String convertedImage = path.absolute(selectedImage!.path).replaceAll('.png', '');
    // File tempFile = File('$convertedImage.jpg');
    // print(path.current);
    // if(path.basename(selectedImage!.path).endsWith('.png')){
    //   final image = image_converter.decodeImage(File(path.absolute(selectedImage!.path)).readAsBytesSync())!;
    //   tempFile = await File('$convertedImage.jpg').writeAsBytes(image_converter.encodeJpg(image));
    //   // final codec = await ui.instantiateImageCodec(temp!);
    //   // final frame = await codec.getNextFrame();
    //   // final image = frame.image;
    //   // final data = await image.toByteData();
    //   // final jpg = image_converter.JpegEncoder().encode(image_converter.Image.fromBytes(width: 300, height: 300, bytes: data!.buffer));
    //   // temp = jpg;
    //   isPNG = true;
    //   // tempFile = await File('$convertedImage.jpg').writeAsBytes(temp!);
    // }
    var encodedImage = base64.encode(selectedImage!.readAsBytesSync());
    // print(encodedImage);
    // return;
    request.fields.addAll({
      'encoded-image': encodedImage
    });
    // request.files.add(
    //   http.MultipartFile(
    //     'image',
    //     selectedImage!.readAsBytes().asStream(),
    //     selectedImage!.lengthSync(),
    //     filename: selectedImage!.path.split('/').last,
    //   ),
    // );
    // isPNG ? tempFile.readAsBytes().asStream():
    // isPNG ? tempFile.lengthSync():
    await request.send(cancellationToken: token).then((res) async {
      var response = await http.Response.fromStream(res);
      print(response.body);
      // Test

      // print(jsonDecode(response.body));
      // var responseTest = await http.get(Uri.parse(jsonDecode(response.body)['output_url']));
      // var response3 = responseTest.bodyBytes;


      final decodedBytes = base64Decode(response.body);
      var response3 = decodedBytes;

      // End Test

      // var response3 = response.bodyBytes;
      if (response.statusCode == 200) {
        if (response.body == "Failed") {
          showError();
          return;
        }
        received = response3;
        setState(() {
          isUploading = false;
        });
        Get.offAndToNamed(BeforeAfterScreen.routeName,
            arguments: {
              'selectedImage': CustomImage(
                imageBytes: temp!,
              ),
              'receivedImage': CustomImage(
                imageBytes: received!,
              ),
              'imageName': '$imageName'
            });
      } else {
        showError();
        return;
      }
    }).catchError((e) {
      if (token.isCancelled) {
        token = http.CancellationToken();
        return;
      }
      showError();
    }).then((value) {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    });
  }

  Future<void> getImage(ImageSource imageSource) async {
    await ImagePicker()
        .pickImage(source: imageSource)
        .then((image) async{
          if(image == null){
            return;
          }
      selectedImage = File(image.path);
     imageName = path.basename(selectedImage!.path);
      temp = await selectedImage!.readAsBytes();
      setState((){});
      onUploadImage();
    });
  }

  Future<dynamic> customAlert(BuildContext context , String title , String subtitle) {
    return showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(subtitle),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child:const Text('No')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  // Navigator.of(context).pop(true);
                },
                child:const Text('Yes'))
          ],
        ));
  }
  @override
  void dispose() {
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await customAlert(context,'Exit','Do you want to exit?');
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 20,
          actions: isUploading
              ? <Widget>[TextButton(
                onPressed: () {
                  token.cancel();
                  setState(() {
                    isUploading = false;
                  });
                  return;
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ))]
              : null,
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text('Colorize'),
        ),
        drawer: isUploading
            ? null
            : AppDrawer(),
        body: isUploading ? const Center(child: Uploading(message: 'Uploading and processing your image ... \n                    Please be patient',))
            : Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0,horizontal: 20.0),
              child: Column(
                children: <Widget>[
                  SizedBox(
                      height: MediaQuery.of(context).size.height / 4,
                      width: MediaQuery.of(context).size.width,
                      child: GridView(
                        padding: const EdgeInsets.all(10.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 10,
                        ),
                        children: <Widget>[
                          CustomCard(onTap: ()async{
                            // print('test begin');
                            // await Provider.of<HistoryImages>(context,listen: false).fetchAndSetImages(context);
                            // return;
                            // // final picker = ImagePicker();
                            // // final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            // // final fileName = path.basename(pickedFile!.path);
                            // // final fileData = await File(pickedFile.path).readAsBytes();
                            // //
                            // // // final url = 'gs://my-store-7ce91.appspot.com/${Uri.encodeComponent(fileName)}';
                            // //
                            // // var url = 'https://firebasestorage.googleapis.com/v0/b/my-store-7ce91.appspot.com/o/users%2Fhistory%2FyypNtnTh2gMySrHdVCGAqeJm2wk2%2F$fileName?name=$fileName';
                            //
                            //
                            // // String authToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjBkMGU4NmJkNjQ3NDBjYWQyNDc1NjI4ZGEyZWM0OTZkZjUyYWRiNWQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbXktc3RvcmUtN2NlOTEiLCJhdWQiOiJteS1zdG9yZS03Y2U5MSIsImF1dGhfdGltZSI6MTY5ODMzNzc0OCwidXNlcl9pZCI6Inl5cE50blRoMmdNeVNySGRWQ0dBcWVKbTJ3azIiLCJzdWIiOiJ5eXBOdG5UaDJnTXlTckhkVkNHQXFlSm0yd2syIiwiaWF0IjoxNjk4MzM3NzQ4LCJleHAiOjE2OTgzNDEzNDgsImVtYWlsIjoidGVzdDVAdGVzdC5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsidGVzdDVAdGVzdC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9fQ.AR8IduM99qmzeceF4PPPfeUv_NcOY11aDw5AQ6p-bcgDoHawGdLdmRA4xzmFJ7Zp8WYwejw3uida2nWv0c7W2YOkGy9W5TQHtlQZUx8BfmujfgMSVglW5El1gu9Vt3UtxHo3z6VHr-No4fwBV0AIucU5VPcmbweyUcWJJXHsq_uBeE2KaPqh2YXWSdT9pza_kfDyyQmzFBLQ-Q2jxATBrC5fVnBDBXSschEBdhuQVo4MtK1GHcVo3zIavVyvjG-QJ7mtlQFuSNnMZbNvg-Vogh7KxmgUONCacIFRDskAVr1VyuUII_Xr-2u5MRT6YGEh1cjM0e6LUbysIdJQKYMsQA';
                            // // var headers = {
                            // //   // 'Content-Type': 'image/jpeg',
                            // //   'Authorization': 'Bearer $authToken',};
                            //
                            // // var imagepath = 'users/history/FyypNtnTh2gMySrHdVCGAqeJm2wk2';
                            // // var encodedimagepath = Uri.encodeQueryComponent(imagepath);
                            // //
                            // //
                            // // final url = 'https://firebasestorage.googleapis.com/v0/b/my-store-7ce91.appspot.com/o/$imagepath?alt=media';
                            // // final response = await http.get(Uri.parse(url), headers: headers);
                            // // print(response.body);
                            // // if (response.statusCode == 200) {
                            // //   final jsonData = jsonDecode(response.body);
                            // //   final files = jsonData['items'];
                            // //
                            // //   for (final file in files) {
                            // //     final fileUrl = file['url'];
                            // //     final fileName = file['name'];
                            // //     print('File name: $fileName');
                            // //     print('File URL: $fileUrl');
                            // //   }
                            // // }else{
                            // //   print(response.statusCode);
                            // // }
                            // // return;
                            // //
                            // //
                            // // // var response = await http.post(Uri.parse(url), headers: headers, body: fileData);
                            // // // var imageUrl = jsonDecode(response.body);
                            // // // print(imageUrl);
                            // // // var imagepath = 'users%2Fhistory%2FFyypNtnTh2gMySrHdVCGAqeJm2wk2%2Ftest1.png';
                            // //
                            // //
                            // //
                            //
                            // // var imagepath = 'history/FyypNtnTh2gMySrHdVCGAqeJm2wk2/';
                            //
                            // // var imagepath = 'users/history/FyypNtnTh2gMySrHdVCGAqeJm2wk2/test1.png';
                            // // var encodedimagepath = Uri.encodeQueryComponent(imagepath);
                            // // // print(encodedimagepath);
                            // // var url2 = 'https://firebasestorage.googleapis.com/v0/b/my-store-7ce91.appspot.com/o/$encodedimagepath?alt=media';
                            // //
                            // // // // To get all files from a specific folder:
                            // // var url2 = 'https://firebasestorage.googleapis.com/v0/b/my-store-7ce91.appspot.com/o?prefix=users/history/FyypNtnTh2gMySrHdVCGAqeJm2wk2/';
                            // // var response2 = await http.get(Uri.parse(url2),headers: headers);
                            // // // //
                            // // // //
                            // // // //
                            // // print(response2.body);
                            // // print(json.decode(response2.body));
                            // // return;
                            // // // final bytes = response2.bodyBytes;
                            // // // final Uint8List decodedData = Utf8Encoder().convert(response2.body);
                            // // // final base64String = base64Encode(bytes);
                            // //
                            // //
                            // //
                            // // final decodedBytes = base64Decode(response2.body);
                            // // // var bytes = decodedBytes;
                            // //
                            // //
                            // //
                            // // setState(() {
                            // //   imageTest = decodedBytes;
                            // // });
                            // // return;
                            //
                            //
                            //
                            // https://my-store-7ce91-default-rtdb.firebaseio.com/users/history/yypNtnTh2gMySrHdVCGAqeJm2wk2/-NhY5B2ZklvOe8fvnyLg.json
                            // // final url = Uri.parse('?auth=eyJhbGciOiJSUzI1NiIsImtpZCI6IjBkMGU4NmJkNjQ3NDBjYWQyNDc1NjI4ZGEyZWM0OTZkZjUyYWRiNWQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbXktc3RvcmUtN2NlOTEiLCJhdWQiOiJteS1zdG9yZS03Y2U5MSIsImF1dGhfdGltZSI6MTY5ODIzMjE3NiwidXNlcl9pZCI6Inl5cE50blRoMmdNeVNySGRWQ0dBcWVKbTJ3azIiLCJzdWIiOiJ5eXBOdG5UaDJnTXlTckhkVkNHQXFlSm0yd2syIiwiaWF0IjoxNjk4MjMyMTc2LCJleHAiOjE2OTgyMzU3NzYsImVtYWlsIjoidGVzdDVAdGVzdC5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsidGVzdDVAdGVzdC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9fQ.SaMaaBdB16D1J6iF_7M3c0ubG9tYwmxcSlafggrSSzt5z9w9M38niwVdQ9YGeOY1KP_NTxENU9kWVa1abyyLD6xrBj7aWgJ3-z3hLYLvm2CWl9HrlBWgRDj3oRLgMtx5y6Ax0RRzKUE_y-4otw6hU-HZQeqHgnyJQq4323wpGqtwp2kbtMiq517UH_z16IKWjDR329PWz3k_4wQruyFdmhVxZa4YwaKjK4lscZBsibMM9tDsYYAb9odxFWP0iuydR2tD2L7KFdvLxhPpGmbLqYadA8kXkvvSsoYl8HSaxLlj52DvJgYwIeSTofjRIlC2VCdk205lLcdtxfpEHwov4g');
                            // // var request = await http.get(url);
                            // // final Uint8List decodedData = Utf8Encoder().convert(request.body);
                            // // print(request.body);
                            // // var utf8String = Latin1Encoder().convert(request.body);
                            // // print(utf8String);
                            // // setState(() {
                            // //   imageTest = utf8String;
                            // // });
                            // // print(utf8String);
                            // // final Uint8List testing = Utf8Encoder().convert(decodedData);
                            // // print('$testing  : Testing Var Value ');
                            // // setState(() {
                            // //   // imageTest = decodedData;
                            // // });
                            // // print('Decoded Data : $decodedData');
                            // // final extractedData = json.decode(request.body) as Map<String, dynamic>;
                            // // print('Request Body : ${request.body}');
                            // // var test = Utf8Encoder().convert(extractedData['-NhY5B2ZklvOe8fvnyLg']);
                            // // print('Test Value : $test');
                            // // setState(() {
                            // //   // imageTest = utf8.decode(test);
                            // // });
                            // print('Data get done');
                            // // print(Utf8Encoder().convert(extractedData['-NhY5B2ZklvOe8fvnyLg']));
                            // // print(json.decode(extractedData['-NhY5B2ZklvOe8fvnyLg']));
                            // // setState(() {
                            // //   // imageTest = Utf8Decoder().convert(extractedData['-NhY5B2ZklvOe8fvnyLg']);
                            // //   // print(Utf8Decoder().convert(extractedData['-NhY5B2ZklvOe8fvnyLg']));
                            // // });
                            // print('test end');
                            getImage(ImageSource.gallery);
                            },title: 'Gallery',
                          placeHolderPath: 'assets/images/ph_gallery.png',imgPath: 'assets/images/gallery.png',
                          ),
                          CustomCard(onTap: (){getImage(ImageSource.camera);},title: 'Take photo',
                            placeHolderPath: 'assets/images/ph_camera.jpg',imgPath: 'assets/images/camera.jpg',
                          ),
                        ],
                      ),
                    ),
                  Center(child:CustomCard(onTap: (){Get.offNamedUntil(ImageUploadByNetwork.routeName,(_)=>false);},title: 'Colorize image by URL',
                    placeHolderPath: 'assets/images/ph_www.jpg',imgPath: 'assets/images/www.jpg',
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget{
  final Function onTap;
  final Icon icon;
  const CustomTextButton({super.key, required this.onTap , required this.icon});
  @override
  Widget build(BuildContext context){
    return TextButton(
          onPressed: (){
            onTap();
          },
          style: ButtonStyle(
            shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
            splashFactory: NoSplash.splashFactory,
            padding: MaterialStateProperty.all(EdgeInsets.zero)
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: icon,
          ),
        );
  }
}

class CustomCard extends StatelessWidget {
  final Function onTap;
  final String title;
  final String placeHolderPath;
  final String imgPath;
  const CustomCard({Key? key, required this.onTap, required this.title, required this.placeHolderPath, required this.imgPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22.0),
      radius: 0.0,
      splashFactory: InkSplash.splashFactory,
      onTap: (){
        onTap();
      },
      child: SizedBox(
        height: 200,
        width: MediaQuery.of(context).size.width / 1.2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GridTile(
            footer: GridTileBar(
              backgroundColor: Colors.black87,
              title: Text(
                title,
                textAlign: TextAlign.center,
              ),
            ),
            child: FadeInImage(
              fadeOutDuration: const Duration(seconds: 2),
              fadeInDuration: const Duration(seconds: 2),
              fit: BoxFit.cover,
              placeholder: AssetImage(placeHolderPath),
              image: Image.asset(imgPath).image,
            ),
          ),
        ),
      ),
    );
  }
}
