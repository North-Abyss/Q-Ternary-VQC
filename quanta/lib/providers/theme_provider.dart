import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

enum MenuPosition { left, right, top, bottom }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  MenuPosition _menuPosition = MenuPosition.left;
  MenuPosition get menuPosition => _menuPosition;

  bool _isMenuMinimized = false;
  bool get isMenuMinimized => _isMenuMinimized;

  bool _isMenuCentered = false;
  bool get isMenuCentered => _isMenuCentered;

  final Map<String, Color> _predefinedThemes = {
    "Trackify Default": const Color(0xFF81C784), // Subdued green
    "Ocean Blue": Colors.blue,
    "Forest Green": Colors.green,
    "Deep Purple": Colors.purple,
    "Sunset Orange": Colors.orange,
    "Cherry Red": Colors.red,
    "Teal": Colors.teal,
    "Pink": Colors.pink,
    "Amber": Colors.amber,
    "Indigo": Colors.indigo,
    "Slate": Colors.blueGrey,
    "Cyan": Colors.cyan,
    "Earth": Colors.brown,
  };

  ThemeProvider() {
    _loadPreferences(); 
  }

  String _activeThemeName = "Trackify Default"; 

  String get activeThemeName => _activeThemeName;
  List<String> get availableThemes => _predefinedThemes.keys.toList();
  Color getThemeColor(String name) => _predefinedThemes[name] ?? Colors.deepPurple;

  // Custom Dark Scaffold Color (Colab Style)
  final Color darkScaffoldColor = const Color(0xFF1E1E1E);

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: getThemeColor(_activeThemeName),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final seedColor = getThemeColor(_activeThemeName);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkScaffoldColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF282828), // Colab card surface
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF282828),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkScaffoldColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkScaffoldColor,
        indicatorColor: seedColor.withValues(alpha: 0.2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkScaffoldColor,
        indicatorColor: seedColor.withValues(alpha: 0.2),
      ),
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedMode = prefs.getInt('themeMode');
    if (savedMode != null && savedMode >= 0 && savedMode < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[savedMode];
    }
    
    _activeThemeName = prefs.getString('themeName') ?? "Trackify Default"; 
    
    final savedMenuPos = prefs.getInt('menuPosition');
    if (savedMenuPos != null && savedMenuPos >= 0 && savedMenuPos < MenuPosition.values.length) {
      _menuPosition = MenuPosition.values[savedMenuPos];
    }
    
    _isMenuMinimized = prefs.getBool('isMenuMinimized') ?? false;
    _isMenuCentered = prefs.getBool('isMenuCentered') ?? false;
    
    notifyListeners(); 
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index); 
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    if (_predefinedThemes.containsKey(themeName)) {
      _activeThemeName = themeName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeName', _activeThemeName); 
      notifyListeners();
    }
  }

  Future<void> setMenuPosition(MenuPosition pos) async {
    _menuPosition = pos;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('menuPosition', pos.index);
    notifyListeners();
  }

  Future<void> toggleMenuMinimized() async {
    _isMenuMinimized = !_isMenuMinimized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMenuMinimized', _isMenuMinimized);
    notifyListeners();
  }

  Future<void> toggleMenuCentered() async {
    _isMenuCentered = !_isMenuCentered;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMenuCentered', _isMenuCentered);
    notifyListeners();
  }
}
