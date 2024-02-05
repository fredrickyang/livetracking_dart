import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:livetracking/person.dart';
import 'package:geocoding/geocoding.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PersonTile extends StatefulWidget {
  final Person person;
  final Function(bool?)? onCheckboxSelected;
  final Function(Person) onClickPanTo;
  final Function(Person, String) onClickPanToBottomSheet;
  const PersonTile(
      {super.key,
      required this.person,
      this.onCheckboxSelected,
      required this.onClickPanTo,
      required this.onClickPanToBottomSheet});

  @override
  State<PersonTile> createState() => _PersonTileState();
}

class _PersonTileState extends State<PersonTile> {
  @override
  Widget build(BuildContext context) {
    // Data to be modified (Person)
    String personsName = widget.person.name;
    String personsImageName = widget.person.imageName;
    AssetImage personsImage = AssetImage(personsImageName);
    Color? backgroundColor = widget.person.color;

    // Data to be modified (Tiles)
    const double widthTiles = 118;
    const double spacingBetweenTiles = 10;
    const double roundedRadiusTiles = 15;
    Color? colorTiles = widget.person.color;
    colorTiles = const Color.fromARGB(255, 234, 226, 200);

    // Data to be modified (Pan Button [marker])
    Icon markerDisplay = const Icon(Icons.location_pin);
    const double widthPanButton = 50;
    const double heightPanButton = 50;
    const Color backgroundPanButton = Color.fromRGBO(220, 176, 181, 1);

    return Container(
      margin: const EdgeInsets.only(left: spacingBetweenTiles),
      width: widthTiles,
      decoration: BoxDecoration(
          color: colorTiles,
          borderRadius: BorderRadius.circular(roundedRadiusTiles)),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: backgroundColor!, width: 5),
                    shape: BoxShape.circle,
                    color: backgroundColor,
                    image: DecorationImage(
                      fit: BoxFit.fitHeight,
                      image: personsImage,
                    ),
                  ),
                ),
                onTap: () => setState(() {
                      showUserLog(context, widget.person,
                          widget.onClickPanToBottomSheet);
                    })),
            Text(personsName),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                  width: widthPanButton,
                  height: heightPanButton,
                  decoration: const BoxDecoration(
                      color: backgroundPanButton,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(roundedRadiusTiles),
                          topRight: Radius.circular(roundedRadiusTiles))),
                  child: IconButton(
                      icon: markerDisplay,
                      onPressed: () {
                        widget.onClickPanTo(widget.person);
                        widget.onCheckboxSelected!(true);
                      },
                      color: Colors.black)),
              Checkbox(
                value: widget.person.isChecked,
                onChanged: (val) => widget.onCheckboxSelected!(val),
              )
            ])
          ],
        ),
      ),
    );
  }
}
// Helper function ---=========================================

Future showUserLog(BuildContext context, Person person,
    Function(Person, String) onClickPanToBottomSheet) {
  return showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 1,
          builder: (_, controller) => ListView(
                children: [
                  topRowUserLog(person),
                  const Divider(
                    indent: 50,
                    endIndent: 50,
                  ),
                  statusUserLog(person),
                  const SizedBox(height: 30),
                  timestampsUserLog(context, person, onClickPanToBottomSheet),
                ],
              )));
}


Widget timestampsUserLog(
  BuildContext context, 
  Person person, 
  Function(Person, String) onClickPanToBottomSheet
) {
  if (person.timestamps == null || person.timestamps!.isEmpty) {
    return const Text('No timestamps available');
  }

  List<String> timestamps = person.timestamps!;
  List<LatLng> coordinates = person.coordinates!;

  // The FutureBuilder will rebuild itself when the future completes.
  return ListView.builder(
    itemCount: timestamps.length,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(), // to disable ListView's scrolling
    itemBuilder: (BuildContext context, int index) {
      return FutureBuilder<List<Placemark>>(
        future: placemarkFromCoordinates(
          coordinates[index].latitude, 
          coordinates[index].longitude
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Showing a loading spinner while waiting for geocoding data
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            // In case of error, show an error message
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // When data is received, build the widget with it
            Placemark place = snapshot.data!.first;
            String jalan = '${place.street}, ${place.postalCode}';

            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                person.lastCoord = coordinates[index];
                onClickPanToBottomSheet(person, timestamps[index]);
              },
              child: ListTile(
                leading: const Icon(Icons.location_on_sharp),
                subtitle: Text(jalan),
                title: Text(timestamps[index],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          } else {
            // In case no data is received, show a placeholder text
            return const Text('No location data');
          }
        },
      );
    },
  );
}



// Alternative ----------------- 

// Widget timestampsUserLog(
//     context, Person person, Function(Person, String) onClickPanToBottomSheet) {
      
//   if (person.timestamps == null || person.timestamps!.isEmpty) {
//     return const Text('No timestamps available');
//   }

//   List<String> timestamps = person.timestamps!;
//   List<LatLng> coordinates = person.coordinates!;
//   List<Widget> timestampWidgets = [];
//   for (int i = 0; i < timestamps.length; i++) {
//       timestampWidgets.add(Container(
//           height: 80,
//           child: Container(
//             padding: EdgeInsets.all(15),
//             margin: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
//             decoration: const BoxDecoration(
//               color: Color.fromARGB(255, 214, 241, 173),
//               borderRadius: BorderRadius.all(Radius.circular(20)),
//             ),
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 person.lastCoord = coordinates[i];
//                 onClickPanToBottomSheet(person, timestamps[i]);
//               },
//               child: Row(
//                 children: [
//                   Text(timestamps[i],
//                       style: const TextStyle(fontWeight: FontWeight.bold)),
//                   const SizedBox(width: 10),
//                   const Icon(Icons.location_on_sharp),
//                   const Spacer(),
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Text('  Latitude : ${coordinates[i].latitude}'),
//                       Text('Longitude : ${coordinates[i].longitude}')
//                     ],
//                   ),
//                 ],
//               ),
                      
//             ),
//           )));
    
//   }

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: timestampWidgets,
//   );
// }





Row topRowUserLog(Person person) {
  return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          '${person.name}',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.fitHeight,
              image: person.image.image,
            ),
          ),
        ),
      ]),
    ),
  ]);
}

Row statusUserLog(Person person) {
  String status = 'null';
  Row notif = const Row();
  if (person.color == Colors.green) {
    status = 'Active';
  } else if (person.color == Colors.red) {
    status = 'Inactive';
    notif = Row(
      children: [
        const SizedBox(height: 70),
        ElevatedButton(
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(
                  Color.fromRGBO(37, 211, 102, 1)),
              elevation: MaterialStatePropertyAll(10.0),
            ),
            onPressed: () =>
                print('https://wa.me/\${phone}?text=\${encodedMessage}'),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.whatsapp, color: Color.fromARGB(255, 58, 63, 63)),
                const SizedBox(width: 10),
                Text('Notify ${person.name}!',
                    style: const TextStyle(color: Color.fromARGB(255, 58, 63, 63))),
              ],
            ))
      ],
    );
  }

  return (status != 'null')
      ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: person.color)),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(status)
                  ],
                ),
                notif
              ],
            ),
          ],
        )
      : const Row();
}

// ---=======================================================
