import 'package:colorization/models/images_grid.dart';
import 'package:colorization/providers/history_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'app_drawer.dart';

class History extends StatefulWidget {
  static const routeName = "/history";
  static var isInit = true;
  // History({Key key}) : super(key: key);

  @override
  HistoryState createState() => HistoryState();
}

class HistoryState extends State<History> {

  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    if(History.isInit){
      _refreshImages(context);
    }
    History.isInit = false;
  }


  @override
  void didChangeDependencies() async{
    if (mounted) {
      if (History.isInit) {
        setState(() {
          _isLoading = true;
        });
        try {
          await Provider.of<HistoryImages>(context,listen: false)
              .fetchAndSetImages(context);
        } catch (error) {
          if (mounted) {
            Future.delayed(Duration.zero).then((value) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    dismissDirection: DismissDirection.endToStart,
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red.shade800,
                    content: const Text(
                      'Something went wrong , please try again.',
                    ),
                  )
              );
            });
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
      History.isInit = false;
      super.didChangeDependencies();
    }
  }

  Future<void> _refreshImages(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try{
      await Provider.of<HistoryImages>(context , listen: false).fetchAndSetImages(context);
    }catch(error){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            dismissDirection: DismissDirection.endToStart,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 5,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
            content: const Text(
              'Something went wrong , please try again !',
            ),
          )
      );
    }finally{
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   flexibleSpace: Container(
      //     decoration: BoxDecoration(
      //       gradient: LinearGradient(
      //           begin: Alignment.topLeft,
      //           end: Alignment.bottomRight,
      //           colors: <Color>[Colors.blue.shade900, Colors.purple.shade900]),
      //     ),
      //   ),
      //   title: const Text('My Shop'),
      //   actions: <Widget>[
      //     PopupMenuButton(
      //         onSelected: (FilterOptions selectedValue) {
      //           setState(() {
      //             if (selectedValue == FilterOptions.Favorites) {
      //               _showFavoritesOnly = true;
      //             } else {
      //               _showFavoritesOnly = false;
      //             }
      //           });
      //         },
      //         icon: Icon(Icons.more_vert),
      //         itemBuilder: (_) => [
      //           PopupMenuItem(
      //             child: Text(
      //               'Only Favorites',
      //               style: TextStyle(
      //                   color: _showFavoritesOnly == true
      //                       ? Colors.blue
      //                       : Colors.black),
      //             ),
      //             value: FilterOptions.Favorites,
      //           ),
      //           PopupMenuItem(
      //             child: Text('Show All'),
      //             value: FilterOptions.All,
      //           ),
      //         ]),
      //     Consumer<Cart>(
      //       builder: (_, cart, ch) => badge.Badge(
      //         child: ch as Widget,
      //         value: cart.totalQuantity,
      //         color: Colors.black,
      //       ),
      //       child: IconButton(
      //         icon: Icon(Icons.shopping_cart),
      //         onPressed: () {
      //           Navigator.of(context).pushNamed(CartScreen.routeName);
      //         },
      //       ),
      //     )
      //   ],
      // ),
      appBar: AppBar(
        elevation: 20,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Images History'),
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(
          child: LoadingAnimationWidget.halfTriangleDot(
              color: Colors.blue.shade900, size: 150))
          : RefreshIndicator(onRefresh: (){
        return _refreshImages(context);
      },
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        backgroundColor: Colors.lightBlue.shade900,
        semanticsLabel: 'Refresh images',
        color: Colors.black,
        displacement: 15,
        strokeWidth: 3,
        child: ImagesGrid(),),
    );
  }
}