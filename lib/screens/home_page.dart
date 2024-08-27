import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'introduction_screen.dart'; // Adjust the import based on your file structure
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart'; // Import this
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import for http requests
import 'package:fluttertoast/fluttertoast.dart';

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
  List<Map<String, dynamic>> _submittedData = [];

  List<dynamic> get regions => _regions;

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
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('submittedData') ?? '[]';
    _submittedData = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
  }

  Future<void> addData(Map<String, dynamic> data) async {
    _submittedData.add(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('submittedData', jsonEncode(_submittedData));
  }

  List<Map<String, dynamic>> getData() {
    return _submittedData;
  }

  Future<void> clearData() async {
    _regions = [];
    _submittedData = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('submittedData');
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
    _loadData();
  }

  Future<void> _loadData() async {
    await DataCache().fetchData();
    setState(() {
      _regions = DataCache().regions;
      _selectedRegion = null;
      _selectedWilayah = null;
      _selectedEstate = null;
      _wilayahs = [];
      _estates = [];
      _afdelings = [];
    });
  }

  void _resetFormAndFetchData() async {
    setState(() {
      _formKey.currentState?.fields.forEach((key, field) {
        field.reset();
      });

      _selectedRegion = null;
      _selectedWilayah = null;
      _selectedEstate = null;
      _wilayahs = [];
      _estates = [];
      _afdelings = [];
    });

    await _loadData();

    setState(() {
      _formKey.currentState?.fields['select_region']?.didChange(null);
      _formKey.currentState?.fields['select_wilayah']?.didChange(null);
      _formKey.currentState?.fields['select_estate']?.didChange(null);
      _formKey.currentState?.fields['select_afdeling']?.didChange(null);
    });
  }

  void _onRegionChanged(String? value) {
    setState(() {
      _selectedRegion = value;
      if (_regions.isNotEmpty) {
        final region = _regions.firstWhere(
          (region) => region['id'].toString() == value,
          orElse: () => {'wilayahs': []},
        );

        // Use `region['wilayahs'] ?? []` to ensure it's not null
        _wilayahs = region['wilayahs'] as List<dynamic>? ?? [];
      }
      _selectedWilayah = null;
      _estates = [];
      _selectedEstate = null;
      _afdelings = [];
    });
  }

  void _onWilayahChanged(String? value) {
    setState(() {
      _selectedWilayah = value;
      if (_wilayahs.isNotEmpty) {
        final wilayah = _wilayahs.firstWhere(
          (wilayah) => wilayah['id'].toString() == value,
          orElse: () => {'estates': []},
        );

        // Use `wilayah['estates'] ?? []` to ensure it's not null
        _estates = wilayah['estates'] as List<dynamic>? ?? [];
      }
      _selectedEstate = null;
      _afdelings = [];
    });
  }

  void _onEstateChanged(String? value) {
    setState(() {
      _selectedEstate = value;
      if (_estates.isNotEmpty) {
        final estate = _estates.firstWhere(
          (estate) => estate['id'].toString() == value,
          orElse: () => {'afdelings': []},
        );

        // Use `estate['afdelings'] ?? []` to ensure it's not null
        _afdelings = estate['afdelings'] as List<dynamic>? ?? [];
      }
    });
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
                                value: region['id'].toString(),
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
                                value: wilayah['id'].toString(),
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
                                value: estate['id'].toString(),
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
                                value: afdeling['id'].toString(),
                                child: Text(afdeling['nama']),
                              );
                            }).toList(),
                            validator: FormBuilderValidators.compose(
                                [FormBuilderValidators.required()]),
                            menuMaxHeight: 200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FormBuilderTextField(
                            name: 'value_curah_hujan',
                            decoration: InputDecoration(
                              labelText: 'Curah Hujan Data',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.numeric(),
                              (value) {
                                final regex = RegExp(r'^\d*\.?\d*$');
                                if (!regex.hasMatch(value ?? '')) {
                                  return 'Please enter a valid decimal number';
                                }
                                return null;
                              },
                            ]),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                _resetFormAndFetchData();
                              },
                              child: const Text('Reset Pilihan'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                _onSubmit();
                              },
                              child: const Text('Kirim Data'),
                            ),
                          ],
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

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> cachedData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await DataCache().loadSubmittedData();
    setState(() {
      cachedData = DataCache().getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This is the History Page',
              style: TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: cachedData.length,
                itemBuilder: (context, index) {
                  final item = cachedData[index];
                  return ListTile(
                    title: Text('Afdeling: ${item['afd']}'),
                    subtitle:
                        Text('Estate: ${item['est']} - CH: ${item['ch']}'),
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
