// Flutter code sample for widgets.Navigator.1

// The following example demonstrates how a nested [Navigator] can be used to
// present a standalone user registration journey.
//
// Even though this example uses two [Navigator]s to demonstrate nested
// [Navigator]s, a similar result is possible using only a single [Navigator].
//
// Run this example with `flutter run --route=/signup` to start it with
// the signup flow instead of on the home page.

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

Future<void> main() async {
  //Obtain a list of available cameras
  final cameras = await availableCameras();
  //Get a specific camera from the list
  final firstCamera = cameras.first;
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(
    MaterialApp(
        theme: ThemeData.dark(),
        home: TakePictureScreen(
          //Pass the appropriate camera to the widget
          camera: firstCamera,
        )),
  );
}

// Takes a picture with a passed in camera
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    //To display the current output from the camera,
    //crete a CameraController
    _controller = CameraController(
      //Get a specific camera from the list of available cameras
      widget.camera,
      //Define the resolution to use
      ResolutionPreset.medium,
    );

    //Next initialize the controller, this returns a Future
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    //Dispose of the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DOT'),
//        actions: <Widget>[
//          Center(child: Text('1 Coin(s)')),
//          Padding(padding: EdgeInsets.all(1)),
//          FlatButton(
//            onPressed: () {
//              Navigator.push(
//                  context,
//                  MaterialPageRoute(
//                    builder: (context) => VotingPage(),
//                  ));
//            },
//            child: Text('VOTE'),
//          ),
//          Padding(padding: EdgeInsets.all(1))
//        ],
      ),
      //Wait until the controller is initialized before displaying the camera
      //preview. Future builder displays a loading spinner until the controller
      //has finished initializing
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            //If the Future is complete, display the preview
            return CameraPreview(_controller);
          } else {
            //Otherwise display a loading indicator
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Transform.scale(
          scale: 3,
          child: CenterHorizontal(FloatingActionButton(
              child: Icon(Icons.filter_tilt_shift),
              backgroundColor: const Color(0xFFFFFF),
              elevation: 0.0,
              //Button callback
              onPressed: () async {
                //Take the Picture in a try/catch block.
                try {
                  GeolocationStatus geolocationStatus =
                      await Geolocator().checkGeolocationPermissionStatus();
                  print(geolocationStatus);
                  Position position = await Geolocator().getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.best);
                  print(position);
                  //Ensure camera is initialized
                  await _initializeControllerFuture;

                  //Construct the path to save to
                  var name = '${DateTime.now()}.png';
                  final path = join(
                    (await getTemporaryDirectory()).path,
                    name,
                  );

                  //Attempt to take a picture and log where it's been saved
                  await _controller.takePicture(path);

                  //If the picture was taken, display it on a new screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadPicture(
                          imagePath: path, fileName: name, location: position),
                    ),
                  );
                } catch (e) {
                  print(e);
                }
              }))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class UploadPicture extends StatelessWidget {
  final String imagePath;
  final String fileName;
  final Position location;
  const UploadPicture(
      {Key key, this.imagePath, this.fileName, this.location})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload'),
//        actions: <Widget>[Text('1 Coin')],
      ),
      //Constructs an image object from the path passed in as a parameter to the widget
      body: Scaffold(body: Image.file(File(imagePath))),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.cloud_upload),
          onPressed: () async {
            try {
              final Dio _dio = Dio();
              Response response = await _dio.post(
                "http://128.180.108.68:4000/upload",
                data: FormData.from({
                  "file": UploadFileInfo(File(imagePath), fileName),
                  "location": location
                }),
              );
              print(response);
              var amount = 1.00;
              //Delete the file now that we are done with it
              File(imagePath).deleteSync(recursive: false);

              var alertStyle = AlertStyle(
//                overlayColor: Colors.blue[400],
                overlayColor: Color(0xfff98650),
                animationType: AnimationType.fromTop,
                backgroundColor: Color(0xfff7f5ea),
                isCloseButton: false,
                isOverlayTapDismiss: false,
                descStyle: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xff202125)),
                animationDuration: Duration(milliseconds: 400),
                alertBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                  side: BorderSide(
                    color: Colors.grey,
                  ),
                ),
                titleStyle: TextStyle(
                  color: Color(0xff393a3f),
                ),
              );
              Alert(
                context: context,
                style: alertStyle,
                type: AlertType.success,
                title: "Reward",
                desc: "You have recieved  $amount  DOT coins",
                buttons: [
                  DialogButton(
                    child: Text(
                      "COOL",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    color: Color(0xff202125),
                    radius: BorderRadius.circular(10.0),
                  ),
                ],
              ).show();
              Alert(
                      context: context,
                      title: "Upload Complete",
                      desc: "Upload Complete")
                  .show();
              //Go back to the main screen
              Navigator.pop(context);
            } on DioError catch (e) {
              var alertStyle = AlertStyle(
//                overlayColor: Colors.blue[400],
                overlayColor: Color(0xfff98650),
                animationType: AnimationType.fromTop,
                backgroundColor: Color(0xfff7f5ea),
                isCloseButton: false,
                isOverlayTapDismiss: false,
                descStyle: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xff202125)),
                animationDuration: Duration(milliseconds: 400),
                alertBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                  side: BorderSide(
                    color: Colors.grey,
                  ),
                ),
                titleStyle: TextStyle(
                  color: Color(0xff393a3f),
                ),
              );
              Alert(
                      context: context,
                      style: alertStyle,
                      title: "Upload Error",
                      desc: "Upload Error $e")
                  .show();
            } catch (e) {
              print('line 238');
              print(e);
            }
          }),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Code Sample for Navigator',
      // MaterialApp contains our top-level Navigator
      initialRoute: '/',
      routes: {
        '/': (BuildContext context) => HomePage(),
        '/signup': (BuildContext context) => SignUpPage(),
        '/vote': (BuildContext context) => VotingPage()
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.display1,
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Text('Home Page'),
      ),
    );
  }
}

class VotingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.display1,
      child: GestureDetector(
        onTap: () {
          // This moves from the personal info page to the credentials page,
          // replacing this page with that one.
//          Navigator.of(context)
//              .pushReplacementNamed('signup/choose_credentials');
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('DOT'),
            actions: <Widget>[
              Center(child: Text('1 Coin(s)')),
              Padding(padding: EdgeInsets.all(10))
            ],
          ),
          body: Container(
            color: Colors.lightBlue,
            alignment: Alignment.center,
            child: Text('Voting Page'),
          ),
          floatingActionButton:
            Row(children: [
              FloatingActionButton(
                  child: Icon(Icons.cancel),
                  onPressed: () {
                    print('Left');
                  }),
              FloatingActionButton(
                  child: Icon(Icons.check),
                  onPressed: () {
                    print('Right');
                  })
            ]),
          ),
        ),
    );
  }
}

class CollectPersonalInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.display1,
      child: GestureDetector(
        onTap: () {
          // This moves from the personal info page to the credentials page,
          // replacing this page with that one.
          Navigator.of(context)
              .pushReplacementNamed('signup/choose_credentials');
        },
        child: Container(
          color: Colors.lightBlue,
          alignment: Alignment.center,
          child: Text('Collect Personal Info Page'),
        ),
      ),
    );
  }
}

class ChooseCredentialsPage extends StatelessWidget {
  const ChooseCredentialsPage({
    this.onSignupComplete,
  });

  final VoidCallback onSignupComplete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSignupComplete,
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.display1,
        child: Container(
          color: Colors.pinkAccent,
          alignment: Alignment.center,
          child: Text('Choose Credentials Page'),
        ),
      ),
    );
  }
}

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // SignUpPage builds its own Navigator which ends up being a nested
    // Navigator in our app.
    return Navigator(
      initialRoute: 'signup/personal_info',
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case 'signup/personal_info':
            // Assume CollectPersonalInfoPage collects personal info and then
            // navigates to 'signup/choose_credentials'.
            builder = (BuildContext _) => CollectPersonalInfoPage();
            break;
          case 'signup/choose_credentials':
            // Assume ChooseCredentialsPage collects new credentials and then
            // invokes 'onSignupComplete()'.
            builder = (BuildContext _) => ChooseCredentialsPage(
                  onSignupComplete: () {
                    // Referencing Navigator.of(context) from here refers to the
                    // top level Navigator because SignUpPage is above the
                    // nested Navigator that it created. Therefore, this pop()
                    // will pop the entire "sign up" journey and return to the
                    // "/" route, AKA HomePage.
                    Navigator.of(context).pop();
                  },
                );
            break;
          case '/vote':
            builder = (BuildContext _) => VotingPage();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

class CenterHorizontal extends StatelessWidget {
  CenterHorizontal(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [child]);
}
