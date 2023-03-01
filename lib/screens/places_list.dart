import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin, pow, sin, pi;

import '../modals/landmark.dart';

class PlacesList extends StatefulWidget {
  const PlacesList({super.key});

  @override
  State<PlacesList> createState() => _PlacesListState();
}

class _PlacesListState extends State<PlacesList> {
  bool _ispopupShown = false;
  final Location location = Location();
  late StreamSubscription subscription;

  static const _nearbyLandmarks = [
    Landmark(title: 'Kothrud', latitude: 18.509890, longitude: 73.807182),
    Landmark(title: 'Lonavala', latitude: 18.7557, longitude: 73.4091),
    Landmark(title: 'Pheonix Mall', latitude: 18.5621, longitude: 73.9167),
    Landmark(title: 'Katraj', latitude: 18.4529, longitude: 73.8652)
  ];

  bool _didUserMoved(originalLat, originalLong, currentLat, currentLong) {
    bool isUserMoved = false;
    //returns distance in meters
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((currentLat - originalLat) * p) / 2 +
        c(originalLat * p) *
            c(currentLat * p) *
            (1 - c((currentLong - originalLong) * p)) /
            2;
    var distance = 12742 * asin(sqrt(a));

    if (distance >= 1) {
      isUserMoved = true;
    } else {
      isUserMoved = false;
    }
    return isUserMoved;
  }

  _checkTimer() {
    //TODO: need to change startShift to desired time for now it has been hardcoded.
    final startShift = DateTime.now();
    final endShift = DateTime.now().add(Duration(hours: 1));
    final currentTime = DateTime.now();

    //Calculation for whether user is in between start and end service.
    if (currentTime.isBefore(endShift) && currentTime.isAfter(startShift)) {
      _getNearbyLandmark();
    }
  }

  _handlePermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _showAlertDialog('Enable location services.');
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _showAlertDialog('Enable location permissions.');
      }
    }
    location.enableBackgroundMode(enable: true);
    _checkTimer();
    return true;
  }

  _getNearbyLandmark() async {
    LocationData lastKnownPosition = await location.getLocation();

    //assign current location to vars for further comparison
    subscription = location.onLocationChanged.listen((LocationData position) {
      var isUserMoved = _didUserMoved(lastKnownPosition.latitude,
          lastKnownPosition.longitude, position.latitude, position.longitude);
      double distanceToNearestLandmark = double.infinity;
      Landmark nearestLandmark = const Landmark(
          title: 'No nearby Landmarks', latitude: 10.12, longitude: 12.10);
      double distance;
      List<Map<String, dynamic>> arrayOfDistance = [];
      // List<Landmark>

//calculating nearby landmark only if user has been  moved
      if (isUserMoved) {
        _nearbyLandmarks.forEach((element) {
          var p = 0.017453292519943295;
          var c = cos;
          var a = 0.5 -
              c((element.latitude - position.latitude!) * p) / 2 +
              c(position.latitude! * p) *
                  c(element.latitude * p) *
                  (1 - c((element.longitude - position.longitude!) * p)) /
                  2;
          var distance = 12742 * asin(sqrt(a));

          print('Distance is: $distance');
          Map<String, dynamic> abc = {
            'name': element.title,
            'distance': distance
          };
          arrayOfDistance.add(abc);
        });
        if (arrayOfDistance.isNotEmpty) {
          arrayOfDistance
              .sort((a, b) => a['distance'].compareTo(b['distance']));
          if (!_ispopupShown) {
            setState(() {
              _showAlertDialog(arrayOfDistance.first['name']);
              isUserMoved = false;
              subscription.cancel();
            });
          }
        }
      }
    });
  }

  _showAlertDialog(placeTitle) {
    _ispopupShown = true;
    Widget okButton = TextButton(
      child: const Text("Okay"),
      onPressed: () {
        Navigator.pop(context);
        _ispopupShown = false;
        subscription.cancel();
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text('You are near $placeTitle'),
      actions: [
        okButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: const Text('Geofencing Alert!'),
                content: Text(('You are near $placeTitle')),
                actions: <CupertinoDialogAction>[
                  CupertinoDialogAction(
                    child: const Text('Okay'),
                    onPressed: () {
                      Navigator.pop(context);
                      _ispopupShown = false;
                    },
                  )
                ],
              )
            : alert;
      },
    );
  }

  @override
  void initState() {
    _handlePermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? Material(
            child: CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Geofencing'),
              ),
              child: ListView.builder(
                  itemCount: _nearbyLandmarks.length,
                  itemBuilder: (context, index) => ListTile(
                        title: Text(_nearbyLandmarks[index].title),
                      )),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Geofencing'),
            ),
            body: ListView.builder(
                itemCount: _nearbyLandmarks.length,
                itemBuilder: (context, index) => ListTile(
                      title: Text(_nearbyLandmarks[index].title),
                    )),
          );
  }
}
