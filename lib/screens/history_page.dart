import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/models.dart';
import 'package:flutter/foundation.dart';

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
      if (historyBox != null) {
        final data = historyBox!.values.toList();
        setState(() {
          cachedData = data;
          filteredData = cachedData;
        });
      }
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
