import 'package:flutter/foundation.dart';

class TypeConverter {
  static List<int> convertIntoListOfInteger(String options) {
    List<int> result = [];
    String s = options.replaceAll('(', '').replaceAll(')', '');
    List<String> res = s.split(',');
    for (String element in res) {
      try {
        result.add(int.parse(element));
      } catch (e) {
        if (kDebugMode) {
          print('=====not converted : $e');
        }
      }
    }
    return result;
  }

  static bool getBool(dynamic value){
    return value == 'true' || value == true || value == 1 || value == '1';
  }
}
