import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mypasar/user.dart';
import 'package:toast/toast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'mainscreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double screenHeight;
  @override
  void initState() {
    super.initState();
    print("in splash screen");
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.anaheimTextTheme(
            Theme.of(context).textTheme,
          ),
                
      ),
      title: 'My.Pasar',
      home: Scaffold(
          body: Container(
        child: Stack(
          children: <Widget>[
            Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/splash.jpg'),
                        fit: BoxFit.cover))),
            Container(height: 300, child: ProgressIndicator())
          ],
        ),
      )),
    );
  }
}

class ProgressIndicator extends StatefulWidget {
  @override
  _ProgressIndicatorState createState() => new _ProgressIndicatorState();
}

class _ProgressIndicatorState extends State<ProgressIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;
  String thisversion = "1";
  User user;
  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    animation = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener(() {
        setState(() {
          //updating states
          if (animation.value > 0.99) {
            loadpref(this.context);
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (BuildContext context) => LoginScreen()));
          }
        });
      });
    controller.repeat();
  }

  @override
  void dispose() {
    controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
        child: new Container(
      //width: 300,
      child: CircularProgressIndicator(
        value: animation.value,
        //backgroundColor: Colors.brown,
        valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    ));
  }

  void checkVersion(phone, pass, ctx) {
    String urlLoadProd = "https://slumberjer.com/mypasar/php/check_version.php";
    http
        .post(urlLoadProd, body: {})
        .then((res) {
          print(res.body);
          if (res.body != thisversion) {
            Toast.show("Terdapat versi baru sila kemaskini aplikasi", context,
                duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
            //Navigator.of(context).pop(false);
            Timer(Duration(seconds: 3), () {
              exit(0);
            });
          } else {
            _onLogin(phone, pass, ctx);
          }
        })
        .catchError((err) {
          print(err);
        })
        .timeout(const Duration(seconds: 10))
        .then((value) => {print("timeout")});
  }

  void loadpref(BuildContext ctx) async {
    print('Inside loadpref()');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = (prefs.getString('phone') ?? '');
    String pass = (prefs.getString('pass') ?? '');
    print("Splash:Preference");

    if (phone.length > 5) {
      //try to login if got email pref;
      checkVersion(phone, pass, ctx);
    } else {
      //login as unregistered user
      user = new User(
          name: "Tidak Berdaftar",
          phone: "123456789",
          password: "123456",
          datereg: "2020-04-14 22:00:39.205144",
          credit: "0",
          radius: "5");
      Navigator.push(
          ctx, MaterialPageRoute(builder: (context) => MainScreen(user: user)));
    }
  }

  void _onLogin(String phone, String pass, BuildContext ctx) {
    http
        .post("https://slumberjer.com/mypasar/php/login_user.php", body: {
          "phone": phone,
          "password": pass,
        })
        .then((res) {
          print(res.statusCode);
          var string = res.body;
          List userdata = string.split(",");
          print("SPLASH:loading");
          print(userdata);
          if (userdata[0] == "success") {
            User _user = new User(
                name: userdata[1],
                phone: phone,
                password: pass,
                datereg: userdata[2],
                credit: userdata[3],
                radius: userdata[4]);
            Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (context) => MainScreen(user: _user)));
          } else {
            //allow login as unregistered user
            User _user = new User(
                name: userdata[1],
                phone: phone,
                password: pass,
                datereg: userdata[2],
                credit: userdata[3],
                radius: userdata[4]);
            Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (context) => MainScreen(user: _user)));
          }
        })
        .catchError((err) {
          print(err);
        })
        .timeout(const Duration(seconds: 10))
        .then((value) => {print("timeout")});
  }
}
