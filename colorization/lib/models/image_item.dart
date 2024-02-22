import 'dart:typed_data';

import 'package:colorization/providers/history_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as imageLib;

import '../widgets/before_after.dart';
import 'custom_image.dart';

class ImageItem extends StatelessWidget {
  final GlobalKey _stateBuilderKey = GlobalKey();
  void showMessage(BuildContext context , String message , Color color){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      dismissDirection: DismissDirection.endToStart,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      content: Text(
        message,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Provider.of<HistoryImageItem>(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        footer: GridTileBar(
          backgroundColor: Colors.black87,
          trailing: StatefulBuilder(
            key: _stateBuilderKey,
            builder:(ctx,_) => Consumer<HistoryImageItem>(
              builder: (ctx, image, _) => IconButton(
                tooltip: 'If you press again, your image will be saved again.',
                  onPressed: () async{
                    String message = 'Image saved successfully !';
                    Color color = Colors.green.shade600;
                    if(!await image.saveImage()){
                      message = 'Something went wrong, try again.';
                      color = Colors.red.shade600;
                    }
                    _stateBuilderKey.currentState!.setState(() {});
                    showMessage(context, message, color);
                  },
                  icon: Icon(
                    image.isSaved ? Icons.check : Icons.save_alt,
                    color: image.isSaved ? Colors.green : Theme.of(context).colorScheme.secondary,
                  )),
            ),
          ),
          title: Text(
            imageProvider.imageName,
            textAlign: TextAlign.center,
          ),
        ),
        child: GestureDetector(
          onTap: () {
            imageLib.Image? image = imageLib.decodeImage(imageProvider.coloredBytes);
            image = imageLib.grayscale(image!);
            Uint8List finalBytes = imageLib.encodeJpg(image);
            Get.toNamed(BeforeAfterScreen.routeName,
                arguments: {
                  'selectedImage': CustomImage(
                    imageBytes: finalBytes,
                  ),
                  'receivedImage': CustomImage(
                    imageBytes: imageProvider.coloredBytes,
                  ),
                  'imageName': imageProvider.imageName
                });
          },
          child: FadeInImage(
            placeholder: const AssetImage('assets/images/camera.jpg'),
            image: Image.memory(imageProvider.coloredBytes).image,
            imageErrorBuilder: (ctx , _ , __){
              return Image.asset('assets/images/gallery.png' , fit: BoxFit.fill,);
            },
          ),
        ),
      ),
    );
  }
}
