import 'package:colorization/models/image_item.dart';
import 'package:colorization/providers/history_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImagesGrid extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final imagesData = Provider.of<HistoryImages>(context).items;
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      itemCount: imagesData.length,
      itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
        value: imagesData[i],
        child: ImageItem(),),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
    );
  }
}
