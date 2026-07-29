import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/app_language.dart';
import 'home_screen.dart';
import 'pin_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = Provider.of<AppLanguage>(context, listen: false);

    await lang.init();
    await appState.init();

    final pinSet = await PinStorage.isPinSet();

    if (!mounted) return;

    if (pinSet) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EnterPinScreen(
            onSuccess: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            const Text(
              'Expense Tracker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
