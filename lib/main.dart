import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'tflite_interpreter.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List _outputs;
  Map<String, double> outmap;
  File _image;
  bool _loading = false;
  TfLiteInterpreter tf1 = new TfLiteInterpreter();
  String outputKey;
  var outputValue;
  String suggestions;
  var isCalling = false;
  var _response;
//  Interpreter _interpreter;
//  ImageProcessor imageProcessor = ImageProcessorBuilder()
//      .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
//      .build();

  @override
  void initState() {
    super.initState();
    _loading = true;
    isCalling = false;
    print("Initialize isCalling: " + isCalling.toString());
//    _response['sharpness'] = 0.0;
//    _response['brightness'] = 0.0;
//    _response['contrast'] = 0.0;
    _response = {'sharpness': 0.0, 'brightness': 0.0, 'contrast': 0.0};
//    loadModel().then((value) {
//      setState(() {
//        _loading = false;
//      });
//    });
  }

//  showAlertDialog(BuildContext context) {
//    // set up the button
//    Widget okButton = FlatButton(
//      child: Text("OK"),
//      onPressed: () {},
//    );
//
//    // set up the AlertDialog
//    AlertDialog alert = AlertDialog(
//      title: Text("My title"),
//      content: Text("This is my message."),
//      actions: [
//        okButton,
//      ],
//    );
//
//    // show the dialog
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        return alert;
//      },
//    );
//  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text("FacUp"))),
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null
                      ? Container()
                      : new Image.file(
                          _image,
                          height: 450,
                          width: 1000,
                        ),
                  outputKey != null
                      ? Center(
                          child: Table(
                            border: TableBorder.all(
                                style: BorderStyle.none, width: 0.5),
                            columnWidths: {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(children: [
                                Text('Skin Tone'),
                                Text("${outputKey}"),
                              ]),
                              TableRow(children: [
                                Text('Confidence'),
                                Text('${outputValue}'),
                              ]),
                              TableRow(children: [
                                Text('Suggestions'),
                                Text('${suggestions}'),
                              ]),
                              TableRow(children: [
                                Text('Brightness'),
                                Text(isCalling
                                    ? 'Detecting ...'
                                    : '${_response['brightness']}'),
                              ]),
                              TableRow(children: [
                                Text('Sharpness'),
                                Text(isCalling
                                    ? 'Detecting ...'
                                    : '${_response['sharpness']}'),
                              ]),
                              TableRow(children: [
                                Text('Contrast'),
                                Text(isCalling
                                    ? 'Detecting ...'
                                    : '${_response['contrast']}'),
                              ]),
                            ],
                          ),
                        )
                      : Container()
//                      ? Text(
//                          "${outputKey} "
//                          "${outputValue}",
//                          style: TextStyle(
//                            color: Colors.black,
//                            fontSize: 20.0,
//                            background: Paint()..color = Colors.white,
//                          ),
//                        )
//                      : Container()
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        child: Icon(Icons.image),
      ),
    );
  }
//https://dashboard.sightengine.com/getstarted
//  https://github.com/shaqian/flutter_tflite/issues/55
//  https://gist.github.com/Bryanx/b839e3ceea0f9647ffbc5f90e3091742
//  https://github.com/kshitizrimal/Classification-Flutter-TFlite
// https://firebase.google.com/docs/ml/android/use-custom-models
//  https://firebase.google.com/docs/ml/manage-hosted-models
//  https://www.youtube.com/results?search_query=firebase+auto+ml+python
//  https://www.google.com/search?q=flutter+lite&oq=flutter+lite&aqs=chrome..69i57j69i59l2j69i60j69i61j69i60l2.15719j0j1&sourceid=chrome&ie=UTF-8
//  https://pub.dev/packages/tflite
//  https://pub.dev/packages/tflite_flutter
//  https://pub.dev/packages/image
//  https://pub.dev/packages/image_picker
//  https://github.com/am15h/tflite_flutter_plugin
//  https://github.com/am15h/tflite_flutter_helper
//  https://pub.dev/packages/tflite_flutter_helper
//  https://medium.com/@am15hg/real-time-object-detection-using-new-tensorflow-lite-flutter-support-ea41263e801d
//  https://www.youtube.com/results?search_query=flutter+custom+model+
//  https://www.youtube.com/watch?v=Z_vdMqWXEsw
//  https://api.flutter.dev/flutter/dart-core/List-class.html
//  https://gist.github.com/Bryanx/b839e3ceea0f9647ffbc5f90e3091742

