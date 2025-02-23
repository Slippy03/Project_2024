import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapPage extends StatefulWidget {
  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;

  final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.736717, 100.523186),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enable location services")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Location permission is permanently denied")));
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  Future<void> _loadMarkers() async {
    FirebaseFirestore.instance.collection('pins').get().then((snapshot) {
      setState(() {
        _markers = snapshot.docs.map((doc) {
          final data = doc.data();
          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'], data['lng']),
            infoWindow: InfoWindow(
              title: data['title'],
              snippet: data['description'],
            ),
          );
        }).toSet();
      });
    });
  }

  Future<void> _pinCurrentLocation() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fetching current location...")));
      return;
    }

    _showPinDialog(_currentLocation!);
  }

  Future<void> _showPinDialog(LatLng position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please log in first!")));
      return;
    }

    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add a Pin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Location: ${position.latitude}, ${position.longitude}"),
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _addMarker(
                    position, titleController.text, descriptionController.text);
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMarker(
      LatLng position, String title, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newMarker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(title: title, snippet: description),
    );

    await FirebaseFirestore.instance.collection('pins').add({
      'lat': position.latitude,
      'lng': position.longitude,
      'title': title,
      'description': description,
      'username': user.displayName ?? user.email,
    });

    setState(() {
      _markers.add(newMarker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Map with GPS')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            mapType: MapType.normal,
            markers: _markers,
          ),
          Positioned(
            left: 16.0,
            bottom: 80.0,
            child: FloatingActionButton(
              onPressed: _pinCurrentLocation,
              child: Icon(Icons.location_pin, color: Colors.white),
              backgroundColor: Colors.green,
              tooltip: "Pin Current Location",
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: Icon(Icons.my_location, color: Colors.white),
              backgroundColor: Colors.blue,
              tooltip: "Get Current Location",
            ),
          ),
        ],
      ),
    );
  }
}
