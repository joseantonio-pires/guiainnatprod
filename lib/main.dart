import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FlutterFlowTheme.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  bool displaySplashImage = true;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    Future.delayed(
      Duration(milliseconds: 1000),
      () => safeSetState(() => _appStateNotifier.stopShowingSplashImage()),
    );
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'insetosFlutter',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('pt'),
        Locale('en', ''),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (final locale in supportedLocales) {
            if (locale.languageCode == deviceLocale.languageCode &&
                (locale.countryCode == null ||
                    locale.countryCode == deviceLocale.countryCode)) {
              return locale;
            }
          }
        }
        return const Locale('pt', 'BR');
      },
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key, this.initialPage, this.page});

  final String? initialPage;
  final Widget? page;

  @override
  // ignore: library_private_types_in_public_api
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'HomePage';
  late Widget? _currentPage;

  // ✅ Cache dos widgets para evitar recriação
  late final Map<String, Widget> _tabs = {
    'HomePage': const HomePageWidget(),
    'tutorial': const TutorialWidget(),
    'menu': const MenuWidget(),
    'sobre': const SobreWidget(),
  };

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabs.keys.toList().indexOf(_currentPageName);

    return Scaffold(
      body: _currentPage ?? _tabs[_currentPageName],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == 4) {
            // Se clicar no botão Sair o i é igual a 4. Entra nessa condição
            Future.delayed(Duration(milliseconds: 100), () {
              // ignore: use_build_context_synchronously
              Navigator.of(context).popUntil((route) => route.isFirst);
              Future.delayed(Duration(milliseconds: 100), () {
                // Fecha o app de forma segura e limpa
                SystemNavigator.pop(); // Use esta linha no lugar de exit(0)
              });
            });
          } else {
            safeSetState(() {
              _currentPage = null;
              _currentPageName = _tabs.keys.toList()[i];
            });
          }
        },
        backgroundColor: Color(0xFF006F35),
        selectedItemColor: FlutterFlowTheme.of(context).primaryBackground,
        unselectedItemColor: Color(0x8A000000),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house, size: 44.0),
            label: 'Home',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined, size: 44.0),
            label: 'Tutorial',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_sharp, size: 44.0),
            label: 'Menu',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 44.0),
            label: 'Sobre',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app, size: 44.0),
            label: 'Sair',
            tooltip: '',
          ),
        ],
      ),
    );
  }
}
