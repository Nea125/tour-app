import 'dart:convert';

import 'package:flutter/foundation.dart';

const JsonDecoder decoder = JsonDecoder();
const JsonEncoder encoder = JsonEncoder.withIndent('  ');

void httpLog([dynamic log, dynamic additional = ""]) {
  if (kDebugMode) debugPrint("Http request Log: $log $additional");
}

void prettyPrintJson(dynamic input) {
  var prettyString = encoder.convert(input);
  prettyString.split('\n').forEach((element) => debugPrint(element));
}

printMe(dynamic msg) {
  if (kDebugMode) {
    print("👉 $msg");
  }
}


errorLog(dynamic msg) {
  if (kDebugMode) {
    print("⁉️: $msg");
  }
}