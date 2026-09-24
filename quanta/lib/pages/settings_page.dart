import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import '../widgets/app_notification.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await _apiService.getBaseUrl();
    setState(() {
      _urlController.text = url;
    });
  }

  Future<void> _saveSettings() async {
    await _apiService.setBaseUrl(_urlController.text);
    if (mounted) {
      AppNotification.show(context, 'Success', 'Settings saved successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme Mode'),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        themeProvider.setThemeMode(newSelection.first);
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text('Menu Position'),
                    const SizedBox(height: 12),
                    SegmentedButton<MenuPosition>(
                      segments: const [
                        ButtonSegment(value: MenuPosition.left, label: Text('Left'), icon: Icon(Icons.align_horizontal_left)),
                        ButtonSegment(value: MenuPosition.right, label: Text('Right'), icon: Icon(Icons.align_horizontal_right)),
                        ButtonSegment(value: MenuPosition.top, label: Text('Top'), icon: Icon(Icons.align_vertical_top)),
                        ButtonSegment(value: MenuPosition.bottom, label: Text('Bottom'), icon: Icon(Icons.align_vertical_bottom)),
                      ],
                      selected: {themeProvider.menuPosition},
                      onSelectionChanged: (Set<MenuPosition> newSelection) {
                        themeProvider.setMenuPosition(newSelection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Center Menu Items'),
                        const Spacer(),
                        Switch(
                          value: themeProvider.isMenuCentered,
                          onChanged: (bool value) {
                            themeProvider.toggleMenuCentered();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Color Palette (Colab Style)'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: themeProvider.availableThemes.map((themeName) {
                        final isSelected = themeProvider.activeThemeName == themeName;
                        final color = themeProvider.getThemeColor(themeName);
                        
                        return InkWell(
                          onTap: () => themeProvider.setTheme(themeName),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? color : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(themeName, style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? color : null,
                                )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            Text(
              'Backend Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL',
                        hintText: 'e.g., http://127.0.0.1:5000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Connection Settings'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
