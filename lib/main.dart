// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:livetracking/custom_marker.dart';
import 'package:livetracking/karyawan_tile.dart';
import 'package:livetracking/person.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LiveTracking(title: 'Live Tracking'),
    );
  }
}

class LiveTracking extends StatefulWidget {
  const LiveTracking({super.key, required this.title});
  final String title;

  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
  // -- VARIABLES ===========================================

  // used in search bar
  TextEditingController cariKaryawan = TextEditingController();

  // initialize time
  DateTime dateChosen = DateTime.now();
  TimeOfDay _timeFrom = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _timeTo = TimeOfDay.now();
  String dateData = '';

  // stores all the data read
  dynamic _allData;
  Set<String> _namesdata = {};
  Map<String, Map<String, dynamic>> _combinedData = {};
  List<dynamic> featuresList = [];
  

  // statuses
  bool _isSelectAll = false;
  bool _isloading = true;
  bool _notFound = false;
  bool _isFullScreen = false;

  // all Person to be displayed
  final List<Person> _toBeDisplayed = [];
  final Map<String, bool> _checkedBoxes = {};
  final Map<String, String> _singleCheckedTimestamp = {};
  String _searchedPerson = '';

  // data to be displayed
  final List<dynamic> _dataToBeDrawn = [];

  // Map Controller
  final MapController mapController = MapController();

  @override
  void initState() {
    _getData();
    super.initState();
  }

