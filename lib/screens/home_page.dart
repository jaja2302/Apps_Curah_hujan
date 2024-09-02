// import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'introduction_screen.dart'; // Adjust the import based on your file structure
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart'; // Import this
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import for http requests
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/models.dart'; // Import your History model
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File class
import 'package:http_parser/http_parser.dart';
import 'dart:async';

void main() async {
  // Ensure that plugin services are initialized so that Hive can use them
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters if you have any custom types
  Hive.registerAdapter(HistoryAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const HistoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        items: const [
          TabItem(icon: Icons.home, title: 'Dashboard'),
          TabItem(icon: Icons.history, title: 'History'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class DataCache {
  static final DataCache _instance = DataCache._internal();
  factory DataCache() => _instance;
  DataCache._internal();

  List<dynamic> _regions = [];
  Box<History>? _historyBox;

  List<dynamic> get regions => _regions;
  void clearCache() {
    _regions = [];
  }

  Future<void> fetchData() async {
    if (_regions.isEmpty) {
      final response = await http.get(Uri.parse(
          'https://management.srs-ssms.com/api/get_data_main?email=j&password=j'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _regions = data;
      } else {
        throw Exception('Failed to load data');
      }
    }
  }

  Future<void> loadSubmittedData() async {
    if (!Hive.isBoxOpen('historyBox')) {
      _historyBox = await Hive.openBox<History>('historyBox');
    } else {
      _historyBox = Hive.box<History>('historyBox');
    }
  }

  Future<void> addData(Map<String, dynamic> data) async {
    if (_historyBox == null) await loadSubmittedData();

    final history = History(
      afd: data['afd'],
      est: data['est'],
      ch: data['ch'],
      afdId: data['afd_id'],
      estId: data['est_id'],
    );
    await _historyBox?.add(history);
  }

  List<History> getData() {
    if (_historyBox == null) return [];
    return _historyBox?.values.toList() ?? [];
  }

  Future<void> clearData() async {
    if (_historyBox == null) await loadSubmittedData();
    await _historyBox?.clear();
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

late MapController _mapController;
late StreamSubscription<Position> _positionStreamSubscription;

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  List<EstatePlot> _selectedEstatePlots = [];
  List<Ombrocoordinat> _selectedOmbrocoordinats = [];
  bool _isSubmitButtonEnabled = false;

  List<dynamic> _regions = [];
  List<dynamic> _wilayahs = [];
  List<dynamic> _estates = [];
  List<dynamic> _afdelings = [];
  double _currentLat = 0.0;
  double _currentLon = 0.0;

  String locationMessage = "Fetching location...";
  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLocationPermission();
    _mapController = MapController();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentLat = position.latitude;
        _currentLon = position.longitude;
        _updateDistanceToOmbro();
      });
    });
  }

  void _updateDistanceToOmbro() {
    if (_selectedOmbrocoordinats.isNotEmpty) {
      LatLng currentLocation = LatLng(_currentLat, _currentLon);
      LatLng ombroLocation = LatLng(
          _selectedOmbrocoordinats.last.lat, _selectedOmbrocoordinats.last.lon);
      double distanceInMeters =
          calculateDistance(currentLocation, ombroLocation);
      _isSubmitButtonEnabled = distanceInMeters <= 25.0;
    }
  }

  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    var controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Show a dialog or a message to the user explaining the need for location access
      _showPermissionDeniedMessage();
    } else if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, handle appropriately
      _showPermissionPermanentlyDeniedMessage();
    } else {
      _initializeLocation();
    }
  }

  void _initializeLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      _currentLat = position.latitude;
      _currentLon = position.longitude;

      setState(() {
        LatLng currentLocation = LatLng(_currentLat, _currentLon);
        LatLng lastPlotLocation = _selectedEstatePlots.isNotEmpty
            ? LatLng(
                _selectedEstatePlots.last.lat, _selectedEstatePlots.last.lon)
            : const LatLng(0, 0); // Default location if no plot is selected

        double distanceInKm =
            calculateDistance(currentLocation, lastPlotLocation);
        _isSubmitButtonEnabled =
            distanceInKm <= 10.0; // Disable button if more than 1 km
      });
    } catch (e) {
      // Handle location fetching error (e.g., user turned off location services)
      if (kDebugMode) {
        print("Failed to get location: $e");
      }
    }
  }

  void _showPermissionDeniedMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'This app requires location access to function properly. Please grant location permission in your device settings.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Permanently Denied'),
          content: const Text(
              'Location access has been permanently denied. Please enable location permission manually in your device settings.'),
          actions: [
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadData() async {
    // Clear the cache before fetching new data
    DataCache().clearCache();
    await DataCache().fetchData();
    setState(() {
      _regions = DataCache().regions;
      _wilayahs = [];
      _estates = [];
      _afdelings = [];
    });
  }

  void _resetFormAndFetchData() async {
    _formKey.currentState?.reset();

    setState(() {
      _regions = [];
      _wilayahs = [];
      _estates = [];
      _afdelings = [];
      _selectedEstatePlots = [];
      _selectedOmbrocoordinats = [];
    });

    await _loadData();

    setState(() {
      // Explicitly set all dropdown values to null
      _formKey.currentState?.fields['select_region']?.didChange(null);
      _formKey.currentState?.fields['select_wilayah']?.didChange(null);
      _formKey.currentState?.fields['select_estate']?.didChange(null);
      _formKey.currentState?.fields['select_afdeling']?.didChange(null);

      // Force rebuild of the regional dropdown
      _formKey.currentState?.fields['select_region']?.reset();
    });

    // Trigger a rebuild of the form
    _formKey.currentState?.save();
  }

  void _onRegionChanged(String? value) {
    setState(() {
      if (_regions.isNotEmpty) {
        final region = _regions.firstWhere(
          (region) => region['id'].toString() == value,
          orElse: () => {'wilayahs': []},
        );

        // Use `region['wilayahs'] ?? []` to ensure it's not null
        _wilayahs = region['wilayahs'] as List<dynamic>? ?? [];
      }
      _estates = [];
      _afdelings = [];
      _selectedEstatePlots = [];
      _selectedOmbrocoordinats = [];
      _initializeLocation();
    });
  }

  void _onWilayahChanged(String? value) {
    setState(() {
      if (_wilayahs.isNotEmpty) {
        final wilayah = _wilayahs.firstWhere(
          (wilayah) => wilayah['id'].toString() == value,
          orElse: () => {'estates': []},
        );

        // Use `wilayah['estates'] ?? []` to ensure it's not null
        _estates = wilayah['estates'] as List<dynamic>? ?? [];
      }
      _afdelings = [];
      _selectedEstatePlots = [];
      _selectedOmbrocoordinats = [];
      _initializeLocation();
    });
  }

  void _onEstateChanged(String? value) {
    setState(() {
      if (_estates.isNotEmpty) {
        final estate = _estates.firstWhere(
          (estate) => estate['id'].toString() == value,
          orElse: () => {'afdelings': [], 'estate_plots': []},
        );

        _afdelings = estate['afdelings'] as List<dynamic>? ?? [];
        _selectedEstatePlots = (estate['estate_plots'] as List<dynamic>? ?? [])
            .map((plot) => EstatePlot(
                  id: plot['id'],
                  est: plot['est'],
                  lat: plot['lat'],
                  lon: plot['lon'],
                ))
            .toList();

        // Clear previously selected ombro coordinates
        _selectedOmbrocoordinats = [];

        // Recheck location distance after selecting a new estate
        _initializeLocation();
      }
    });
  }

  void _onAfdelingChanged(String? value) {
    setState(() {
      if (_afdelings.isNotEmpty) {
        final afdeling = _afdelings.firstWhere(
          (afdeling) => afdeling['id'].toString() == value,
          orElse: () => {'ombro_afdeling': []},
        );

        _selectedOmbrocoordinats =
            (afdeling['ombro_afdeling'] as List<dynamic>? ?? [])
                .map((ombro) => Ombrocoordinat(
                      id: ombro['id'],
                      est: ombro['est'],
                      afd: ombro['afd'],
                      lat: ombro['lat'],
                      lon: ombro['lon'],
                      status: ombro['status'],
                      images: ombro['images'],
                    ))
                .toList();

        if (_selectedOmbrocoordinats.isEmpty) {
          _showEmptyOmbroAlert();
        }

        _initializeLocation();
      }
    });
  }

  void _showEmptyOmbroAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ombro Data Kosong'),
          content: const Text(
              'Tidak ada data ombro untuk afdeling ini. Silakan tambahkan data ombro terlebih dahulu.'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Tambah'),
              onPressed: () {
                Navigator.of(context).pop();
                _showAddOmbroForm();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddOmbroForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();
        String est = '';
        String afd = '';
        String base64Image = '';
        File? imageFile;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah data ombro'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormBuilderDropdown<String>(
                      name: 'estate',
                      decoration: const InputDecoration(labelText: 'Estate'),
                      items: _estates
                          .map((estate) => DropdownMenuItem(
                                value: estate['id'].toString(),
                                child: Text(estate['est']),
                              ))
                          .toList(),
                      onChanged: (value) => est = value ?? '',
                      validator: FormBuilderValidators.required(),
                    ),
                    FormBuilderDropdown<String>(
                      name: 'afdeling',
                      decoration: const InputDecoration(labelText: 'Afdeling'),
                      items: _afdelings
                          .map((afdeling) => DropdownMenuItem(
                                value: afdeling['id'].toString(),
                                child: Text(afdeling['nama']),
                              ))
                          .toList(),
                      onChanged: (value) => afd = value ?? '',
                      validator: FormBuilderValidators.required(),
                    ),
                    ElevatedButton(
                      child: const Text('Take Photo'),
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 100,
                        );
                        if (pickedFile != null) {
                          setState(() {
                            imageFile = File(pickedFile.path);
                          });
                          final bytes = await pickedFile.readAsBytes();
                          base64Image = base64Encode(bytes);
                        }
                      },
                    ),
                    if (imageFile != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('Full Image'),
                                ),
                                body: Center(
                                  child: Image.file(imageFile!),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(imageFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      _saveNewOmbroData(
                          est, afd, _currentLat, _currentLon, base64Image);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveNewOmbroData(String estId, String afdId, double lat, double lon,
      String base64Image) async {
    try {
      var imageData = base64Decode(base64Image);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://management.srs-ssms.com/api/input_data_newombro_location'),
      );

      // Adding the regular form fields
      request.fields['est'] = estId;
      request.fields['afd'] = afdId;
      request.fields['email'] = 'j';
      request.fields['password'] = 'j';
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();

      // Adding the image as a file field
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // field name in the API
          imageData,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Sending the request
      var response = await request.send();

      // Log response details
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "New ombro location added successfully");
        // Refresh the data after successful upload
        await _loadData();
        setState(() {
          // Explicitly set all dropdown values to null
          _formKey.currentState?.fields['select_region']?.didChange(null);
          _formKey.currentState?.fields['select_wilayah']?.didChange(null);
          _formKey.currentState?.fields['select_estate']?.didChange(null);
          _formKey.currentState?.fields['select_afdeling']?.didChange(null);

          // Force rebuild of the regional dropdown
          _formKey.currentState?.fields['select_region']?.reset();
        });

        // Trigger a rebuild of the form
        _formKey.currentState?.save();
      } else {
        // Handle error response
        if (kDebugMode) {
          print('Response reason: ${response.reasonPhrase}');
        }
        Fluttertoast.showToast(
          msg: "Failed to add new ombro location: ${response.reasonPhrase}",
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (error) {
      // Handle any errors that occur during the API call
      if (kDebugMode) {
        print('Error: $error');
      }
      Fluttertoast.showToast(
        msg: "Error occurred: $error",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState?.value;

      // Helper method to find the name based on the id
      String findNameById(List<dynamic> list, String id, String nameKey) {
        return list.firstWhere(
              (item) => item['id'].toString() == id,
              orElse: () => {nameKey: ''},
            )[nameKey] ??
            '';
      }

      final afdId = formData?['select_afdeling'] ?? '';
      final estId = formData?['select_estate'] ?? '';

      final afdNama = findNameById(_afdelings, afdId, 'nama');
      final estNama = findNameById(_estates, estId, 'est');

      final response = await http.post(
        Uri.parse('https://management.srs-ssms.com/api/curah_hujan'),
        body: {
          'email': 'j',
          'password': 'j',
          'afd': afdNama,
          'est': estNama,
          'ch': (formData?['value_curah_hujan'] ?? '').toString(),
          'afd_id': afdId,
          'est_id': estId,
        },
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Data berhasil diunggah",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Cache the submitted data
        await DataCache().addData({
          'afd': afdNama,
          'est': estNama,
          'ch': (formData?['value_curah_hujan'] ?? '').toString(),
          'afd_id': afdId,
          'est_id': estId,
        });

        _resetFormAndFetchData();
      } else {
        Fluttertoast.showToast(
          msg: "Gagal mengunggah data",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Image.asset('assets/images/LOGO-SRS.png', width: 40, height: 40),
          const SizedBox(width: 10),
          const Text('Dashboard',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  if (_selectedEstatePlots.isNotEmpty) ...[
                    _buildLocationInfoCard(),
                    const SizedBox(height: 20),
                    _buildMapCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final String lottieFile = _getLottieFileBasedOnTime();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      color: const Color.fromARGB(255, 0, 34, 102),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Masukkan Data Aktual Sesuai dengan Data yang Ada di Lapangan',
                style: TextStyle(
                    fontSize: 12.0, color: Colors.white.withOpacity(0.9)),
                textAlign: TextAlign.left,
              ),
            ),
            lottie.Lottie.asset(lottieFile, height: 60, width: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdownRow('select_region', 'Pilih Regional', _regions,
                  _onRegionChanged),
              _buildDropdownRow('select_wilayah', 'Pilih Wilayah', _wilayahs,
                  _onWilayahChanged),
              _buildDropdownRow(
                  'select_estate', 'Pilih Estate', _estates, _onEstateChanged),
              _buildDropdownRow('select_afdeling', 'Pilih Afdeling', _afdelings,
                  _onAfdelingChanged),
              const SizedBox(height: 20),
              _buildCurahHujanInput(),
              const SizedBox(height: 25),
              _buildFormButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String name, String label, List<dynamic> items,
      Function(String?)? onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FormBuilderDropdown<String>(
        name: name,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: items.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item['id'].toString(),
            child: Text(item['nama']),
          );
        }).toList(),
        onChanged: onChanged,
        validator:
            FormBuilderValidators.compose([FormBuilderValidators.required()]),
        menuMaxHeight: 200,
      ),
    );
  }

  Widget _buildCurahHujanInput() {
    return FormBuilderTextField(
      name: 'value_curah_hujan',
      decoration: InputDecoration(
        labelText: 'Curah Hujan Data',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(),
        FormBuilderValidators.numeric(),
        (value) {
          final regex = RegExp(r'^\d*\.?\d*');
          if (!regex.hasMatch(value ?? '')) {
            return 'Please enter a valid decimal number';
          }
          return null;
        },
      ]),
    );
  }

  Widget _buildFormButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: _resetFormAndFetchData,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Pilihan'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitButtonEnabled ? _onSubmit : null,
          icon: const Icon(Icons.send),
          label: const Text('Kirim Data'),
        ),
      ],
    );
  }

  Widget _buildLocationInfoCard() {
    double distanceInMeters = _selectedOmbrocoordinats.isNotEmpty
        ? calculateDistance(
            LatLng(_currentLat, _currentLon),
            LatLng(_selectedOmbrocoordinats.last.lat,
                _selectedOmbrocoordinats.last.lon),
          )
        : 0.0;

    return GestureDetector(
      onLongPress: _copyLocationToClipboard,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            distanceInMeters > 10
                ? 'Lokasi anda terlalu jauh dengan lokasi aktual ${distanceInMeters.toStringAsFixed(2)} meter'
                : 'Lokasi anda berada tepat dengan lokasi aktual ${distanceInMeters.toStringAsFixed(2)} meter',
            style: TextStyle(
                color: distanceInMeters > 10 ? Colors.red : Colors.green),
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 400.0,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentLat, _currentLon),
                initialZoom: 14.00,
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  enableMultiFingerGestureRace: true,
                  rotationThreshold: 15.0,
                  pinchZoomThreshold: 0.3,
                  pinchMoveThreshold: 30.0,
                  scrollWheelVelocity: 0.005,
                ),
              ),
              children: [
                _buildTileLayer(),
                _buildPolygonLayer(),
                _buildMarkerLayer(),
                _buildMarkercurrentLocation(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.red, 'User Location',
                    () => _flyTo(_currentLat, _currentLon)),
                const SizedBox(width: 20),
                _buildLegendItem(Colors.blue, 'Ombro Location',
                    () => _flyToOmbroLocations()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _flyTo(double lat, double lon) {
    animatedMapMove(LatLng(lat, lon), 15.0);
  }

  void _flyToOmbroLocations() {
    if (_selectedOmbrocoordinats.isNotEmpty) {
      final firstOmbro = _selectedOmbrocoordinats.first;
      _flyTo(firstOmbro.lat, firstOmbro.lon);
    }
  }

  Widget _buildLegendItem(Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.location_on, color: color, size: 20),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  TileLayer _buildTileLayer() {
    return TileLayer(
      urlTemplate: "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
      subdomains: const ['a', 'b', 'c'],
      maxZoom: 19,
    );
  }

  PolygonLayer _buildPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: _selectedEstatePlots
              .map((plot) => LatLng(plot.lat, plot.lon))
              .toList(),
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
          // ignore: deprecated_member_use
          isFilled: true,
        ),
      ],
    );
  }

  MarkerLayer _buildMarkerLayer() {
    return MarkerLayer(
      markers: _selectedOmbrocoordinats
          .map((ombro) => Marker(
                point: LatLng(ombro.lat, ombro.lon),
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onTap: () {
                    _showMarkerDetails(context, ombro);
                  },
                  child: const Icon(Icons.location_on,
                      color: Colors.blue, size: 30.0), // Changed to blue
                ),
              ))
          .toList(),
    );
  }

  void _showMarkerDetails(BuildContext context, Ombrocoordinat ombro) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Marker Ombro Lokasi'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: double.infinity, // Make the container take full width
                height: 200.0, // Set a fixed height for the image
                child: Image.network(
                  'https://management.srs-ssms.com/storage/${ombro.images}',
                  fit: BoxFit.cover, // Ensure the image covers the container
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  MarkerLayer _buildMarkercurrentLocation() {
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(_currentLat, _currentLon),
          width: 30.0,
          height: 30.0,
          child: GestureDetector(
            onTap: () {
              _showCurrentLocationDetails(context);
            },
            child: const Icon(Icons.location_on,
                color: Colors.red, size: 30.0), // Changed to red
          ),
        ),
      ],
    );
  }

  void _showCurrentLocationDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Lokasi Sekarang'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Add any content you want to display about the current location
              Text('Latitude: $_currentLat'),
              Text('Longitude: $_currentLon'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getLottieFileBasedOnTime() {
    final int hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'assets/animations/Animation - 1724746871822.json';
    } else if (hour >= 12 && hour < 18) {
      return 'assets/animations/Animation - 1724744924585.json';
    } else {
      return 'assets/animations/Night.json';
    }
  }

  void _copyLocationToClipboard() {
    Clipboard.setData(const ClipboardData(text: 'Location copied')).then((_) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    });
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<History> cachedData = [];
  List<History> filteredData = [];
  final TextEditingController _filterController = TextEditingController();
  Box<History>? historyBox;

  @override
  void initState() {
    super.initState();
    _initHiveBox();
    _loadData();
    _filterController.addListener(_filterData);
  }

  Future<void> _initHiveBox() async {
    try {
      if (Hive.isBoxOpen('historyBox')) {
        historyBox = Hive.box<History>('historyBox');
      } else {
        historyBox = await Hive.openBox<History>('historyBox');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening Hive box: $e');
      }
    }
  }

  Future<void> _loadData() async {
    try {
      await DataCache().loadSubmittedData();

      final data = DataCache().getData();
      setState(() {
        cachedData = data;
        filteredData = cachedData;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      setState(() {
        cachedData = [];
        filteredData = [];
      });
    }
  }

  void _filterData() {
    final query = _filterController.text.toLowerCase();
    setState(() {
      filteredData = cachedData.where((history) {
        return history.est.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteItem(int index) async {
    if (historyBox != null) {
      try {
        // Find the actual index in the Hive box using the object reference
        final historyToDelete = filteredData[index];
        final int hiveIndex = cachedData.indexOf(historyToDelete);

        if (hiveIndex != -1) {
          // Ensure the item exists in the box
          await historyBox!.deleteAt(hiveIndex); // Delete the item from Hive

          setState(() {
            cachedData.removeAt(hiveIndex); // Update cachedData first
            filteredData =
                List.from(cachedData); // Re-sync filteredData with cachedData
          });

          // Optionally, reload the data to ensure consistency
          await _loadData();
        } else {
          debugPrint('Error: Item not found in Hive box.');
        }
      } catch (e) {
        debugPrint('Error deleting item: $e');
      }
    }
  }

  Future<void> _clearData() async {
    if (historyBox != null) {
      try {
        await historyBox!.clear();
        setState(() {
          cachedData.clear();
          filteredData.clear();
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error clearing Hive box: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/LOGO-SRS.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              'History',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                labelText: 'Cari Estate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (value) => _filterData(),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final history = filteredData[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SizedBox(
              height: 100,
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text("${history.afd} - ${history.est}"),
                      subtitle: Text("Curah Hujan: ${history.ch}"),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus History',
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteItem(index); // Delete the specific item
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearData,
        tooltip: 'Hapus Semua Data',
        child: const Icon(Icons.delete_forever),
      ),
    );
  }
}
