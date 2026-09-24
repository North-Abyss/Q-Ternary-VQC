import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/diagnostic_state_provider.dart';
import 'pages/dashboard_page.dart';
import 'pages/pipeline_page.dart';
import 'pages/inference_page.dart';
import 'pages/info_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DiagnosticStateProvider()),
      ],
      child: const QuantaApp(),
    ),
  );
}

class QuantaApp extends StatelessWidget {
  const QuantaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Q-Ternary VQC',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AppShell(),
        );
      }
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final List<NavigationDestination> _navDestinations = const [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: 'Pipeline'),
    NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Inference'),
    NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'Info'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  final List<NavigationRailDestination> _railDestinations = const [
    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: Text('Pipeline')),
    NavigationRailDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: Text('Inference')),
    NavigationRailDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: Text('Info')),
    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final pos = themeProvider.menuPosition;
    final isMinimized = themeProvider.isMenuMinimized;

    Widget bodyContent = Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Navigator(
            key: _navigatorKey,
            initialRoute: '/dashboard',
            onGenerateRoute: (RouteSettings settings) {
              WidgetBuilder builder;
              switch (settings.name) {
                case '/dashboard':
                  builder = (BuildContext _) => const DashboardPage();
                  break;
                case '/pipeline':
                  builder = (BuildContext _) => const PipelinePage();
                  break;
                case '/inference':
                  builder = (BuildContext _) => const InferencePage();
                  break;
                case '/info':
                  builder = (BuildContext _) => const InfoPage();
                  break;
                case '/settings':
                  builder = (BuildContext _) => const SettingsPage();
                  break;
                default:
                  builder = (BuildContext _) => const DashboardPage();
              }
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => builder(context),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              );
            },
          ),
        ),
      ),
    );

    Widget buildRail() {
      return NavigationRail(
        extended: !isMinimized,
        groupAlignment: themeProvider.isMenuCentered ? 0.0 : -1.0,
        leading: SizedBox(
          width: isMinimized ? null : 256,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => themeProvider.toggleMenuMinimized(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Row(
                  mainAxisSize: isMinimized ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    Icon(isMinimized ? Icons.menu : Icons.close),
                    if (!isMinimized) ...[
                      const SizedBox(width: 16),
                      const Text('Collapse Menu', style: TextStyle(fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          final routes = ['/dashboard', '/pipeline', '/inference', '/info', '/settings'];
          if (index < routes.length) {
            _navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
        destinations: _railDestinations,
      );
    }

    Widget buildTopBottomBar() {
      return NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          final routes = ['/dashboard', '/pipeline', '/inference', '/info', '/settings'];
          if (index < routes.length) {
            _navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
        destinations: _navDestinations,
      );
    }

    if (pos == MenuPosition.left) {
      return Scaffold(
        body: Row(
          children: [
            buildRail(),
            const VerticalDivider(thickness: 1, width: 1),
            bodyContent,
          ],
        ),
      );
    } else if (pos == MenuPosition.right) {
      return Scaffold(
        body: Row(
          children: [
            bodyContent,
            const VerticalDivider(thickness: 1, width: 1),
            buildRail(),
          ],
        ),
      );
    } else if (pos == MenuPosition.top) {
      return Scaffold(
        body: Column(
          children: [
            buildTopBottomBar(),
            const Divider(thickness: 1, height: 1),
            bodyContent,
          ],
        ),
      );
    } else {
      // Bottom
      return Scaffold(
        body: Column(
          children: [
            bodyContent,
            const Divider(thickness: 1, height: 1),
            buildTopBottomBar(),
          ],
        ),
      );
    }
  }
}
