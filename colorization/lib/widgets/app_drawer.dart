import 'package:colorization/providers/history_image.dart';
import 'package:colorization/widgets/history.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colorization/providers/auth.dart';
import 'package:colorization/widgets//auth_screen.dart';

class AppDrawer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
              title: const Text('Colorization',style: TextStyle(color: Colors.white),),
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).primaryColor),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.of(context)
                  .pushReplacementNamed(History.routeName);
            },
          ),
          const Divider(),
          ListTile(
            leading:const Icon(Icons.exit_to_app),
            title:const Text('Logout'),
            onTap: () {
               CoolAlert.show(context: context,
                type: CoolAlertType.confirm,
                title: 'Do you want to logout ?',
                confirmBtnText: 'Yes',
                cancelBtnText: 'No',
                onConfirmBtnTap: () {
                  // Navigator.of(context).pop();
                  // Navigator.of(context).pop();
                 Provider.of<Auth>(context , listen: false).logout();
                 Provider.of<HistoryImages>(context , listen: false).logout();
                 History.isInit = true;
                 Navigator.of(context).pushNamedAndRemoveUntil(AuthScreen.routeName,(_)=>false);
                },
                onCancelBtnTap: (){
                  Navigator.of(context).pop();
                }
              );
            },
          ),
        ],
      ),
    );
  }
}