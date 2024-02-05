import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Person {
  final String name;
  final IconData icon;
  List<LatLng>? coordinates;
  List<String>? timestamps;
  LatLng? lastCoord;
  String? lastTimestamp;
  Color? color;
  bool isChecked;
  Image image;
  String imageName;
  String singleTimestampClicked;
  Person({required this.name, this.coordinates, this.timestamps, this.lastCoord, this.color = Colors.amber, this.icon = Icons.person, this.isChecked = false, required this.image, required this.imageName, required this.singleTimestampClicked}) {

    if (name == 'FREDRICK') {
      color = Colors.green;
    } else if (name == 'PAK IWAN') {
      color = Colors.green;

    } else if (name == 'VICKY') {
      color = Colors.red;
    } else if (name == 'SIS199404001') {
      color = Colors.green;
    } else if (name == 'JOSHE') {
      color = Colors.green;
    }
  }
  void setIsChecked(bool? value) {
    isChecked = value!;
  }

  @override
  String toString() {
    return "\n$name \n \t with color: $color \n \t and coordinates of : $coordinates \n\n";
  }
}