import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'introduction_screen.dart'; // Adjust the import based on your file structure
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart'; // Import this
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import for http requests

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    HistoryPage(),
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
        items: [
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
    _fetchData();
  }

  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse(
        'https://management.srs-ssms.com/api/get_data_main?email=j&password=j'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _regions = data;
      });
    } else {
      throw Exception('Failed to load data');
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
  }

  void _onWilayahChanged(String? value) {
    setState(() {
      _selectedWilayah = value;
      _estates = _wilayahs
          .firstWhere((wilayah) => wilayah['nama'] == value)['estates'];
      _selectedEstate = null;
      _afdelings = [];
    });
  }

  void _onEstateChanged(String? value) {
    setState(() {
      _selectedEstate = value;
      _afdelings =
          _estates.firstWhere((estate) => estate['nama'] == value)['afdelings'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image at the top
            Image.asset(
              'assets/images/LOGO-SRS.png', // Replace with your image path
              width: 100,
              height: 100,
            ),
            SizedBox(height: 20),
            Text(
              'Masukkan Data aktual sesuai dengan data yang ada di lapangan',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_region',
                            decoration: InputDecoration(
                              labelText: 'Pilih Regional',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
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
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_wilayah',
                            decoration: InputDecoration(
                              labelText: 'Pilih Wilayah',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
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
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_estate',
                            decoration: InputDecoration(
                              labelText: 'Pilih Estate',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
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
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          child: FormBuilderDropdown<String>(
                            name: 'select_afdeling',
                            decoration: InputDecoration(
                              labelText: 'Pilih Afdeling',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
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
                        SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {},
                              child: Text('Reset Pilihan'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.saveAndValidate() ??
                                    false) {
                                  print(_formKey.currentState?.value);
                                }
                              },
                              child: Text('Submit'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('hasSkipped'); // Clear the skip status
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IntroductionScreen(),
                  ),
                );
              },
              child: Text('Reset to Introduction Screen'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: Center(
        child: Text(
          'This is the History Page',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
