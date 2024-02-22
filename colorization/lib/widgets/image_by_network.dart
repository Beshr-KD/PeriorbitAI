import 'dart:convert';
import 'dart:typed_data';
import 'package:colorization/models/uploading.dart';
import 'package:colorization/widgets/overview.dart';
import 'package:flutter/material.dart';
import 'package:cancellation_token_http/http.dart' as http;
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import '../models/custom_button.dart';
import '../models/custom_image.dart';
import '../providers/auth.dart';
import 'before_after.dart';
class ImageUploadByNetwork extends StatefulWidget {
  static const routeName = "/image-by-network";
  const ImageUploadByNetwork({super.key});

  @override
  ImageUploadByNetworkState createState() => ImageUploadByNetworkState();
}
class ImageUploadByNetworkState extends State<ImageUploadByNetwork> {
  bool _isProcessing = false;
  bool _isLoading = true;
  final _form = GlobalKey<FormState>();
  final TextEditingController imageUrlController = TextEditingController();
  Uint8List? imageBytes;
  late http.CancellationToken token;

  Future<void> getImageFromUrl(String imageUrl) async {
    if (imageUrlController.text.isEmpty) {
      return;
    }
    token = http.CancellationToken();
    setState(() {
      _isLoading = true;
      _isProcessing = true;
    });
    try {
      var response = await http.get(Uri.parse(imageUrl), cancellationToken: token);
      if (response.statusCode == 200) {
        setState(() {
          imageBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        // print('Failed to load image: ${response.statusCode}');
        return;
      }
    }catch(e){
      if (token.isCancelled) {
        token = http.CancellationToken();
        return;
      }
      return;
    }finally{
      setState(() {
        _isProcessing = false;
      });
    }
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
  Future<void> uploadImage(BuildContext context) async {
    if(imageBytes == null){
      return;
    }
    bool isPreprocessing = await customAlert(context, 'Preprocess', 'Do you want to preprocess the image ?');
    setState(() {
      _isProcessing = true;
    });
    var url = Uri.parse('Your API endpoint');
    String imageName = Uri.parse(imageUrlController.text).pathSegments.last;
    var userInfo = Provider.of<Auth>(context,listen: false);
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('Your API endpoint'),
    );
    Map<String, String> headers = {
      "Content-type": "multipart/form-data",
      "Connection": "keep-alive",
      "Preprocess": isPreprocessing ? "pre" : "",
      "User-id": '${userInfo.userId}',
      "Auth-Token": '${userInfo.token}',
      "image-name":imageName
    };
    request.headers.addAll(headers);
    // imageName = '${basenameWithoutExtension(selectedImage!.path)}_colored';
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
    var encodedImage = base64.encode(imageBytes!);
    // print(encodedImage);
    // return;
    request.fields.addAll({
      'encoded-image': encodedImage
    });
    // var request = http.MultipartRequest('POST', url);
    // request.files.add(http.MultipartFile.fromBytes(
    //   'image',
    //   imageBytes!,
    //   filename: imageName,
    // ));
    // Map<String, String> headers = {
    //   "Content-type": "multipart/form-data",
    //   "Connection": "keep-alive",
    //   "Preprocess": isPreprocessing ? "pre" : ""
    // };
    // request.headers.addAll(headers);
    try{
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseReq = await http.Response.fromStream(response);
        final decodedBytes = base64Decode(responseReq.body);
        var result = decodedBytes;
        setState(() {
          _isProcessing = false;
        });
        Get.offAndToNamed(BeforeAfterScreen.routeName,
            arguments: {
              'selectedImage': CustomImage(
                imageBytes: imageBytes!,
              ),
              'receivedImage': CustomImage(
                imageBytes: result,
              ),
              'imageName': '${imageName}_colored'
            });
      } else {
        return;
      }
    }catch(e){
      return;
    }finally{
      if(mounted){
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        Get.off(()=> const OverviewScreen());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          leading: !_isProcessing ? IconButton(
              iconSize: 30.0,
              splashRadius: 25.0,
              onPressed: (){
                Get.off(()=> const OverviewScreen());
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white,)
          ):null,
          actions: _isProcessing ? <Widget>[
                  TextButton(
                      onPressed: () {
                        token.cancel();
                        setState(() {
                          _isProcessing = false;
                        });
                        return;
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ))
                ]
              : null,
        ),
        body: _isProcessing ? Center(child: Uploading(message: _isLoading ? 'Loading Your Image ...':'Uploading and processing your image ... \n                    Please be patient')) : Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width / 1.2,
                child: TextFormField(
                  key: _form,
                  decoration: InputDecoration(labelText: 'Enter image URL',border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0))),
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.url,
                  controller: imageUrlController,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              onTap: () async{
              await getImageFromUrl(imageUrlController.text);
            }, title: 'Load Image',),
            const SizedBox(height: 16),
            if (imageBytes != null)
              Image.memory(
                imageBytes!,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.secondary)
              ),
              onPressed: () async{
                await uploadImage(context);
              },
              child: const Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}