//
  pickImage() async {
    ImagePicker picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    final File image = File(pickedFile.path);
//    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    _image = image;
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  callApi(File image) async {
    print('----------------------API Start_______________');
    setState(() {
      _response['sharpness'] = 0.0;
      _response['brightness'] = 0.0;
      _response['contrast'] = 0.0;
      isCalling = true;
      print("callApi: Set isCalling: " + isCalling.toString());
    });
    var postUri = Uri.parse("https://api.sightengine.com/1.0/check.json");
    var request = new http.MultipartRequest("POST", postUri);
    request.fields['api_user'] = '898643903';
    request.fields['api_secret'] = 'z9xj8bpdBNHUsGaFUABk';
    request.fields['models'] = 'properties';

    request.files.add(await http.MultipartFile.fromPath(
      'media',
      image.absolute.path,
      contentType: new MediaType('image', 'jpg'),
    ));
    print('callApi: Requesting ... ');
    request
        .send()
        .then((result) async {
          http.Response.fromStream(result).then((response) {
            if (response.statusCode == 200) {
              print("callApi: Uploaded! ");
              print('response.body ' + response.body);
//              return response;
            }
            setState(() {
              isCalling = false;
              _response = json.decode(response.body);
              print("callApi: Set isCalling: " + isCalling.toString());
            });
            print(_response['sharpness']);
            print('----------------------API DONE_______________');
            return response.body;
          });
        })
        .catchError((err) => print('callApi: error : ' + err.toString()))
        .whenComplete(() {});
  }

// Must be top-level function
  _parseAndDecode(String response) {
    return jsonDecode(response);
  }

  classifyImage(File image) async {
//    img.Image im = img.decodeImage(File(image.path).readAsBytesSync());
//    TensorImage tensorImage = TensorImage.fromFile(image);
//    tensorImage = imageProcessor.process(tensorImage);
//
//    TensorBuffer probabilityBuffer =
//        TensorBuffer.createFixedSize(<int>[1, 1001], TfLiteType.uint8);
//
//    try {
//      // Create interpreter from asset.
//      Interpreter interpreter = await Interpreter.fromAsset("model.tflite");
//      interpreter.run(tensorImage.buffer, probabilityBuffer.buffer);
//    } catch (e) {
//      print('Error loading model: ' + e.toString());
//    }
//    TensorBuffer outputBuffer = TensorBuffer.createFixedSize(
//        interpreter.getOutputTensor(0).shape,
//        interpreter.getOutputTensor(0).type);
//
//    var output = probabilityBuffer.getDoubleList();

//    var output = await Tflite.runModelOnImage(
//      path: image.path,
//      numResults: 2,
//      threshold: 0.5,
//      imageMean: 127.5,
//      imageStd: 127.5,
//    );
    print('----------------------Classifing______________');
    await tf1.predictImage(image.path);
    var output = tf1.ddmap;
    var confidence = 0.0;
    var totalScore = 0.0;

    var thevalue = 0.0;
    var thekey;

    output.forEach((k, v) {
      if (v > thevalue) {
        thevalue = v;
        thekey = k;
      }
      totalScore = totalScore + v;
    });
    String msg;
    confidence = thevalue / totalScore;
    if (thekey.toString() == 'Other') {
      thekey = 'No face detected!';
      msg = 'Nothing to suggest';
    }
    if (thekey.toString() == 'Pokemon') {
      thekey = 'You are amazing trainer! Love you';
      msg = 'You need a limited pokemon concealer!';
      thevalue = 3000;
    } else {
      thevalue = confidence * 100;
    }

    if (thekey.toString() == 'amond') {
      msg = "Light Ivory coloured Concealer, Medium Beige coloured Concealer";
    }
    if (thekey.toString() == 'ivory') {
      msg = "Medium Beige coloured Concealer, Fawn coloured Concealer";
    }
    if (thekey.toString() == 'natural') {
      msg = "Light Ivory coloured Concealer, Fawn coloured Concealer";
    }
    suggestions = msg;
//    Dio dio = new Dio();
//    FormData formData;
//    Response response;
//    try {
//      String filename = image.path.split('/').last;
//      FormData formData = new FormData.fromMap(
//        {
//          "media": await MultipartFile.fromFile(image.path,
//              filename: filename, contentType: new MediaType('image', 'jpg')),
//          "type": "image/jpg"
//        },
//      );
//
//      response = await dio.post("path",
//          data: formData,
//          options: Options(headers: {
//            'api_user': '898643903',
//            'api_secret': 'z9xj8bpdBNHUsGaFUABk',
//            'Content-type': 'multipart/form-data',
//            'models': 'properties',
//          }));
//    } catch (e) {
//      print(e);
//    }
//    String filename = image.path.split('/').last;
//    FormData formData = new FormData.fromMap(
//      {
//        "media": await MultipartFile.fromFile(image.path,
//            filename: filename, contentType: new MediaType('image', 'jpg')),
//        "type": "image/jpg"
//      },
//    );
//    final http.Response response = await http.post(
//      'https://api.sightengine.com/1.0/check.json',
//      headers: <String, String>{
//        // no! let http set the content type itself -'Content-Type': 'application/json; charset=UTF-8',
//      },
//      body: <String, String>{
//        'api_user': '898643903',
//        'api_secret': 'z9xj8bpdBNHUsGaFUABk',
//        'Content-type': 'multipart/form-data',
//        'models': 'properties',
//      },
//
//    );
//    if (response.statusCode == 200) {
//      var parsedJson = json.decode(response);
//    }
//    var request = http.MultipartRequest(
//        'POST', Uri.parse('https://api.sightengine.com/1.0/check.json'));
//    request.files.add(http.MultipartFile.fromBytes(
//        'picture', File(image.path).readAsBytesSync(),
//        filename: image.path.split("/").last));
//    request.fields['api_user'] = '898643903';
//    request.fields['api_secret'] = 'z9xj8bpdBNHUsGaFUABk';
//    request.fields['models'] = 'properties';
//    var res = await request.send();+

    print("Start test");
    var test = callApi(image);
//      setState(() {
//        isCalling = false;
//        print("classifyImage: Set isCalling: " + isCalling.toString());
    print("test Done!");
    print('----------------------Classified______________');
    print("@======================================");
    print(_response.toString());
    print("@======================================");
    output = {thekey: thevalue};
    setState(() {
      _loading = false;
      outmap = output;
      outputKey = thekey;
      outputValue = thevalue;
      suggestions = msg;
    });
  }

  loadModel() async {
//    await Tflite.loadModel(
//      model: "assets/model.tflite",
//      labels: "assets/dict.txt",
//    );
  }

  @override
  void dispose() {
//    Tflite.close();
    super.dispose();
  }
}

