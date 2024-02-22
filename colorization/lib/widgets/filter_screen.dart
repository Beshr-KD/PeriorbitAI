import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:colorization/providers/history_image.dart';
import 'package:image/image.dart' as imageLib;
import 'package:colorfilter_generator/addons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:provider/provider.dart';


enum FilterImageType{
  sketch,
  pixelate,
  grayscale,
  vignette
}
class FilterScreen extends StatefulWidget {
  final Uint8List imgBytes;

  FilterScreen({required this.imgBytes});
  @override
  FilterScreenState createState() => FilterScreenState();
}

class FilterScreenState extends State<FilterScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final GlobalKey _stateBuilderKey = GlobalKey();

  final picker = ImagePicker();
  Uint8List _filteredImage = Uint8List(0);
  ColorFilter? _selectedFilter;
  static double filter = 0.5;
  bool _isFilterImage = false;
  double imageQuality = 5;
  Map<String , List<double>> filterGenMap = {
    'Brightness':ColorFilterAddons.brightness(filter),
    'Saturation':ColorFilterAddons.saturation(filter),
    // 'Hue':ColorFilterAddons.hue(filter),
    'Contrast':ColorFilterAddons.contrast(filter),
    // 'Invert':ColorFilterAddons.invert(),
  };
  Map<String , FilterImageType> imageFilterMap = {
  'Grayscale' : FilterImageType.grayscale ,
  'Sketch' :  FilterImageType.sketch ,
  'Pixelate': FilterImageType.pixelate,
  'Vignette' : FilterImageType.vignette
  };
  late String chosenFilter;

  @override
  void initState() {
    super.initState();
    chosenFilter = 'Brightness';
    _selectedFilter = ColorFilter.matrix(filterGenMap['Brightness']!);
  }

  void showMessage(BuildContext context , String message , Color color){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      dismissDirection: DismissDirection.endToStart,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      behavior: SnackBarBehavior.fixed,
      backgroundColor: color,
      content: Text(
        message,
      ),
    ));
  }

  Future<void> _saveImage() async {
    String message = 'Image saved successfully !';
    Color color = Colors.green.shade600;
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
      if(await Permission.storage.isDenied){
        return;
      }
    }
    // if(!_isSaved){
      try {
        RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: imageQuality);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        await ImageGallerySaver.saveImage(byteData!.buffer.asUint8List(),quality: 100);
        // _isSaved = true;
        // imagePath = path.absolute(temp['filePath']).replaceAll('%20', ' ').replaceFirst('/file://', '');
      } catch (e) {
        message = 'Something went wrong, try again.';
        color = Colors.red.shade600;
        return;
      }finally{
        if(context.mounted){
          showMessage(context, message, color);
        }
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: Column(
        children: [
          StatefulBuilder(key: _stateBuilderKey,
              builder: (ctx , st){
            return Column(
              children: <Widget>[
                resultImageContainer(context),
                // create drop down list that has three items
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Choose Image quality :'),
                    const SizedBox(width: 10,),
                    DropdownButton(items: const [
                      DropdownMenuItem(value: 5,child: Text('High',),),
                      DropdownMenuItem(value: 3,child: Text('Medium'),),
                      DropdownMenuItem(value: 1,child: Text('Low'),),
                    ],
                    borderRadius: BorderRadius.circular(10),
                    alignment: Alignment.center,
                    underline: null,
                    // dropdownColor: Colors.black,
                    // focusColor: Colors.black,
                    value: imageQuality,
                      onChanged: (value) {
                      _stateBuilderKey.currentState!.setState(() {
                        imageQuality = value!.toDouble();
                      });
                    },),
                  ],
                ),

                const SizedBox(height: 5,),
                _isFilterImage ? const SizedBox() : Slider(value: filter, onChanged: (value){
                  st((){
                    filter = value;
                    filterGenMap = {
                      'Brightness':ColorFilterAddons.brightness(filter),
                      'Saturation':ColorFilterAddons.saturation(filter),
                      // 'Hue':ColorFilterAddons.hue(filter),
                      'Contrast':ColorFilterAddons.contrast(filter),
                      // 'Invert':ColorFilterAddons.invert(),
                    };
                    _selectedFilter = ColorFilter.matrix(filterGenMap[chosenFilter]!);
                  });
                },
                    min: -1.0,max: 1.0),
                Text('Selected Filter: $chosenFilter'),
              ],
            );
          }),
          filterColorOptionContainer(context),
        ],
      ),
    );
  }

  // Future getImage(ImageSource imageSource) async {
  //   final pickedFile = await picker.pickImage(source: imageSource);
  //   setState(() {
  //     if (pickedFile != null) {
  //       _image = File(pickedFile.path);
  //     } else {
  //       return;
  //     }
  //   });
  // }

  AppBar appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      actions: <Widget>[
        TextButton(onPressed: (){
          _saveImage();
        }, child: const Text('Save Image',style: TextStyle(color: Colors.white),))
      ],
      elevation: 0,
      centerTitle: true,
      title: const Text('Editing', style: TextStyle(fontWeight: FontWeight.bold),),
    );
  }

  Widget resultImageContainer(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
        height: screenHeight * 0.4,
        margin: const EdgeInsets.all(5),
        child:  
        // _image == null ? Center(
        //   child: IconButton(
        //     padding: const EdgeInsets.only(right: 25,bottom: 25),
        //     icon: Icon(Icons.add, size: 50, color: Theme.of(context).primaryColor,),
        //     onPressed: () {
        //       getImage(ImageSource.gallery);
        //     },
        //   ),
        // ) : 
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child:
          _isFilterImage ? Image.memory(_filteredImage) :
          ColorFiltered(colorFilter: _selectedFilter!,child: Image.memory(widget.imgBytes),)
        )
    );
  }

  Widget filterColorOptionContainer(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(10),
        child: ListView.builder(itemBuilder: (context, index) {
          var length = filterGenMap.length;
          if(index >= length){
            return imageContainer(null , imageFilterMap.keys.elementAt(index - length) , true , imageFilterMap.values.elementAt(index - length));
          }
          return imageContainer(filterGenMap.values.elementAt(index), filterGenMap.keys.elementAt(index) , false , null);
        },
          itemCount: filterGenMap.length + imageFilterMap.length,
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }

  // Widget filterImageOptionContainer(BuildContext context) {
  //   return Expanded(
  //     flex: 1,
  //     child: Container(
  //       margin: const EdgeInsets.all(10),
  //       child: ListView.builder(itemBuilder: (context, index) {
  //         var imageType = imageFilterMap.keys.elementAt(index);
  //         var imageBytes = filteredImageBytes(orImage, imageType);
  //         return SizedBox(width: 50, height: 50,);
  //       },
  //         itemCount: imageFilterMap.length,
  //         scrollDirection: Axis.horizontal,
  //       ),
  //     ),
  //   );
  // }

  Widget imageContainer(List<double>? matrix, String filterName , bool isFilterImage , FilterImageType? type) {
    Uint8List imageBytes = Uint8List(0);
    if(isFilterImage){
      imageBytes = filteredImageBytes(widget.imgBytes, type!);
    }
    filter = 0.5;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: isFilterImage ? (){
        _stateBuilderKey.currentState!.setState(() {
          _isFilterImage = true;
          chosenFilter = filterName;
          _filteredImage = filteredImageBytes(widget.imgBytes, type!);
        });
      } :
          () {
        _stateBuilderKey.currentState!.setState(() {
          _isFilterImage = false;
          chosenFilter = filterName;
          _selectedFilter = ColorFilter.matrix(filterGenMap[chosenFilter]!);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 0),
        height: 40,
        width: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            isFilterImage ? SizedBox(
              child: Image.memory(imageBytes),
            ) : ColorFiltered(
                colorFilter: ColorFilter.matrix(matrix!),
                child: Image.memory(widget.imgBytes)
            ),
            Text(filterName)
          ],
        ),
      ),
    );
  }

  Uint8List filteredImageBytes(Uint8List originalImage , FilterImageType type){
    Uint8List finalBytes = Uint8List(0);
    imageLib.Image? image = imageLib.decodeImage(originalImage);
    switch(type){
      case FilterImageType.grayscale:
        image = imageLib.grayscale(image!);
        break;
      case FilterImageType.pixelate:
        image = imageLib.pixelate(image!, size: 4);
        break;
      case FilterImageType.sketch:
        image = imageLib.sketch(image!);
        break;
      case FilterImageType.vignette:
        image = imageLib.vignette(image!,amount: 1);
        break;
    }
    // image = imageLib.copyResize(image!, width: 600);
    finalBytes = imageLib.encodeJpg(image);
    return finalBytes;
  }

  @override
  void dispose() {
    filter = 0.5;
    super.dispose();
  }
}