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

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(13.736717, 100.523186),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _getCurrentLocation(); // Load GPS automatically when app starts
  }

  // Location related functions
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Location permission is permanently denied")));
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    if (_mapController != null && _currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  void _focusOnMyLocation() {
    if (_currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 16)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Location not available!")));
    }
  }

  // Marker related functions
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
              snippet:
                  'Description: ${data['description']}\nAdded by: ${data['username']}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure), // Custom marker color
            onTap: () {
              _showMarkerDetailDialog(
                  doc.id, data['title'], data['description'], data['username']);
            },
          );
        }).toSet();
      });
    });
  }

  Future<void> _showMarkerDetailDialog(String markerId, String title,
      String description, String username) async {
    TextEditingController commentController = TextEditingController();

    FirebaseFirestore.instance
        .collection('pins')
        .doc(markerId)
        .collection('comments')
        .get()
        .then((snapshot) {
      List comments =
          snapshot.docs.map((doc) => doc['comment']).toList();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Description: $description"),
                  const SizedBox(height: 10),
                  Text("Added by: $username"),
                  const SizedBox(height: 20),
                  const Text("Comments:"),
                  for (var comment in comments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text("- $comment"),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(labelText: "Add a comment"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
              TextButton(
                onPressed: () {
                  _addComment(markerId, commentController.text);
                  Navigator.pop(context);
                },
                child: const Text("Save Comment"),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _addComment(String markerId, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || comment.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('pins')
        .doc(markerId)
        .collection('comments')
        .add({
      'comment': comment,
      'username': user.displayName ?? user.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Pin current location functions
  Future<void> _pinCurrentLocation() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fetching current location...")));
      return;
    }

    _showPinDialog(_currentLocation!);
  }

  Future<void> _showPinDialog(LatLng position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please log in first!")));
      return;
    }

    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add a Pin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Location: ${position.latitude}, ${position.longitude}"),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _addMarker(
                    position, titleController.text, descriptionController.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
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
      infoWindow: InfoWindow(
        title: title,
        snippet: description,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed), // Custom marker color
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
      appBar: AppBar(title: const Text('Google Map with GPS')),
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
            bottom: 140.0,
            child: FloatingActionButton(
              onPressed: _pinCurrentLocation,
              child: const Icon(Icons.location_pin, color: Colors.white),
              backgroundColor: Colors.green,
              tooltip: "Pin Current Location",
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 80.0,
            child: FloatingActionButton(
              onPressed: _focusOnMyLocation,
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
              backgroundColor: Colors.orange,
              tooltip: "Focus on My Location",
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
              backgroundColor: Colors.blue,
              tooltip: "Get Current Location",
            ),
          ),
        ],
      ),
    );
  }
}