//import 'tflite_interpreter.dart';
//
//void main() => runApp(MaterialApp(
//      home: MyApp(),
//    ));
//
//class MyApp extends StatefulWidget {
//  @override
//  _MyAppState createState() => _MyAppState();
//}
//
//class _MyAppState extends State<MyApp> {
////  List _outputs;
//  Map<String, double> _outputs;
//  File _image;
//  bool _loading = false;
//  final picker = ImagePicker();
//
//  @override
//  void initState() {
//    super.initState();
//    _loading = true;
//
//    loadModel().then((value) {
//      setState(() {
//        _loading = false;
//      });
//    });
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Teachable Machine Learning'),
//      ),
//      body: _loading
//          ? Container(
//              alignment: Alignment.center,
//              child: CircularProgressIndicator(),
//            )
//          : Container(
//              width: MediaQuery.of(context).size.width,
//              child: Column(
//                crossAxisAlignment: CrossAxisAlignment.center,
//                mainAxisAlignment: MainAxisAlignment.center,
//                children: [
//                  _image == null ? Container() : Image.file(_image),
//                  SizedBox(
//                    height: 20,
//                  ),
//                  _outputs != null
//                      ? Text(
//                          "Values: ${_outputs.values} Label: ${_outputs.keys}",
//                          style: TextStyle(
//                            color: Colors.black,
//                            fontSize: 20.0,
//                            background: Paint()..color = Colors.white,
//                          ),
//                        )
//                      : Container()
//                ],
//              ),
//            ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: pickImage,
//        child: Icon(Icons.image),
//      ),
//    );
//  }
//
//  pickImage() async {
//    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
////    var pickedFile = await picker.getImage(source: ImageSource.gallery);
////    var image = File(pickedFile.path);
//    if (image == null) return null;
//    setState(() {
//      _loading = true;
//      _image = image;
//    });
//    print('image loaded');
//    classifyImage(image);
//  }
//
//  classifyImage(File image) async {
////    var output = await Tflite.runModelOnImage(
////      path: image.path,
////      numResults: 2,
////      threshold: 0.5,
////      imageMean: 127.5,
////      imageStd: 127.5,
////    );
//    print("created Tf object");
//    TfLiteInterpreter tf = new TfLiteInterpreter();
//    print(image.path);
//    var output = await tf.predictImage(image.path);
//    setState(() {
//      _loading = false;
//      _outputs = output;
//    });
//  }
//
//  loadModel() async {
////    await Tflite.loadModel(
////      model: "model/model.tflite",
////      labels: "model/dict.txt",
////    );
//  }
//
//  @override
//  void dispose() {
////    Tflite.close();
//    super.dispose();
//  }
//}
