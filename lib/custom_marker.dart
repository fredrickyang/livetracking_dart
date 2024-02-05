import 'package:flutter/material.dart';
import 'package:livetracking/person.dart';

// ignore: must_be_immutable
class CustomMarkerIcon extends StatelessWidget {
  final Person person;
  bool isVisible;
  CustomMarkerIcon({super.key, required this.person, this.isVisible = false});

  @override
  Widget build(BuildContext context) {
    isVisible = false;
    return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Pin
          // Positioned(
          //   top: 20,
          //   child: Container(
          //       padding: EdgeInsets.all(4),
          //       decoration: BoxDecoration(
          //         color: Colors.grey[200],
          //         borderRadius: BorderRadius.all(Radius.circular(10)),
          //       ),
          //       child: Text(person.name)),
          // ),


          Positioned(
            bottom: -5,
            child: Icon(
              Icons.location_pin,
              size: 62,
              color: person.color,
            ),
          ),

          // Rounded Image
          Positioned(
            bottom: 16, // Adjust this value to the pin tip
            child: ClipOval(
              child: Image.asset(
                person.imageName,
                width: 30,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          )
        ],
    );
  }
}