  // Fetch data ---==========================================
  Future _getData() async {
    try {
      print('try');
      final response = await http
          .get(Uri.parse('http://192.168.100.39/livetracking/all_data.php'));

      if (response.statusCode == 200) {
        print('entered 200');
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          _allData = data;

          _updateData();

          _updateToBeDisplayed();

          _isloading = false;
        });
      }
    } catch (e) {
      print('hello');
      // ignore: avoid_print
      print(e);
    }
  }

  // ---=========================================
  
  // Update (coords and names to be displayed) ---===================================
  void _updateData() {
    dateData =
        '${dateChosen.year}-${dateChosen.month.toString().padLeft(2, '0')}-${dateChosen.day.toString().padLeft(2, '0')}';

    featuresList = _allData['features']
        .where((feature) => feature['properties']['date'] == dateData)
        .toList() as List;

    _notFound = featuresList.isEmpty;

    // reset the names of people && combined data
    _combinedData = {};
    _namesdata = {};
    for (var feature in featuresList) {
      String name = feature['properties']['name'];

      // add name data
      _namesdata.add(name);

      // combine separated data into _combinedData
      if (!_combinedData.containsKey(name)) {
        _singleCheckedTimestamp[name] = '';

        // If not, create a new entry with the current feature's data
        _combinedData[name] = {
          'name': name,
          'timestamps': List<String>.from(feature['properties']['timestamps']),
          'coordinates': (feature['geometry']['coordinates'] as List)
              .map((coords) => LatLng(coords[1], coords[0]))
              .toList(),
        };
      } else {
        // If it does, append the timestamps and coordinates to the existing entry
        _combinedData[name]!['timestamps']
            .addAll(List<String>.from(feature['properties']['timestamps']));
        _combinedData[name]!['coordinates'].addAll(
            (feature['geometry']['coordinates'] as List)
                .map((coords) => LatLng(coords[1], coords[0]))
                .toList());
      }

    }
  }

  // Update ---=========================================================
  // Update data and make list of all elements that will be drawn
  // important function, most logics here.

  void _updateToBeDisplayed() {

    // clear all
    _toBeDisplayed.clear();
    _dataToBeDrawn.clear();
    setState(() {
      // update
      for (var name in _namesdata) {

        String imageName = 'assets/$name.png';
        Image image = getImage(name);
      
        Person karyawan = Person(
            name: name,
            timestamps: _combinedData[name]!['timestamps'],
            coordinates: _combinedData[name]!['coordinates'],
            icon: Icons.person,
            imageName: imageName,
            image: image,
            isChecked: _checkedBoxes[name] ?? _isSelectAll,
            singleTimestampClicked: _singleCheckedTimestamp[name] ?? '');

        for (var feature in featuresList) {
          // current name?
          var currName = feature['properties']['name'];

          // skips repetition
          if (_singleCheckedTimestamp[karyawan.name] == 'done') {
            continue;
          }

          if (name != currName || !karyawan.isChecked) {
            continue; // save space
          } else {
            List<String> timestamps =
                feature['properties']['timestamps'].cast<String>();

            List<List<double>> coordinates =
                (feature['geometry']['coordinates'] as List)
                    .map((e) => List<double>.from(e))
                    .toList();

            List<LatLng> line = [];
          
            // A single timestamp is clicked in a profile
            if (_singleCheckedTimestamp[name]!.isNotEmpty) {

              for (int i = 0; i < karyawan.timestamps!.length; i += 1) {
                line.add(karyawan.coordinates![i]);
                if (!_isLessThanCurrTimeStamp(karyawan.singleTimestampClicked, karyawan.timestamps![i])) {
                  break;
                }
              }
              _singleCheckedTimestamp[karyawan.name] = 'done';
            } else {
            // A normal reading of data and drawing paths---

            // Check timestamps if valid or not

            for (int i = 0; i < timestamps.length; i++) {
              TimeOfDay timestamp = TimeOfDay(
                  hour: int.parse(timestamps[i].split(':')[0]),
                  minute: int.parse(timestamps[i].split(':')[1]));

              if (_isTimeInRange(timestamp, _timeFrom, _timeTo)) {
                line.add(LatLng(coordinates[i][1], coordinates[i][0]));
              }
            }
            }

            // -------- at this point, `line` is all coordinates that pass the _isTimeInRange test -----
            if (line.isNotEmpty) {
              karyawan.lastCoord = line.last;
              _dataToBeDrawn.add(drawPolyline(karyawan, line));
              _dataToBeDrawn.add(drawMarker(karyawan));
            }
          }
        }

        if (karyawan.name.toLowerCase().contains(_searchedPerson)) {
          _toBeDisplayed.add(karyawan);
        }
        _checkedBoxes[name] = karyawan.isChecked;
      }
    });


    // Reset the status of single timestamp selection (Profile)
    _singleCheckedTimestamp.updateAll((key, value) => '');
  }

  // ------=============================================================

  // UI ---=========================

  // Date Picker
  void _showDatePicker() {
    showDatePicker(
            context: context,
            firstDate: DateTime(2021),
            lastDate: DateTime.now())
        .then((value) {
      dateChosen = value ?? DateTime.now();

      setState(() {
        _updateData();
        _updateToBeDisplayed();
      });
    });
  }

  // Time picker (from)
  void _timePickerFrom() {
    showTimePicker(context: context, initialTime: _timeFrom).then((value) {
      setState(() {
        _timeFrom = value ?? _timeFrom;
      });
      _updateToBeDisplayed();
    });
  }

  // Time picker (to)
  void _timePickerTo() {
    showTimePicker(context: context, initialTime: _timeTo).then((value) {
      setState(() {
        _timeTo = value ?? _timeTo;
      });
      _updateToBeDisplayed();
    });
  }

  // Search Bar (searching)
  _runFilter(String value) {
    setState(() {
      _searchedPerson = value;
    });
    _updateToBeDisplayed();
  }

  // Search Bar (clear)
  void _clearButton() {
    setState(() {
      cariKaryawan.clear();
      _searchedPerson = '';
    });
    _updateToBeDisplayed();
  }

  // Move to a person (PersonTile)
  void _clickPanTo(Person person) {
    if (person.lastCoord != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {

        mapController.move(person.lastCoord!, 16);
      });
    }

    setState(() {
      _checkedBoxes.updateAll((key, value) => false);
      _checkedBoxes[person.name] = true;
    });
  }

  // Move to a person (PersonTile BottomSheet)
  void _clickPanToBottomSheet(Person person, String timestamp) {
    String hr = timestamp.split(':')[0];
    String min = timestamp.split(':')[1];
    setState(() {
      person.lastTimestamp = timestamp;

      _singleCheckedTimestamp[person.name] = timestamp;
      
      _timeTo = TimeOfDay(hour: int.parse(hr), minute: int.parse(min));
      _timeFrom = TimeOfDay(hour: 0, minute: 0);

    });

    _clickPanTo(person);
    _updateToBeDisplayed();

    
    // setState(() {
    //   _dataToBeDrawn.add(drawPoint(person));
    // });
  }

  // refresh button (top right of screen)/(appbar)
  void _updateCurrTime() {
    setState(() {
      _timeTo = TimeOfDay.now();
      dateChosen = DateTime.now();
      _updateData();
      _updateToBeDisplayed();
    });
  }

  // Select all button (bottom of screen)
  void _selectAll() {
    setState(() {
      _isSelectAll = !_isSelectAll;
      if (_isSelectAll) {
        _checkedBoxes.updateAll((key, value) => true);
      } else {
        _checkedBoxes.updateAll((key, value) => false);
      }
    });
    _updateToBeDisplayed();
  }

  // Fullscreen button (on map)
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  // ---===============================

  // Timestamp function ---==============================
  // check if timestamp is in range with from -> to times.
  bool _isTimeInRange(TimeOfDay timestamp, TimeOfDay start, TimeOfDay end) {
    double startTimeDouble = toDouble(start);
    double endTimeDouble = toDouble(end);
    double currTimeDouble = toDouble(timestamp);

    return startTimeDouble <= currTimeDouble && currTimeDouble <= endTimeDouble;
  }

  // check if the the timestamps are less than the current timestamp
  bool _isLessThanCurrTimeStamp(String curr, String other) {
    int currHr = int.parse(curr.split(':')[0]);
    int currMin = int.parse(curr.split(':')[1]);
    int currSec = int.parse(curr.split(':')[2]);
    
    int otherHr = int.parse(other.split(':')[0]);
    int otherMin = int.parse(other.split(':')[1]);
    int otherSec = int.parse(other.split(':')[2]);

    double currTime = currHr + currMin / 60.0 + currSec / 3600.0;
    double otherTime = otherHr + otherMin / 60.0 + otherSec / 3600.0;
    
    return otherTime <= currTime;
    

  }


  // Helper functions ---========================


  // check timestamp by converting to double
  double toDouble(TimeOfDay myTime) => myTime.hour + myTime.minute / 60.0;

  // draw lines/paths
  PolylineLayer drawPolyline(Person person, List<LatLng> coords) {
    return (person.isChecked)
        ? PolylineLayer(polylines: [
            Polyline(
                points: coords,
                color: person.color!,
                borderStrokeWidth: 2,
                strokeWidth: 5)
          ])
        : PolylineLayer(polylines: []);
  }

  // draw marker
  MarkerLayer drawMarker(Person person) {
    return (person.isChecked)
        ? MarkerLayer(markers: [
            Marker(
              point: person.lastCoord!,
              alignment: Alignment.topCenter,
              child: CustomMarkerIcon(person: person),
              height: 100,
              width: 100,
            )
          ])
        : MarkerLayer(markers: []);
  }

  // draw marker
  MarkerLayer drawPoint(Person person) {
    if (person.isChecked) {
      print('isChekced');
    }
    return (person.isChecked)
        ? MarkerLayer(markers: [
            Marker(
              point: person.lastCoord!,
              child: Icon(Icons.person),
              // CustomMarkerIcon(person: person),
              height: 20,
              width: 20,
            )
          ])
        : MarkerLayer(markers: []);
  }

  // convert to alphabets
  String _monthParse(String monthNum) {
    String month = '';
    switch (monthNum) {
      case '1':
        month = 'January';
      case '2':
        month = 'February';
      case '3':
        month = 'March';
      case '4':
        month = 'April';
      case '5':
        month = 'May';
      case '6':
        month = 'June';
      case '7':
        month = 'July';
      case '8':
        month = 'August';
      case '9':
        month = 'September';
      case '10':
        month = 'October';
      case '11':
        month = 'November';
      case '12':
        month = 'December';
    }
    return month;
  }

  Image getImage(String image) {
    Image img;
    try {
      img = Image.asset(
        'assets/$image.png',
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/default.png');
        },
      );
    } catch (e) {
      img = Image.asset('assets/default.png');
    }
    return img;
  }

  // ---===============================

  // Build ---==========================
  @override
  Widget build(BuildContext context) {
    return _isloading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: appBar(context),
            body: Container(
              decoration: BoxDecoration(color: Colors.deepPurple[50]),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    dateDisplay(),
                    map(),
                    searchbar(),
                    cardList(),
                    bottomButtons()
                  ],
                ),
              ),
            ),
          );
  }

  // ---=================================

  // Widgets ---=============================================

  // The App Bar
  AppBar? appBar(BuildContext context) {
    return (!_isFullScreen)
        ? AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_sharp),
                      onPressed: () => {},
                    ),
                    Text(widget.title,
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.restart_alt),
                  onPressed: () => _updateCurrTime(),
                ),
              ],
            )),
          )
        : null;
  }

  // The buttons on the bottom (e.g. Select All)
  SizedBox bottomButtons() {
    return (!_isFullScreen)
        ? SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _selectAll,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select All'),
                      SizedBox(
                        width: 10,
                      ),
                      Icon(Icons.checklist_sharp)
                    ],
                  ),
                ),
              ],
            ))
        : SizedBox();
  }

  // Container of date (includes calendar icon, timepicker (from), timepicker(to))
  Column dateDisplay() {
    return (!_isFullScreen)
        ? Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 50),
                  Spacer(),
                  GestureDetector(
                    onTap: _showDatePicker,
                    child: Row(
                      children: [
                        Text('${dateChosen.day} ',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('${_monthParse(dateChosen.month.toString())} ',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(dateChosen.year.toString(),
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.calendar_month_sharp),
                    onPressed: _showDatePicker,
                  )
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _timePickerFrom,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(20)),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Text("From: ",
                                style: TextStyle(
                                  fontSize: 16,
                                )),
                            Text(
                              // ignore: unnecessary_string_interpolations
                              "${_timeFrom.format(context)}",
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _timePickerTo,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(20)),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Text("To: ", style: TextStyle(fontSize: 16)),
                            Text(
                              _timeTo.format(context),
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          )
        : Column();
  }

  // Person Tiles
  SizedBox cardList() {
    return (!_isFullScreen)
        ? SizedBox(
            height: 160,
            child: _notFound
                ? Center(child: Text('No one found.'))
                : Container(
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _toBeDisplayed.length,
                      itemBuilder: (context, index) {
                        Person karyawan = _toBeDisplayed[index];

                        // update
                        karyawan.timestamps = _combinedData[karyawan.name]!['timestamps'];
                        karyawan.coordinates = _combinedData[karyawan.name]!['coordinates'];
                        
                        return PersonTile(
                          person: karyawan,
                          onCheckboxSelected: (val) => setState(() {
                            _checkedBoxes[karyawan.name] = val!;
                            _updateToBeDisplayed();
                          }),
                          onClickPanTo: (karyawan) => _clickPanTo(karyawan),
                          onClickPanToBottomSheet: (person, timestamp) =>
                              _clickPanToBottomSheet(person, timestamp),
                        );
                      },
                    ),
                  ))
        : SizedBox();
  }

  // Search Bar
  Padding searchbar() {
    return (!_isFullScreen)
        ? Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextField(
              controller: cariKaryawan,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Cari karyawan..',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: _clearButton,
                  )),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(1),
          );
  }

  // Map
  Expanded map() {
    return Expanded(
      flex: 3,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(-6.134326, 106.735743),
              initialZoom: 16,
              minZoom: 0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
                maxZoom: 25,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(-6.134326, 106.735743),
                    width: 25,
                    height: 25,
                    child: FlutterLogo(),
                  ),
                ],
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(-6.134326, 106.735743),
                    radius: 100,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              ..._dataToBeDrawn,
            ],
          ),
          Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.fullscreen),
                onPressed: () {
                  _toggleFullScreen();
                },
                iconSize: 30,
              )),
        ],
      ),
    );
  }
}

// ---================================================
