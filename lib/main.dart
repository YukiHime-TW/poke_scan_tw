import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/collection_provider.dart';
import 'screens/home_screen.dart';

void main() {
    runApp(
        MultiProvider(
        providers: [
            ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ],
        child: const MyApp(),
        ),
    );
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
        title: 'PokeScan TW',
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            useMaterial3: true,
        ),
        home: const HomeScreen(),
        );
    }
}
