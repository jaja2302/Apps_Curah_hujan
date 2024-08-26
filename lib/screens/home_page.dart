import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

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
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final GlobalKey<_DashboardPageState> _dashboardKey =
      GlobalKey<_DashboardPageState>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      DashboardPage(key: _dashboardKey),
      const HistoryPage(),
    ]);
  }

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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  List<dynamic> _regions = [];
  List<dynamic> _wilayahs = [];
  List<dynamic> _estates = [];
  List<dynamic> _afdelings = [];

  String? _selectedRegion;
  String? _selectedWilayah;
  String? _selectedEstate;

  @override
  void initState() {
    super.initState();
    _loadFormData(); // Load saved form data
    _fetchData();
  }

  Future<void> _loadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRegion = prefs.getString('selectedRegion');
      _selectedWilayah = prefs.getString('selectedWilayah');
      _selectedEstate = prefs.getString('selectedEstate');
      _regions = jsonDecode(prefs.getString('regionsData') ?? '[]');
      _wilayahs = jsonDecode(prefs.getString('wilayahsData') ?? '[]');
      _estates = jsonDecode(prefs.getString('estatesData') ?? '[]');
      _afdelings = jsonDecode(prefs.getString('afdelingsData') ?? '[]');
    });
  }

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedRegion', _selectedRegion ?? '');
    await prefs.setString('selectedWilayah', _selectedWilayah ?? '');
    await prefs.setString('selectedEstate', _selectedEstate ?? '');
    await prefs.setString('regionsData', jsonEncode(_regions));
    await prefs.setString('wilayahsData', jsonEncode(_wilayahs));
    await prefs.setString('estatesData', jsonEncode(_estates));
    await prefs.setString('afdelingsData', jsonEncode(_afdelings));
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('regionsData');

    if (cachedData != null) {
      final data = jsonDecode(cachedData) as List;
      setState(() {
        _regions = data;
      });
    } else {
      try {
        final response = await http.get(Uri.parse(
            'https://management.srs-ssms.com/api/get_data_main?email=j&password=j'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List;
          setState(() {
            _regions = data;
          });
          prefs.setString('regionsData', jsonEncode(data));
        } else {
          throw Exception('Failed to load data');
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
  }

  void _onRegionChanged(String? value) {
    setState(() {
      _selectedRegion = value;
      _wilayahs =
          _regions.firstWhere((region) => region['nama'] == value)['wilayahs'];
      _selectedWilayah = null;
      _estates = [];
      _selectedEstate = null;
      _afdelings = [];
    });
    _saveFormData(); // Save form data on change
  }

  void _onWilayahChanged(String? value) {
    setState(() {
      _selectedWilayah = value;
      _estates = _wilayahs
          .firstWhere((wilayah) => wilayah['nama'] == value)['estates'];
      _selectedEstate = null;
      _afdelings = [];
    });
    _saveFormData(); // Save form data on change
  }

  void _onEstateChanged(String? value) {
    setState(() {
      _selectedEstate = value;
      _afdelings =
          _estates.firstWhere((estate) => estate['nama'] == value)['afdelings'];
    });
    _saveFormData(); // Save form data on change
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'assets/images/LOGO-SRS.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Masukkan Data aktual sesuai dengan data yang ada di lapangan',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_region',
                            decoration: InputDecoration(
                              labelText: 'Pilih Regional',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            initialValue: _selectedRegion,
                            items: _regions
                                .map<DropdownMenuItem<String>>((region) {
                              return DropdownMenuItem<String>(
                                value: region['nama'],
                                child: Text(region['nama']),
                              );
                            }).toList(),
                            onChanged: _onRegionChanged,
                            validator: FormBuilderValidators.compose(
                                [FormBuilderValidators.required()]),
                            menuMaxHeight: 200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_wilayah',
                            decoration: InputDecoration(
                              labelText: 'Pilih Wilayah',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            initialValue: _selectedWilayah,
                            items: _wilayahs
                                .map<DropdownMenuItem<String>>((wilayah) {
                              return DropdownMenuItem<String>(
                                value: wilayah['nama'],
                                child: Text(wilayah['nama']),
                              );
                            }).toList(),
                            onChanged: _onWilayahChanged,
                            validator: FormBuilderValidators.compose(
                                [FormBuilderValidators.required()]),
                            menuMaxHeight: 200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_estate',
                            decoration: InputDecoration(
                              labelText: 'Pilih Estate',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            initialValue: _selectedEstate,
                            items: _estates
                                .map<DropdownMenuItem<String>>((estate) {
                              return DropdownMenuItem<String>(
                                value: estate['nama'],
                                child: Text(estate['nama']),
                              );
                            }).toList(),
                            onChanged: _onEstateChanged,
                            validator: FormBuilderValidators.compose(
                                [FormBuilderValidators.required()]),
                            menuMaxHeight: 200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_afdeling',
                            decoration: InputDecoration(
                              labelText: 'Pilih Afdeling',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            items: _afdelings
                                .map<DropdownMenuItem<String>>((afdeling) {
                              return DropdownMenuItem<String>(
                                value: afdeling['nama'],
                                child: Text(afdeling['nama']),
                              );
                            }).toList(),
                            validator: FormBuilderValidators.compose(
                                [FormBuilderValidators.required()]),
                            menuMaxHeight: 200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState?.saveAndValidate() ??
                                false) {
                              // Form is valid, perform actions here
                              final selectedRegion =
                                  _formKey.currentState?.value['select_region'];
                              final selectedWilayah = _formKey
                                  .currentState?.value['select_wilayah'];
                              final selectedEstate =
                                  _formKey.currentState?.value['select_estate'];
                              final selectedAfdeling = _formKey
                                  .currentState?.value['select_afdeling'];

                              // Handle the selections here
                              if (kDebugMode) {
                                print('Selected Region: $selectedRegion');
                                print('Selected Wilayah: $selectedWilayah');
                                print('Selected Estate: $selectedEstate');
                                print('Selected Afdeling: $selectedAfdeling');
                              }

                              // Clear the SharedPreferences
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('formData');

                              // Reset the form
                              _formKey.currentState?.reset();

                              // Clear state variables
                              setState(() {
                                _selectedRegion = null;
                                _selectedWilayah = null;
                                _selectedEstate = null;
                                _afdelings = [];
                              });

                              // Force rebuild by changing key or navigation (optional)
                              // _dashboardKey.currentState?.setState(() {}); // Force rebuild
                            } else {
                              // Handle validation errors here
                              if (kDebugMode) {
                                print('Validation failed');
                              }
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: const Center(
        child: Text('History Page'),
      ),
    );
  }
}
