import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show AppLocalizations;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'purple';
  final List<Map<String, dynamic>> _themes = [
    {
      'name': 'purple',
      'color': Colors.deepPurple,
    },
    {
      'name': 'blue',
      'color': Colors.blue,
    },
    {
      'name': 'green',
      'color': Colors.green,
    },
    {
      'name': 'orange',
      'color': Colors.orange,
    },
    {
      'name': 'pink',
      'color': Colors.pink,
    },
  ];

  String _themeTitle(BuildContext context, String themeName) {
    final l10n = AppLocalizations.of(context);
    switch (themeName) {
      case 'purple':
        return l10n.themePurple;
      case 'blue':
        return l10n.themeBlue;
      case 'green':
        return l10n.themeGreen;
      case 'orange':
        return l10n.themeOrange;
      case 'pink':
        return l10n.themePink;
      default:
        return themeName;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme') ?? 'purple';
    });
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    setState(() {
      _selectedTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
        backgroundColor: _themes.firstWhere((t) => t['name'] == _selectedTheme)['color'],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _themes.firstWhere((t) => t['name'] == _selectedTheme)['color'].withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.settingsThemeSection,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _themes.map((theme) {
                final isSelected = theme['name'] == _selectedTheme;
                return ChoiceChip(
                  label: Text(_themeTitle(context, theme['name'])),
                  selected: isSelected,
                  onSelected: (_) => _saveTheme(theme['name']),
                  backgroundColor: Colors.white,
                  selectedColor: theme['color'].withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? theme['color'] : Colors.black87,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
} 