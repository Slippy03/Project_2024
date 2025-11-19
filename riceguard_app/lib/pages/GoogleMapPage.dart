import 'dart:io';
import 'package:intl/intl.dart';
import 'package:riceguard_app/pages/forumview.dart';
import 'package:http/http.dart' as http;
import 'forumform.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class GoogleMapPage extends StatefulWidget {
  final String? initialPinId;

  const GoogleMapPage({this.initialPinId, Key? key}) : super(key: key);

  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;
  String? _lastTappedMarkerId;
  bool _dialogOpen = false;
  bool _hasReceivedArguments = false;
  bool _hasLoadedMarkers = false;

  final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.736717, 100.523186),
    zoom: 10,
  );

  String? description;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasReceivedArguments) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args != null) {
        if (args is Map<String, dynamic>) {
          description = args['description'];
          imageUrl = args['imageUrl'];

          final pinId = args['pinId'] as String?;
          if (!_hasLoadedMarkers && pinId != null) {
            _loadMarkers();
            _hasLoadedMarkers = true;
          }

          final hasDescription = description != null && description!.isNotEmpty;
          final hasImageUrl = imageUrl != null && imageUrl!.isNotEmpty;

          if (hasDescription && hasImageUrl) {
            _getCurrentLocation().then((_) {
              if (_currentLocation != null) {
                _showPinDialog(
                  _currentLocation!,
                  initialDescription: description,
                  initialImageUrl: imageUrl,
                );
              }
            });
          }
        } else if (args is String) {
          final pinId = args;
          if (!_hasLoadedMarkers && pinId.isNotEmpty) {
            _loadMarkers();
            _hasLoadedMarkers = true;
          }
        }
      }

      _hasReceivedArguments = true;
    }
  }

  Future<XFile?> _downloadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/downloaded_image.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return XFile(file.path);
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  Future<void> _moveToCoordinates(String latitude, String longitude) async {
    final lat = double.tryParse(latitude);
    final lng = double.tryParse(longitude);

    if (lat != null && lng != null) {
      LatLng targetPosition = LatLng(lat, lng);
      _mapController.animateCamera(
        CameraUpdate.newLatLng(targetPosition),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Moved to the coordinates")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid coordinates")));
    }
  }

  Future<void> _showCoordinateDialog() async {
    TextEditingController latitudeController = TextEditingController();
    TextEditingController longitudeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // ปรับมุมของ dialog ให้มน
          ),
          title: Text(
            "Enter Coordinates",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent, // ใช้สีที่สะดุดตา
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: latitudeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Latitude",
                    labelStyle:
                        TextStyle(color: Colors.blueAccent), // เปลี่ยนสี Label
                    prefixIcon: Icon(Icons.location_on,
                        color: Colors.blueAccent), // ไอคอนแสดงพิกัด
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // ปรับขอบให้มน
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: longitudeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Longitude",
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    prefixIcon:
                        Icon(Icons.location_on, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.redAccent, // ใช้สีแดงสำหรับปุ่ม Cancel
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _moveToCoordinates(
                  latitudeController.text,
                  longitudeController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // ปรับสีปุ่ม Move
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Move",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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

    if (_mapController != null && _currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  Future<void> _loadMarkers() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('pins').get();

      Set<Marker> markers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'], data['lng']),
            infoWindow: InfoWindow(title: data['title']),
            onTap: () async {
              if (_lastTappedMarkerId == doc.id) {
                if (!_dialogOpen) {
                  _dialogOpen = true; // ป้องกันเปิดซ้อน
                  await _showMarkerDetailDialog(
                    doc.id,
                    data['title'],
                    data['description'],
                    data['username'],
                  );
                  _dialogOpen = false;
                }
              } else {
                _mapController.showMarkerInfoWindow(MarkerId(doc.id));
                setState(() {
                  _lastTappedMarkerId = doc.id;
                });
              }
            });
      }).toSet();

      setState(() {
        _markers = markers;
      });

      // ✅ Focus and show InfoWindow if initialPinId exists
      if (widget.initialPinId != null) {
        QueryDocumentSnapshot? pinDoc;
        try {
          pinDoc =
              snapshot.docs.firstWhere((doc) => doc.id == widget.initialPinId);
        } catch (_) {
          pinDoc = null;
        }

        if (pinDoc != null) {
          final data = pinDoc.data() as Map<String, dynamic>;
          final LatLng position = LatLng(data['lat'], data['lng']);
          await Future.delayed(Duration(milliseconds: 500));
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(position, 16),
          );

          await Future.delayed(Duration(milliseconds: 300));
          _mapController.showMarkerInfoWindow(MarkerId(pinDoc.id));

          setState(() {
            _lastTappedMarkerId = pinDoc!.id;
          });
        }
      }
    } catch (e) {
      print("Error loading markers: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลด pin")),
      );
    }
  }

  Future<String> _getUsernameFromFirestore(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return userDoc['username'] ?? 'Anonymous';
    } catch (e) {
      print('Error fetching username: $e');
      return 'Anonymous';
    }
  }

  Future<void> _showMarkerDetailDialog(
    String markerId,
    String title,
    String description,
    String username,
  ) async {
    final doc =
        await FirebaseFirestore.instance.collection('pins').doc(markerId).get();
    final data = doc.data();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ไม่พบข้อมูลหมุดนี้"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Marker? marker;
    try {
      marker = _markers.firstWhere((m) => m.markerId.value == markerId);
    } catch (_) {
      marker = null;
    }

    if (marker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ไม่พบหมุดบนแผนที่"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool isFavorited = false;
    if (uid != null) {
      final favDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(markerId)
          .get();
      isFavorited = favDoc.exists;
    }

    String status = data['status'] ?? 'Unknown';
    IconData statusIcon = Icons.help_outline;
    Color statusColor = Colors.grey;

    if (status.contains('🧬')) {
      statusIcon = Icons.bug_report_outlined;
      statusColor = Colors.deepPurple;
    } else if (status.contains('💊')) {
      statusIcon = Icons.medication_outlined;
      statusColor = Colors.orange;
    } else if (status.contains('✅')) {
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
    } else if (status.contains('⚠️')) {
      statusIcon = Icons.warning_amber_outlined;
      statusColor = Colors.redAccent;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: EdgeInsets.fromLTRB(20, 20, 10, 0),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: EdgeInsets.only(right: 10, bottom: 10),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Tooltip(
                        message: isFavorited
                            ? "remove from favorites"
                            : "add to favorites",
                        child: IconButton(
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited
                                ? Colors.redAccent
                                : Colors.grey[500],
                            size: 24,
                          ),
                          onPressed: () async {
                            if (uid == null) return;
                            final favRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('favorites')
                                .doc(markerId);

                            if (isFavorited) {
                              await favRef.delete();
                            } else {
                              await favRef.set({
                                'favoritedAt': FieldValue.serverTimestamp(),
                                'title': title,
                                'createdBy': username,
                                'lat': marker!.position.latitude,
                                'lng': marker.position.longitude,
                              });
                            }

                            setState(() {
                              isFavorited = !isFavorited;
                            });
                          },
                        ),
                      ),
                      Tooltip(
                        message: "สร้างกระทู้จากหมุดนี้",
                        child: IconButton(
                          icon: Icon(Icons.forum,
                              color: Colors.indigo[600], size: 24),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForumFormPage(
                                  initialTitle: title,
                                  initialContent:
                                      "$description\n\n[Status: $status]",
                                  pinId: markerId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['imageUrl'] != null &&
                        (data['imageUrl'] as String).isNotEmpty)
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              spreadRadius: 2,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description,
                            size: 20, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Description:\n",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text: description,
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Pin by: ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: username,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(statusIcon, size: 20, color: statusColor),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Status: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text: status,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Pin forum",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('forums')
                          .where('pinId', isEqualTo: markerId)
                          .get(),
                      builder: (context, forumSnapshot) {
                        if (forumSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!forumSnapshot.hasData ||
                            forumSnapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.forum_outlined, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "No forum about this pin",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final forumDocs = forumSnapshot.data!.docs;
                        return Column(
                          children: forumDocs.map((doc) {
                            final forumData =
                                doc.data() as Map<String, dynamic>;
                            final title = forumData['title'] ?? 'No Title';
                            final username = forumData['username'] ?? 'Unknown';

                            // ใช้ timestamp จาก Firestore
                            final createdAt =
                                (forumData['timestamp'] as Timestamp?)
                                    ?.toDate();
                            final formattedDate = createdAt != null
                                ? DateFormat('d MMM yyyy')
                                    .format(createdAt) // e.g. 2 Apr 2025
                                : '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ForumViewPage(),
                                        settings:
                                            RouteSettings(arguments: doc.id),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              Colors.indigo.withOpacity(0.1),
                                          child: Icon(Icons.forum,
                                              color: Colors.indigo, size: 20),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'by $username${formattedDate.isNotEmpty ? ' - $formattedDate' : ''}',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: Colors.grey[700],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right,
                                            color: Colors.grey[500]),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.redAccent),
                  label: Text(
                    "close",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showFavoritePins() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // เช็คว่า _currentLocation มีค่าหรือยัง ถ้าไม่มีให้เรียก _getCurrentLocation
    if (_currentLocation == null) {
      await _getCurrentLocation();
      // ถ้า _currentLocation ยังเป็น null หลังจากเรียก _getCurrentLocation, แสดงข้อความเตือน
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to get current location.")),
        );
        return;
      }
    }

    // ถ้า _currentLocation มีค่าแล้ว ให้ทำการโหลดข้อมูล favorite
    try {
      final current = _currentLocation!;
      QuerySnapshot favSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      List<Map<String, dynamic>> favoritePins = [];

      for (var doc in favSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('lat') && data.containsKey('lng')) {
          final double distanceInMeters = Geolocator.distanceBetween(
            current.latitude,
            current.longitude,
            data['lat'],
            data['lng'],
          );

          favoritePins.add({
            'title': data['title'],
            'description': data['description'],
            'user': data['createdBy'],
            'lat': data['lat'],
            'lng': data['lng'],
            'distance': (distanceInMeters / 1000).toStringAsFixed(2),
          });
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "❤️ Favorite Pins",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            content: favoritePins.isEmpty
                ? Text("You have no favorite pins.")
                : Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: favoritePins.length,
                      itemBuilder: (context, index) {
                        final pin = favoritePins[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _mapController.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(pin['lat'], pin['lng']),
                                  zoom: 16.0,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "🏷️ ${pin['title']}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text("👤 Pinned by: ${pin['user']}"),
                                  Text("📍 (${pin['lat']}, ${pin['lng']})"),
                                  Text("📏 ${pin['distance']} km away"),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.redAccent, // ใช้สีแดงสำหรับปุ่ม Close
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  Future<void> _showMyPins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_currentLocation == null) {
      await _getCurrentLocation();
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to get current location.")),
        );
        return;
      }
    }

    try {
      final current =
          _currentLocation!; // ใช้ _currentLocation ที่ได้รับการตั้งค่าแล้ว
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pins')
          .where('uid', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> myPins = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final double distanceInMeters = Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          data['lat'],
          data['lng'],
        );

        myPins.add({
          'id': doc.id,
          'title': data['title'],
          'description': data['description'],
          'user': data['username'],
          'lat': data['lat'],
          'lng': data['lng'],
          'distance': (distanceInMeters / 1000).toStringAsFixed(2),
        });
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  "\ud83d\udccc My Pins",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                content: myPins.isEmpty
                    ? Text("You haven't created any pins.")
                    : Container(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: myPins.length,
                          itemBuilder: (context, index) {
                            final pin = myPins[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              child: ListTile(
                                title: Text("\ud83c\udff7️ ${pin['title']}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "\ud83d\udc64 Pinned by: ${pin['user']}"),
                                    Text(
                                        "\ud83d\udccd (${pin['lat']}, ${pin['lng']})"),
                                    Text(
                                        "\ud83d\udccd ${pin['distance']} km away"),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _mapController.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(pin['lat'], pin['lng']),
                                        zoom: 16.0,
                                      ),
                                    ),
                                  );
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _editPin(pin['id'], pin['title'],
                                          pin['description'],
                                          (newTitle, newDesc) {
                                        setState(() {
                                          myPins[index]['title'] = newTitle;
                                          myPins[index]['description'] =
                                              newDesc;
                                        });
                                      });
                                    } else if (value == 'delete') {
                                      await _deletePin(pin['id']);
                                      setState(() {
                                        myPins.removeAt(index);
                                      });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors.redAccent),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print("Error loading user's pins: $e");
    }
  }

  Future<void> _deletePin(String pinId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please log in first!")),
      );
      return;
    }

    try {
      // ลบ Pin จาก `pins` collection
      await FirebaseFirestore.instance.collection('pins').doc(pinId).delete();

      // ลบ Pin จาก `favorites` ของทุกผู้ใช้
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        final favRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('favorites')
            .doc(pinId);

        // ลบ Pin ที่อยู่ใน favorites ของผู้ใช้
        await favRef.delete();
      }

      final pinDoc =
          await FirebaseFirestore.instance.collection('pins').doc(pinId).get();
      if (pinDoc.exists && pinDoc.data()?['imageUrl'] != null) {
        await FirebaseFirestore.instance.collection('pins').doc(pinId).update({
          'imageUrl': FieldValue.delete(),
        });
      }

      setState(() {
        _loadMarkers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pin deleted successfully!")),
      );
    } catch (e) {
      print("Error deleting pin: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting pin.")),
      );
    }
  }

  Future<void> _editPin(
    String pinId,
    String oldTitle,
    String oldDescription,
    Function(String, String) onUpdate,
  ) async {
    TextEditingController titleController =
        TextEditingController(text: oldTitle);
    TextEditingController descController =
        TextEditingController(text: oldDescription);
    XFile? selectedImage;
    String selectedStatus = '🧬 Disease recently discovered';

    final List<String> statusOptions = [
      '🧬 Disease recently discovered',
      '💊 Treating disease',
      '✅ Successfully cured disease',
      '⚠️ Still encountering disease',
    ];

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Center(
                child: Text(
                  'Edit Pin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Title',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: TextField(
                          controller: descController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Description',
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: "Status",
                            border: InputBorder.none,
                          ),
                          items: statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(selectedImage!.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() {
                            selectedImage = picked;
                          });
                        }
                      },
                      icon: Icon(Icons.image_outlined),
                      label: Text('Choose Image'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() {
                            isSaving = true;
                          });

                          Map<String, dynamic> updateData = {
                            'title': titleController.text,
                            'description': descController.text,
                            'status': selectedStatus,
                            'lastUpdated': FieldValue
                                .serverTimestamp(), // ✅ บันทึกเวลาที่แก้ไขล่าสุด
                          };

                          if (selectedImage != null) {
                            final ref = FirebaseStorage.instance
                                .ref()
                                .child('pin_images')
                                .child(pinId)
                                .child('pin_image.jpg');

                            await ref.putFile(File(selectedImage!.path));
                            String imageUrl = await ref.getDownloadURL();
                            updateData['imageUrl'] = imageUrl;
                          }

                          await FirebaseFirestore.instance
                              .collection('pins')
                              .doc(pinId)
                              .update(updateData);

                          onUpdate(titleController.text, descController.text);
                          await _loadMarkers();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Pin updated successfully!")),
                          );
                        },
                  child: isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pinCurrentLocation() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fetching current location...")),
      );
      return;
    }

    _showPinDialog(_currentLocation!);
  }

  Future<void> _showPinDialog(
    LatLng position, {
    String? initialTitle,
    String? initialDescription,
    String? initialImageUrl,
  }) async {
    TextEditingController titleController =
        TextEditingController(text: initialTitle ?? '');
    TextEditingController descriptionController =
        TextEditingController(text: initialDescription ?? '');

    XFile? selectedImage;
    String selectedStatus = '🧬 Disease recently discovered';

    final List<String> statusOptions = [
      '🧬 Disease recently discovered',
      '💊 Treating disease',
      '✅ Successfully cured disease',
      '⚠️ Still encountering disease',
    ];

    // 🔽 หากมี imageUrl ให้แปลงเป็น XFile
    if (initialImageUrl != null) {
      selectedImage = await _downloadImageFromUrl(initialImageUrl);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              contentPadding: EdgeInsets.all(20),
              title: Text(
                "📍 Add a New Pin",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Latitude: ${position.latitude.toStringAsFixed(5)}"),
                    Text("Longitude: ${position.longitude.toStringAsFixed(5)}"),
                    SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Description",
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: "Status",
                          prefixIcon: Icon(Icons.local_hospital),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // 🔽 แสดงภาพถ้ามี selectedImage แล้ว
                    if (selectedImage != null)
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(selectedImage!.path),
                              fit: BoxFit.cover),
                        ),
                      ),

                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() {
                            selectedImage = picked;
                          });
                        }
                      },
                      icon: Icon(Icons.image_outlined),
                      label: Text("Choose Image"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.cancel, color: Colors.red),
                  label: Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _addMarker(
                      position,
                      titleController.text,
                      descriptionController.text,
                      selectedImage,
                      selectedStatus,
                    );
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.save),
                  label: Text("Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addMarker(
    LatLng position,
    String title,
    String description,
    XFile? imageFile,
    String status,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      DocumentReference pinRef =
          FirebaseFirestore.instance.collection('pins').doc();
      String pinId = pinRef.id;

      String? imageUrl;

      if (imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('pin_images')
            .child(pinId)
            .child('pin_image.jpg');

        await ref.putFile(File(imageFile.path));
        imageUrl = await ref.getDownloadURL();
      }

      final now = Timestamp.now();

      await pinRef.set({
        'lat': position.latitude,
        'lng': position.longitude,
        'title': title,
        'description': description,
        'uid': user.uid,
        'username': userDoc['username'],
        'imageUrl': imageUrl,
        'status': status,
        'createdAt': now,
        'lastUpdated': now,
      });

      await _loadMarkers();
    } catch (e) {
      print('Error adding marker: $e');
    }
  }

  Future<void> _showNearbyPins() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Current location not available")),
      );
      return;
    }

    final current = _currentLocation!;
    const double maxDistanceInKm = 10.0;

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('pins').get();

      List<Map<String, dynamic>> nearbyPins = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final LatLng pinPosition = LatLng(data['lat'], data['lng']);

        double distanceInMeters = Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          pinPosition.latitude,
          pinPosition.longitude,
        );

        if (distanceInMeters <= maxDistanceInKm * 1000) {
          nearbyPins.add({
            'title': data['title'],
            'user': data['username'],
            'lat': data['lat'],
            'lng': data['lng'],
            'distance': (distanceInMeters / 1000).toStringAsFixed(2),
          });
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20), // ปรับมุมของ dialog ให้มน
            ),
            title: Text(
              "Nearby Pins (within $maxDistanceInKm km)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            content: nearbyPins.isEmpty
                ? Text("No nearby pins found.")
                : Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: nearbyPins.length,
                      itemBuilder: (context, index) {
                        final pin = nearbyPins[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);

                            _mapController.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(pin['lat'], pin['lng']),
                                  zoom: 16.0,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // ปรับมุมให้มน
                            ),
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "🏷️ ${pin['title']}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text("👤 Pinned by: ${pin['user']}"),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.blueAccent, size: 18),
                                      SizedBox(width: 4),
                                      Text("📍 (${pin['lat']}, ${pin['lng']})"),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text("📏 ${pin['distance']} km away"),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.redAccent, // ใช้สีแดงสำหรับปุ่ม Close
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error loading nearby pins: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map with GPS'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _loadMarkers();
            },
            mapType: MapType.normal,
            markers: _markers,
            onTap: (LatLng position) {
              if (_lastTappedMarkerId != null) {
                _mapController
                    .hideMarkerInfoWindow(MarkerId(_lastTappedMarkerId!));
              }
              setState(() {
                _lastTappedMarkerId = null;
                _dialogOpen = false;
              });
            },
          ),
          Positioned(
            right: 16.0,
            bottom: 175.0,
            child: FloatingActionButton(
              onPressed: _showFavoritePins,
              backgroundColor: Colors.pink,
              tooltip: "Favorite Pins",
              child: Icon(Icons.favorite, color: Colors.white),
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 110.0,
            child: FloatingActionButton(
              onPressed: _showMyPins,
              backgroundColor: Colors.purple,
              tooltip: "My Pins",
              child: Icon(Icons.person_pin, color: Colors.white),
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 30.0,
            child: FloatingActionButton(
              onPressed: _pinCurrentLocation,
              backgroundColor: Colors.green,
              tooltip: "Pin Current Location",
              child: Icon(Icons.location_pin, color: Colors.white),
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 95.0,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.blue,
              tooltip: "Get Current Location",
              child: Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 160.0,
            child: FloatingActionButton(
              onPressed: _showNearbyPins,
              backgroundColor: Colors.orange,
              tooltip: "Nearby Pins",
              child: Icon(Icons.list_alt, color: Colors.white),
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 225.0, // Position the button below the existing ones
            child: FloatingActionButton(
              onPressed:
                  _showCoordinateDialog, // Show the input form for coordinates
              backgroundColor: Colors.teal,
              tooltip: "Move to Coordinates",
              child:
                  Icon(Icons.search, color: Colors.white), // Using search icon
            ),
          ),
        ],
      ),
    );
  }
}
