// // This is just a test file

// import 'dart:async';
// import 'package:location/location.dart';
// import "package:google_maps_flutter/google_maps_flutter.dart";
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';

// import 'package:flutter/material.dart';

// const GOOGLE_MAPS_API_KEY = "AIzaSyDmToh-xq4nhfUAaz6dpYl9IylWNWJMCMI";

// class MapPage extends StatefulWidget {
//   const MapPage({super.key});

//   @override
//   State<MapPage> createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   Location _locationController = new Location();

//   final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

//   static const LatLng _pGooglePlex = LatLng(37.7749, -122.4194); // Example coordinates
//   static const LatLng _pApplePark = LatLng(38.3318, -122.0312); // Example coordinates
//   LatLng? _currentP = null;

//   Map<PolylineId, Polyline> polylines = {}; 

//   @override
//   void initState() {
//     super.initState();
//     getLocationUpdates().then((value) => {
//       getPolyLinePoints().then((coordinates) => {
//         generatePolyineFromPoints(coordinates)
//       }),
//     },);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _currentP == null ? const Center(child: Text("Loading..."),) : GoogleMap(
//         onMapCreated: ((GoogleMapController controller) => _mapController.complete(controller)),
//         initialCameraPosition: CameraPosition(
//           target: _pGooglePlex,
//           zoom: 13,
//         ),
//         markers: {
//           Marker(
//             markerId: MarkerId("_scurrentLocation"),
//             icon: BitmapDescriptor.defaultMarker,
//             position: _currentP!,
//           ),
//           Marker(
//             markerId: MarkerId("_sourceLocation"),
//             icon: BitmapDescriptor.defaultMarker,
//             position: _pGooglePlex,
//           ),
//           Marker(
//             markerId: MarkerId("_destinationLocation"),
//             icon: BitmapDescriptor.defaultMarker,
//             position: _pApplePark,
//           ),
//         },
//         polylines: Set<Polyline>.of(polylines.values),
//       ),
//     );
//   }

//   Future<void> _cameraToPosition(LatLng pos) async {
//     final GoogleMapController controller = await _mapController.future;
//     CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 13);
//     await controller.animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition),);
//   }
  
//   Future<void> getLocationUpdates() async {
//     bool _serviceEnabled;
//     PermissionStatus _permissionGranted;

//     _serviceEnabled = await _locationController.serviceEnabled();
//     if (!_serviceEnabled) {
//       _serviceEnabled = await _locationController.requestService();
//     }if (!_serviceEnabled) {
//       return;
//     }

//     _permissionGranted = await _locationController.hasPermission();
//     if (_permissionGranted == PermissionStatus.denied) {
//       _permissionGranted = await _locationController.requestPermission();
//       if (_permissionGranted != PermissionStatus.granted) {
//         return;
//       }
//     }

//     _locationController.onLocationChanged.listen((LocationData currentLocation) {
//       if (currentLocation.latitude != null && currentLocation.longitude != null) {
//         setState(() {
//           _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
//           _cameraToPosition(_currentP!);
//         });
//       }
//     });
//   }

//   Future<List<LatLng>> getPolyLinePoints() async {
//     List<LatLng> polylineCoordinates = [];
//     PolylinePoints polylinePoints = PolylinePoints();

//     // changed here. If an error check this line
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       request: PolylineRequest(
//         origin: PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
//         destination: PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
//         mode: TravelMode.driving,
//       ),
//       googleApiKey: GOOGLE_MAPS_API_KEY,
//     );
//     if (result.points.isNotEmpty) {
//       for (PointLatLng point in result.points) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       }
//     } else {
//       print(result.errorMessage);
//     }
//     return polylineCoordinates;
//   }

//   void generatePolyineFromPoints(List<LatLng> polylineCoordinates) async {
//     PolylineId id = PolylineId("poly");
//     Polyline polyline = Polyline(
//       polylineId:id, 
//       color: Colors.black, 
//       points: polylineCoordinates, 
//       width: 8);
//     setState(() {
//       polylines[id] = polyline;
//     });
//   }
// }