import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facebook Saver',
      theme: ThemeData(
        primaryColor: const Color(0xFF19183B),
        hintColor: const Color(0xFF708993),
        scaffoldBackgroundColor: const Color(0xFFE7F2EF),
        cardColor: const Color(0xFFA1C2BD),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF19183B)),
          bodyMedium: TextStyle(color: Color(0xFF19183B)),
          titleLarge: TextStyle(color: Color(0xFF19183B)),
          labelLarge: TextStyle(color: Color(0xFFE7F2EF)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF708993),
            foregroundColor: const Color(0xFFE7F2EF),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF19183B),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Color(0xFF708993)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF19183B)),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class Account {
  String email;
  String username;
  String password;
  String tfa;

  Account({
    required this.email,
    required this.username,
    required this.password,
    required this.tfa,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      tfa: json['tfa'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'tfa': tfa,
    };
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Account> _accounts = [];
  int? _editingIndex;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tfaController = TextEditingController();
  final TextEditingController _importController = TextEditingController();
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    final String? accountsJson = _prefs.getString('accounts');
    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      setState(() {
        _accounts = decoded.map((item) => Account.fromJson(item)).toList();
      });
    }
    // Load input fields from prefs for instant persistence
    _emailController.text = _prefs.getString('email') ?? '';
    _usernameController.text = _prefs.getString('username') ?? '';
    _passwordController.text = _prefs.getString('password') ?? '';
    _tfaController.text = _prefs.getString('tfa') ?? '';

    // Listeners for instant save of input fields
    _emailController.addListener(() => _prefs.setString('email', _emailController.text));
    _usernameController.addListener(() => _prefs.setString('username', _usernameController.text));
    _passwordController.addListener(() => _prefs.setString('password', _passwordController.text));
    _tfaController.addListener(() => _prefs.setString('tfa', _tfaController.text));
  }

  Future<void> _saveAccounts() async {
    final String accountsJson = jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
    await _prefs.setString('accounts', accountsJson);
  }

  void _generatePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final Random random = Random();
    final String randomLetters = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    final String date = DateFormat('ddMMyyyy').format(DateTime.now());
    setState(() {
      _passwordController.text = '$randomLetters$date';
    });
    // Instant save via listener
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _passwordController.text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied')));
  }

  void _submit() {
    final Account newAccount = Account(
      email: _emailController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      tfa: _tfaController.text,
    );
    setState(() {
      if (_editingIndex != null) {
        _accounts[_editingIndex!] = newAccount;
        _editingIndex = null;
      } else {
        _accounts.add(newAccount);
      }
    });
    _saveAccounts();
    _clearFields();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account saved')));
  }

  void _clearFields() {
    _emailController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _tfaController.clear();
    // Prefs will be updated via listeners
  }

  Future<void> _downloadJson() async {
    final PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final Directory? baseDir = await getExternalStorageDirectory();
      if (baseDir != null) {
        final String downloadPath = '/storage/emulated/0/Download/fb_saver';
        final Directory dir = Directory(downloadPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final String dateTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final String filePath = '$downloadPath/facebook_accounts_$dateTime.json';
        final File file = File(filePath);
        final String jsonData = jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
        await file.writeAsString(jsonData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded to $filePath')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission denied')));
    }
  }

  void _importJson() {
    try {
      final List<dynamic> imported = jsonDecode(_importController.text);
      final List<Account> newAccounts = imported.map((item) => Account.fromJson(item)).toList();
      setState(() {
        _accounts.addAll(newAccounts);
      });
      _saveAccounts();
      _importController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid JSON')));
    }
  }

  void _editAccount(int index) {
    setState(() {
      _editingIndex = index;
      _emailController.text = _accounts[index].email;
      _usernameController.text = _accounts[index].username;
      _passwordController.text = _accounts[index].password;
      _tfaController.text = _accounts[index].tfa;
    });
    _tabController.animateTo(0);
  }

  void _copyAccountPassword(int index) {
    Clipboard.setData(ClipboardData(text: _accounts[index].password));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied')));
  }

  void _deleteAccount(int index) {
    setState(() {
      _accounts.removeAt(index);
    });
    _saveAccounts();
  }

  void _clearAll() {
    setState(() {
      _accounts.clear();
    });
    _saveAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facebook Saver'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Input'),
            const Tab(text: 'Import/Export'),
            Tab(text: 'Saved (${_accounts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _generatePassword,
                      child: const Text('Gen'),
                    ),
                    ElevatedButton(
                      onPressed: _copyPassword,
                      child: const Text('Copy'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tfaController,
                  decoration: const InputDecoration(labelText: '2FA'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit'),
                    ),
                    ElevatedButton(
                      onPressed: _clearFields,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tab 2: Import/Export
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _downloadJson,
                  child: const Text('Download JSON'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _importController,
                  decoration: const InputDecoration(labelText: 'Paste JSON here'),
                  maxLines: null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _importJson,
                  child: const Text('Import JSON'),
                ),
              ],
            ),
          ),
          // Tab 3: Saved
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _clearAll,
                  child: const Text('Clear All'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _accounts.length,
                  itemBuilder: (context, i) {
                    final int accountIndex = _accounts.length - 1 - i; // Latest on top
                    final Account acc = _accounts[accountIndex];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${acc.email}'),
                            Text('Username: ${acc.username}'),
                            Text('Password: ${acc.password}'),
                            Text('2FA: ${acc.tfa}'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _editAccount(accountIndex),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () => _copyAccountPassword(accountIndex),
                                  child: const Text('Copy'),
                                ),
                                TextButton(
                                  onPressed: () => _deleteAccount(accountIndex),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tfaController.dispose();
    _importController.dispose();
    super.dispose();
  }
}