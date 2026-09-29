import 'package:flutter/material.dart';

/// Screen for app preferences, venue selection, and attribution.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & About')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Data Attribution'),
            subtitle: Text(
              'Weather data provided by Open-Meteo.com (CC BY 4.0)',
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.place_outlined),
            title: Text('Default Ground / Location'),
            subtitle: Text('Configure home pitch coordinates'),
          ),
        ],
      ),
    );
  }
}
