import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class TfLiteInterpreter {
  static const MODEL_PATH = "model.tflite";
  static const LABELS_PATH = "assets/dict.txt";

  Interpreter _interpreter;
  List<int> _inputShape;
  List<int> _outputShape;
  TfLiteType _outputType = TfLiteType.uint8;
  TensorImage _inputImage;
  TensorBuffer _outputBuffer;
  Map<String, double> ddmap;

  NormalizeOp get preProcessNormalizeOp => NormalizeOp(127.5, 127.5);

  Future<Map<String, double>> predictImage(String imgPath) async {
    var image = File(imgPath);
    await _loadModel();
    await _predict(image);
    return ddmap;
  }

  Future<void> _loadModel() async {
    try {
      print(MODEL_PATH);
      this._interpreter = await Interpreter.fromAsset(MODEL_PATH);
      print('model loaded');
      _inputShape = _interpreter.getInputTensor(0).shape; // [1, 257, 257, 3]
      print('input_shape:');
      print(_inputShape);
      print(_interpreter.getInputTensor(0).type); //TfLiteType.float32
      _outputShape = _interpreter.getOutputTensor(0).shape;
      print('output_shape:');
      print(_outputShape);
      _outputType = _interpreter.getOutputTensor(0).type;
      print(_outputType);

      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  Future<void> _predict(File image) async {
    //read the image as bytes for TensorImage
    img.Image imageInput = img.decodeImage(image.readAsBytesSync());
    //this will be the tensor that will be used for prediction
    _inputImage = TensorImage.fromImage(imageInput);
    _inputImage = _preProcess();
    _interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    print('output buffer shape and type');
    print(_outputBuffer.getShape());
    print(_outputBuffer.getDataType());
    List<String> labels = await FileUtil.loadLabels(LABELS_PATH);
    TensorLabel tensorLabel = TensorLabel.fromList(labels, _outputBuffer);
    Map<String, double> doubleMap = tensorLabel.getMapWithFloatValue();
    ddmap = doubleMap;
    print('predictions:\n$doubleMap');
  }

  TensorImage _preProcess() {
    int cropSize = min(_inputImage.height, _inputImage.width);
    return ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
        .build()
        .process(_inputImage);
  }
}
