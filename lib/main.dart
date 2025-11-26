import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // 新增
import 'firebase_options.dart'; // 這檔案是 flutterfire configure 自動產生的
import 'providers/collection_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
