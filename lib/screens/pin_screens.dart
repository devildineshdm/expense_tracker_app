import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

// PIN la plain text sathvण्याऐवजी tyacha hash sathvto (thodी jast safety)
String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

class PinStorage {
  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_pin_hash') != null;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin_hash', _hashPin(pin));
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_pin_hash');
    return saved != null && saved == _hashPin(pin);
  }

  static Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_pin_hash');
  }
}

// ---------- SET PIN SCREEN (Settings madhun access hoto) ----------
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _step1Pin = '';
  String _entered = '';
  bool _confirming = false;
  String? _error;
  bool _pinAlreadySet = false;

  @override
  void initState() {
    super.initState();
    PinStorage.isPinSet().then((v) => setState(() => _pinAlreadySet = v));
  }

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _onComplete);
    }
  }

  void _onComplete() {
    if (!_confirming) {
      setState(() {
        _step1Pin = _entered;
        _entered = '';
        _confirming = true;
      });
    } else {
      if (_entered == _step1Pin) {
        PinStorage.setPin(_entered).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN यशस्वीरित्या सेट झाला!')));
            Navigator.pop(context);
          }
        });
      } else {
        setState(() {
          _error = 'PIN जुळत नाही, परत सुरुवात करा';
          _entered = '';
          _confirming = false;
          _step1Pin = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App PIN Lock')),
      body: Column(
        children: [
          if (_pinAlreadySet)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await PinStorage.removePin();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN lock बंद केला')));
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('PIN Lock बंद करा'),
              ),
            ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 50, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _confirming
                        ? 'PIN परत टाका (confirm करण्यासाठी)'
                        : '4-digit PIN टाका',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _entered.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          _buildNumPad(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNumPad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 70, height: 60);
            }
            return SizedBox(
              width: 70,
              height: 60,
              child: TextButton(
                onPressed: () {
                  if (key == '⌫') {
                    _onBackspace();
                  } else {
                    _onDigit(key);
                  }
                },
                child: Text(
                  key,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

// ---------- ENTER PIN SCREEN (App uघडल्यावर lock साठी) ----------
class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  String _entered = '';
  String? _error;

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _verify);
    }
  }

  Future<void> _verify() async {
    final valid = await PinStorage.verifyPin(_entered);
    if (!mounted) return;
    if (valid) {
      // Ithe swataha cha (EnterPinScreen cha) context vaparto, splash screen
      // cha junaa (disposed) context nahi - tyamule navigation nakki hoto
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _error = 'चुकीचा PIN, परत प्रयत्न करा';
        _entered = '';
      });
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('PIN टाका', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            _buildNumPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumPad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 70, height: 60);
            }
            return SizedBox(
              width: 70,
              height: 60,
              child: TextButton(
                onPressed: () {
                  if (key == '⌫') {
                    _onBackspace();
                  } else {
                    _onDigit(key);
                  }
                },
                child: Text(key, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
