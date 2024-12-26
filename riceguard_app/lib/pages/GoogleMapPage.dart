import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPage extends StatefulWidget {
  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController _mapController;

  
  final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.736717, 100.523186), 
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map Example'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        mapType: MapType.normal, 
        markers: {
          Marker(
            markerId: MarkerId('bangkok'),
            position: LatLng(13.736717, 100.523186),
            infoWindow: InfoWindow(title: "Bangkok"),
          ),
        },
      ),
    );
  }
}
