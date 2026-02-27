import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({Key? key}) : super(key: key);

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  String? _errorMessage;
  double? _currentLat;
  double? _currentLon;
  String? _currentCity;
  String? _currentState;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        if (mounted) {
          setState(() {
            _currentLat = position.latitude;
            _currentLon = position.longitude;
          });

          // Fetch City and State for Biasing
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty && mounted) {
              final place = placemarks.first;
              setState(() {
                _currentCity = place.locality ?? place.subAdministrativeArea;
                _currentState = place.administrativeArea;
              });
              debugPrint('Biasing search for: $_currentCity, $_currentState');
            }
          } catch (e) {
            debugPrint('Error getting city name for biasing: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting location for biasing: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(query);
    });
  }

  Future<void> _searchLocation(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Optimize query for India
    String optimizedQuery = query;
    if (!query.toLowerCase().contains('india')) {
      optimizedQuery = '$query, India';
    }

    try {
      // Step 0: Try Native Geocoder (Google/Apple native data) - HIGH CONFIDENCE
      List<dynamic> nativeResults = [];
      try {
        List<Location> locations = await locationFromAddress(
          query,
        ).timeout(const Duration(seconds: 4));
        if (locations.isNotEmpty) {
          final loc = locations.first;
          List<Placemark> marks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (marks.isNotEmpty) {
            final p = marks.first;
            final addrStr = [
              if (p.name != null && p.name != p.street) p.name,
              p.street,
              p.locality,
              p.administrativeArea,
            ].where((s) => s != null && s.isNotEmpty).join(", ");

            nativeResults.add({
              'isNative': true,
              'lat': loc.latitude,
              'lon': loc.longitude,
              'properties': {
                'name': p.name ?? query,
                'full_address': addrStr,
                'city': p.locality ?? '',
                'state': p.administrativeArea ?? '',
              },
            });
          }
        }
      } catch (e) {
        debugPrint('Native geocoder skipped: $e');
      }

      // Step 0.5: Try LocationIQ API with strict bounding box
      final String iqApiKey = dotenv.env['LOCATIONIQ_API_KEY'] ?? '';
      if (iqApiKey.isNotEmpty && iqApiKey != 'YOUR_FREE_KEY_HERE') {
        String biasedQuery = query;
        if (_currentCity != null && !query.contains(_currentCity!)) {
          biasedQuery = '$query, $_currentCity';
        }

        final Map<String, String> iqParams = {
          'key': iqApiKey,
          'q': biasedQuery,
          'format': 'json',
          'addressdetails': '1',
          'limit': '15',
          'countrycodes': 'in',
        };

        // Apply strict 50km bounding box (viewbox) if coords available
        if (_currentLat != null && _currentLon != null) {
          double offset = 0.5; // Approx 55km
          String viewbox =
              '${_currentLon! - offset},${_currentLat! - offset},${_currentLon! + offset},${_currentLat! + offset}';
          iqParams['viewbox'] = viewbox;
          iqParams['bounded'] = '1';
        }

        final iqUrl = Uri.https('us1.locationiq.com', '/v1/search', iqParams);
        final iqResponse = await http
            .get(iqUrl)
            .timeout(const Duration(seconds: 6));

        if (iqResponse.statusCode == 200) {
          final List<dynamic> iqData = json.decode(iqResponse.body);
          if (iqData.isNotEmpty) {
            final List<dynamic> mapped =
                iqData.map((item) {
                  final address = item['address'] ?? {};
                  return {
                    'isIQ': true,
                    'lat': item['lat'],
                    'lon': item['lon'],
                    'properties': {
                      'name': item['display_name'].split(',')[0],
                      'city':
                          address['city'] ??
                          address['town'] ??
                          address['village'] ??
                          '',
                      'state': address['state'] ?? '',
                      'country': address['country'] ?? '',
                      'full_address': item['display_name'],
                    },
                  };
                }).toList();

            setState(() {
              _searchResults = [...nativeResults, ...mapped];
              _isLoading = false;
            });
            return;
          }
        }
      }

      // Merge native results with other providers if LocationIQ skipped/empty
      if (nativeResults.isNotEmpty) {
        setState(() {
          _searchResults = nativeResults;
        });
        // Continue to fetch more results to fill the list
      }

      // Step 1: Try Photon API (Komoot)
      // Enhance optimizedQuery with city context for Photon too
      if (_currentCity != null && !optimizedQuery.contains(_currentCity!)) {
        optimizedQuery = '$query, $_currentCity, India';
      }
      final Map<String, String> photonParams = {
        'q': optimizedQuery,
        'limit': '15',
      };
      if (_currentLat != null && _currentLon != null) {
        photonParams['lat'] = _currentLat!.toString();
        photonParams['lon'] = _currentLon!.toString();
      }

      final photonUrl = Uri.https('photon.komoot.io', '/api', photonParams);
      final photonResponse = await http
          .get(
            photonUrl,
            headers: {
              'User-Agent': 'LabourApp/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (photonResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(photonResponse.body);
        final List<dynamic> features = data['features'] ?? [];

        // Filter: India only and prioritize based on Photon's native ranking
        final indianResults =
            features.where((f) {
              final props = f['properties'] ?? {};
              final countryCode =
                  (props['countrycode'] ?? '').toString().toUpperCase();
              final country = (props['country'] ?? '').toString().toLowerCase();
              return countryCode == 'IN' || country == 'india';
            }).toList();

        if (indianResults.isNotEmpty) {
          setState(() {
            // Include native results at the top if they exist
            final native = _searchResults.where((r) => r['isNative'] == true);
            _searchResults = [...native, ...indianResults];
            _isLoading = false;
          });
          return;
        }
      }

      // Step 2: Fallback to Nominatim if Photon fails or has no Indian results
      final nominatimUrl = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': optimizedQuery,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'countrycodes': 'in',
      });

      final nomResponse = await http
          .get(nominatimUrl, headers: {'User-Agent': 'LabourApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (nomResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(nomResponse.body);
        final List<dynamic> mappedNom =
            data
                .map(
                  (item) => {
                    'properties': {
                      'name':
                          item['name'] ?? item['display_name'].split(',')[0],
                      'city':
                          item['address']['city'] ??
                          item['address']['town'] ??
                          item['address']['village'],
                      'state': item['address']['state'],
                      'country': item['address']['country'],
                      'countrycode': 'IN',
                    },
                  },
                )
                .toList();

        setState(() {
          final native = _searchResults.where((r) => r['isNative'] == true);
          _searchResults = [...native, ...mappedNom];
          _isLoading = false;
          if (_searchResults.isEmpty) {
            _errorMessage = 'No results found in India for "$query"';
          }
        });
      } else {
        throw Exception('Service error (Code: ${nomResponse.statusCode})');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Search unavailable. Please check your connection.';
        debugPrint('Search error: $e');
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enter Location',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Box
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search city, area, or street',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon:
                      _isLoading
                          ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            ),
                          )
                          : IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Current Location Option
            GestureDetector(
              onTap: () async {
                setState(() => _isLoading = true);
                try {
                  Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );

                  // Reverse Geocoding
                  List<Placemark> placemarks = await placemarkFromCoordinates(
                    position.latitude,
                    position.longitude,
                  );

                  String address = "Current Location";
                  if (placemarks.isNotEmpty) {
                    final p = placemarks.first;
                    final components = [
                      if (p.street != null && p.street!.isNotEmpty) p.street,
                      if (p.locality != null && p.locality!.isNotEmpty)
                        p.locality,
                      if (p.subAdministrativeArea != null &&
                          p.subAdministrativeArea!.isNotEmpty)
                        p.subAdministrativeArea,
                      if (p.administrativeArea != null &&
                          p.administrativeArea!.isNotEmpty)
                        p.administrativeArea,
                    ];
                    address = components.join(", ");
                  }

                  if (mounted) {
                    Navigator.pop(context, {
                      'address': address,
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                    });
                  }
                } catch (e) {
                  debugPrint('Error in reverse geocoding: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to resolve address: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Use my current location',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

            // Results List
            Expanded(
              child: ListView.separated(
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final feature = _searchResults[index];
                  final props = feature['properties'] ?? {};

                  // Format address components from Photon response
                  final name = props['name'] ?? 'Unknown';
                  final city = props['city'];
                  final state = props['state'];
                  final country = props['country'];

                  // Build a descriptive address string
                  final addressComponents = [
                    if (city != null && city != name) city,
                    if (state != null) state,
                    if (country != null && country != 'India') country,
                  ];
                  final subtitle = addressComponents.join(', ');

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey,
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      if (feature['isNative'] == true ||
                          feature['isIQ'] == true) {
                        Navigator.pop(context, {
                          'address': props['full_address'],
                          'latitude': double.tryParse(
                            feature['lat'].toString(),
                          ),
                          'longitude': double.tryParse(
                            feature['lon'].toString(),
                          ),
                        });
                      } else {
                        final fullAddress =
                            subtitle.isNotEmpty ? "$name, $subtitle" : name;

                        // For Photon/Nominatim, we might need to fetch coordinates if not provided
                        double? lat = double.tryParse(
                          feature['lat']?.toString() ?? '',
                        );
                        double? lon = double.tryParse(
                          feature['lon']?.toString() ?? '',
                        );

                        // Photon stores coords in feature['geometry']['coordinates'] as [lon, lat]
                        if (feature['geometry'] != null &&
                            feature['geometry']['coordinates'] != null) {
                          List<dynamic> coords =
                              feature['geometry']['coordinates'];
                          if (coords.length >= 2) {
                            lon = double.tryParse(coords[0].toString());
                            lat = double.tryParse(coords[1].toString());
                          }
                        }

                        Navigator.pop(context, {
                          'address': fullAddress,
                          'latitude': lat,
                          'longitude': lon,
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
