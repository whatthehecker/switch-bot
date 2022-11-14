import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  static const String keyReconnectLastUrl = 'reconnect_last_url';
  static const String keyLastUrl = 'last_url';

  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _lastUrl;
  bool _reconnectLastUrl = false;

  @override
  void initState() {
    super.initState();

    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _reconnectLastUrl = preferences.getBool(SettingsScreen.keyReconnectLastUrl) ?? true;
    _lastUrl = preferences.getString(SettingsScreen.keyLastUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Automatically reconnect to last URL on start'),
              subtitle: Text(_lastUrl == null ? 'Not yet connected to bot.' : 'Last URL: $_lastUrl'),
              value: _reconnectLastUrl,
              onChanged: (bool storeLastUrl) async {
                (await SharedPreferences.getInstance()).setBool(SettingsScreen.keyReconnectLastUrl, storeLastUrl);

                setState(() {
                  _reconnectLastUrl = storeLastUrl;
                });
              },
            ),
            const AboutListTile(
              aboutBoxChildren: [
                Text('Controller button icons modified from "Switch Button Icons and Controls" by Zacksly, '
                    'Licensed under CC BY 3.0 - https://zacksly.itch.io')
              ],
            )
          ],
        ),
      ),
    );
  }
}
