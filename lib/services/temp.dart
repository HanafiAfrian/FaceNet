import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: HomePage()),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PersistentBottomSheetController? _bottomSheetController;
  String _selectedItem = 'Item 1'; // Default selected item

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wrap the HomePage with Scaffold
      appBar: AppBar(
        title: Text('Persistent Bottom Sheet Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showBottomSheet();
          },
          child: Text('Show Bottom Sheet'),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    _bottomSheetController = showBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    title: Text('Choose an item:'),
                    trailing: DropdownButton<String>(
                      value: _selectedItem,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedItem = newValue!;
                        });
                      },
                      items: <String>['Item 1', 'Item 2', 'Item 3']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _bottomSheetController?.close();
                    },
                    child: Text('Close Bottom Sheet'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
