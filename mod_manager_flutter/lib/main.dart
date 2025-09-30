import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_segmented_tab_control/animated_segmented_tab_control.dart';
import 'screens/mods_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/state_providers.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'Mod Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: isDarkMode
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  static const List<Widget> _screens = [ModsScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: ref.read(tabIndexProvider),
    );
    _tabController.addListener(() {
      ref.read(tabIndexProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sss = ref.watch(zoomScaleProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Tab views
          IndexedStack(index: ref.watch(tabIndexProvider), children: _screens),

          // Tab bar at the top
          Padding(
            padding: EdgeInsets.only(top: 25 * sss),
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.scale(
                scale: sss,
                child: SizedBox(
                  width: 300,
                  child: SegmentedTabControl(
                    controller: _tabController,
                    height: 42,
                    selectedTabTextColor: Colors.black,
                    tabTextColor: Colors.white,
                    textStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    indicatorDecoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    barDecoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color.fromARGB(127, 255, 255, 255),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    tabs: const [
                      SegmentTab(label: "Моди"),
                      SegmentTab(label: "Налаштування"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
