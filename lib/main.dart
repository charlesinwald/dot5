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
      )
    ),
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
      appBar: AppBar(title: Text('Take a picture'),),
      //Wait until the controller is initialized before displaying the camera
      //preview. Future builder displays a loading spinner until the controller
      //has finished initializing
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.done) {
            //If the Future is complete, display the preview
            return CameraPreview(_controller);
          } else {
            //Otherwise display a loading indicator
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.camera_alt),
          //Button callback
          onPressed: () async {
            //Take the Picture in a try/catch block.
            try {
              //Ensure camera is initialized
              await _initializeControllerFuture;

              //Construct the path to save to
              var name = '${DateTime.now()}.png';
              final path = join((await getTemporaryDirectory()).path,
                name,
              );

              //Attempt to take a picture and log where it's been saved
              await _controller.takePicture(path);

              //If the picture was taken, display it on a new screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DisplayPictureScreen(imagePath: path, fileName: name),
                ),
              );
            } catch (e) {
              print(e);
            }
          }),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final String fileName;
  const DisplayPictureScreen({Key key, this.imagePath, this.fileName}) : super (key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      //Constructs an image object from the path passed in as a parameter to the widget
      body: Scaffold(
          body: Image.file(File(imagePath))),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.cloud_upload),
          onPressed: () async {
            try {
              final log = Logger('DisplayPictureScreen');
//              log.fine(File(imagePath));
              final Dio _dio = Dio();
              Response response = await _dio.post(
                "http://128.180.108.68:4000/upload",
                data: FormData.from({
                  "file": UploadFileInfo(File(imagePath), fileName),
                }),
              );
              print(response);
              //Delete the file now that we are done with it
              File(imagePath).deleteSync(recursive: false);
              //Go back to the main screen
              Navigator.pop(context);
            } catch(e) {
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
          default:
            throw Exception('Invalid route: ${settings.name}');
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
