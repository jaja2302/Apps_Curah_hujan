// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'introduction_screen.dart'; // Adjust the import based on your file structure
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart'; // Import this
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import for http requests
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'history.dart'; // Import your History model

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
    final int hour = DateTime.now().hour;

    // Determine which Lottie animation to use based on the time
    String lottieFile;
    if (hour >= 6 && hour < 12) {
      // Morning
      lottieFile = 'assets/animations/Animation - 1724746871822.json';
    } else if (hour >= 12 && hour < 18) {
      // Afternoon
      lottieFile = 'assets/animations/Animation - 1724744924585.json';
    } else {
      // Night
      lottieFile = 'assets/animations/Night.json';
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/LOGO-SRS.png',
              width: 40, // Adjust the size as needed
              height: 40,
            ),
            const SizedBox(
                width: 10), // Add some space between the logo and title
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              color: const Color.fromARGB(255, 0, 34, 102),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Masukkan Data Aktual Sesuai dengan Data yang Ada di Lapangan',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    Lottie.asset(
                      lottieFile,
                      height: 60,
                      width: 60,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              color: const Color.fromARGB(255, 255, 255, 255),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: FormBuilder(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Row for Regional and Wilayah
                                Row(
                                  children: [
                                    Expanded(
                                      child: FormBuilderDropdown<String>(
                                        name: 'select_region',
                                        decoration: InputDecoration(
                                          labelText: 'Pilih Regional',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                        ),
                                        initialValue: _selectedRegion,
                                        items: _regions
                                            .map<DropdownMenuItem<String>>(
                                                (region) {
                                          return DropdownMenuItem<String>(
                                            value: region['id'].toString(),
                                            child: Text(region['nama']),
                                          );
                                        }).toList(),
                                        onChanged: _onRegionChanged,
                                        validator:
                                            FormBuilderValidators.compose([
                                          FormBuilderValidators.required()
                                        ]),
                                        menuMaxHeight: 200,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FormBuilderDropdown<String>(
                                        name: 'select_wilayah',
                                        decoration: InputDecoration(
                                          labelText: 'Pilih Wilayah',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                        ),
                                        initialValue: _selectedWilayah,
                                        items: _wilayahs
                                            .map<DropdownMenuItem<String>>(
                                                (wilayah) {
                                          return DropdownMenuItem<String>(
                                            value: wilayah['id'].toString(),
                                            child: Text(wilayah['nama']),
                                          );
                                        }).toList(),
                                        onChanged: _onWilayahChanged,
                                        validator:
                                            FormBuilderValidators.compose([
                                          FormBuilderValidators.required()
                                        ]),
                                        menuMaxHeight: 200,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Row for Estate and Afdeling
                                Row(
                                  children: [
                                    Expanded(
                                      child: FormBuilderDropdown<String>(
                                        name: 'select_estate',
                                        decoration: InputDecoration(
                                          labelText: 'Pilih Estate',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                        ),
                                        initialValue: _selectedEstate,
                                        items: _estates
                                            .map<DropdownMenuItem<String>>(
                                                (estate) {
                                          return DropdownMenuItem<String>(
                                            value: estate['id'].toString(),
                                            child: Text(estate['nama']),
                                          );
                                        }).toList(),
                                        onChanged: _onEstateChanged,
                                        validator:
                                            FormBuilderValidators.compose([
                                          FormBuilderValidators.required()
                                        ]),
                                        menuMaxHeight: 200,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FormBuilderDropdown<String>(
                                        name: 'select_afdeling',
                                        decoration: InputDecoration(
                                          labelText: 'Pilih Afdeling',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                        ),
                                        items: _afdelings
                                            .map<DropdownMenuItem<String>>(
                                                (afdeling) {
                                          return DropdownMenuItem<String>(
                                            value: afdeling['id'].toString(),
                                            child: Text(afdeling['nama']),
                                          );
                                        }).toList(),
                                        validator:
                                            FormBuilderValidators.compose([
                                          FormBuilderValidators.required()
                                        ]),
                                        menuMaxHeight: 200,
                                      ),
                                    ),
                                  ],
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
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
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('hasSkipped'); // Clear the skip status
                if (!context.mounted) {
                  return; // Check if context is still mounted
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IntroductionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Kembali ke Halaman Utama'),
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
  List<History> cachedData = [];
  List<History> filteredData = [];
  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _filterController.addListener(_filterData);
  }

  Future<void> _loadData() async {
    await DataCache().loadSubmittedData();
    setState(() {
      cachedData = DataCache().getData();
      filteredData = cachedData; // Initialize with all data
    });
  }

  void _filterData() {
    final query = _filterController.text.toLowerCase();
    setState(() {
      filteredData = cachedData.where((history) {
        return history.est.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _clearData() async {
    var box = await Hive.openBox('historyBox'); // Open your Hive box
    await box.clear(); // Clear all data in the box
    setState(() {
      cachedData.clear();
      filteredData.clear();
    });
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
              height: 100, // Set a fixed height for each card
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
                      // Add your deletion logic here if needed
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
        child: Icon(Icons.delete_forever),
      ),
    );
  }
}
