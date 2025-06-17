import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _pickedLatLng;
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];

  final Color appMainBlue = const Color(0xFFADDDFB);
  final Color primaryColor = const Color(0xFF42A5F5);
  final Color borderColor = const Color(0xFFDDDDDD);

  Future<void> _onSearchChanged(String keyword) async {
    if (keyword.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    final url = Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword');
    final response = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK a6050142a15e2e2ffc660c458f1eb4ff'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        searchResults = (data['documents'] as List)
            .map((e) => {
          'name': e['place_name'],
          'lat': double.parse(e['y']),
          'lng': double.parse(e['x']),
          'address': e['road_address_name'] ?? e['address_name'],
        })
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appMainBlue,
        elevation: 0,
        title: const Text(
          '위치 선택',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            shadows: [
              Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
            ],
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                primaryColor: primaryColor,
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: primaryColor,
                  selectionColor: primaryColor.withOpacity(0.2),
                  selectionHandleColor: primaryColor,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "장소명 또는 주소로 검색",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          if (searchResults.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, idx) {
                  final res = searchResults[idx];
                  return ListTile(
                    title: Text(res['name']),
                    subtitle: Text(res['address']),
                    onTap: () {
                      setState(() {
                        _pickedLatLng = LatLng(res['lat'], res['lng']);
                        _placeNameController.text = res['name'];
                        searchResults = [];
                        _searchController.text = res['name'];
                      });
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(_pickedLatLng!),
                      );
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(35.1796, 129.0756),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _pickedLatLng == null
                  ? {}
                  : {
                Marker(
                  markerId: const MarkerId('picked'),
                  position: _pickedLatLng!,
                  draggable: true,
                  onDragEnd: (newPos) {
                    setState(() => _pickedLatLng = newPos);
                  },
                ),
              },
              onTap: (latLng) {
                setState(() {
                  _pickedLatLng = latLng;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Theme(
              data: Theme.of(context).copyWith(
                primaryColor: primaryColor,
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: primaryColor,
                  selectionColor: primaryColor.withOpacity(0.2),
                  selectionHandleColor: primaryColor,
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _placeNameController,
                    decoration: InputDecoration(
                      labelText: '장소명 입력 (예: 스타벅스 서면점)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_pickedLatLng != null)
                    Text(
                      '선택한 좌표: ${_pickedLatLng!.latitude}, ${_pickedLatLng!.longitude}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('이 위치로 선택'),
                    onPressed: (_pickedLatLng != null &&
                        _placeNameController.text.isNotEmpty)
                        ? () {
                      Navigator.pop(context, {
                        'name': _placeNameController.text,
                        'lat': _pickedLatLng!.latitude,
                        'lng': _pickedLatLng!.longitude,
                        'url':
                        'https://www.google.com/maps/search/?api=1&query=${_pickedLatLng!.latitude},${_pickedLatLng!.longitude}',
                      });
                    }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
