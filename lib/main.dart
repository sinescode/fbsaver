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
      title: 'FB Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1877F2),
          secondary: Color(0xFF4267B2),
          surface: Color(0xFFFAFAFA),
          background: Color(0xFFF8FAFC),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1F2937),
          onBackground: Color(0xFF374151),
          error: Color(0xFFEF4444),
          tertiary: Color(0xFF3B5998),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE1306C), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
          surfaceTintColor: Colors.transparent,
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
  String auth_code;
  Account({
    required this.email,
    required this.username,
    required this.password,
    required this.auth_code,
  });
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      auth_code: json['auth_code'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'auth_code': auth_code,
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
  final TextEditingController _auth_codeController = TextEditingController();
  final TextEditingController _importController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late SharedPreferences _prefs;
 
  bool _showEmailInput = true;
  int _passwordMethod = 0; // 0 for prefix method, 1 for word method
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
   
    _emailController.text = _prefs.getString('email') ?? '';
    _usernameController.text = _prefs.getString('username') ?? '';
    _auth_codeController.text = _prefs.getString('auth_code') ?? '';
    _prefixController.text = _prefs.getString('prefix') ?? '';
    _passwordController.text = _prefs.getString('random_password') ?? '';
    _showEmailInput = _prefs.getBool('show_email_input') ?? true;
    _passwordMethod = _prefs.getInt('password_method') ?? 0;
    if (_passwordMethod == 1 && _passwordController.text.isEmpty) {
      _generateRandomPassword();
    }
    _emailController.addListener(() => _prefs.setString('email', _emailController.text));
    _usernameController.addListener(() => _prefs.setString('username', _usernameController.text));
    _auth_codeController.addListener(() => _prefs.setString('auth_code', _auth_codeController.text));
    _prefixController.addListener(() => _prefs.setString('prefix', _prefixController.text));
    _passwordController.addListener(() => _prefs.setString('random_password', _passwordController.text));
  }
  Future<void> _saveAccounts() async {
    final String accountsJson = jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
    await _prefs.setString('accounts', accountsJson);
  }
  String get _currentPassword {
    if (_passwordMethod == 1) {
      return _passwordController.text.trim();
    } else {
      final String prefix = _prefixController.text.trim();
      final String day = DateTime.now().day.toString().padLeft(2, '0');
      return prefix.isNotEmpty ? '$prefix@$day' : '@$day';
    }
  }
  void _generateRandomPassword() {
    const String letters = 'abcdefghijklmnopqrstuvwxyz';
    final Random random = Random();
    final int randomLength = 8 + random.nextInt(6); // 8 to 13
    String randomPart = '';
    for (int i = 0; i < randomLength; i++) {
      final int index = random.nextInt(letters.length);
      final String char = letters[index];
      randomPart += random.nextBool() ? char.toUpperCase() : char.toLowerCase();
    }
    final String day = DateTime.now().day.toString().padLeft(2, '0');
    _passwordController.text = randomPart + day;
  }
  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _currentPassword));
    _showSnackBar('Password copied to clipboard', Icons.content_copy);
  }
  void _submit() {
    if (_usernameController.text.isEmpty ||
        (_passwordMethod == 0 && _prefixController.text.isEmpty) ||
        (_passwordMethod == 1 && _currentPassword.isEmpty)) {
      _showSnackBar('Please fill in all required fields', Icons.error, isError: true);
      return;
    }
    final Account newAccount = Account(
      email: _emailController.text,
      username: _usernameController.text,
      password: _currentPassword,
      auth_code: _auth_codeController.text,
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
    _showSnackBar('Account saved successfully', Icons.check_circle);
  }
  void _clearFields() {
    _emailController.clear();
    _usernameController.clear();
    _auth_codeController.clear();
    _passwordController.clear();
    if (_passwordMethod == 1) {
      _generateRandomPassword();
    }
  }
  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
        final String filePath = '$downloadPath/fb_accounts_$dateTime.json';
        final File file = File(filePath);
        final String jsonData = jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
        await file.writeAsString(jsonData);
        _showSnackBar('Downloaded to Downloads/fb_saver', Icons.download);
      }
    } else {
      _showSnackBar('Storage permission denied', Icons.error, isError: true);
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
      _showSnackBar('${newAccounts.length} accounts imported successfully', Icons.upload);
    } catch (e) {
      _showSnackBar('Invalid JSON format', Icons.error, isError: true);
    }
  }
  void _editAccount(int index) {
    setState(() {
      _editingIndex = index;
      _emailController.text = _accounts[index].email;
      _usernameController.text = _accounts[index].username;
      _auth_codeController.text = _accounts[index].auth_code;
     
      // Detect password method and set appropriate controller
      final String password = _accounts[index].password;
      if (password.contains('@')) {
        _passwordMethod = 0;
        _prefixController.text = password.split('@').first;
      } else {
        _passwordMethod = 1;
        _passwordController.text = password;
      }
      _prefs.setInt('password_method', _passwordMethod);
    });
    _tabController.animateTo(0);
  }
  void _copyAccountPassword(int index) {
    Clipboard.setData(ClipboardData(text: _accounts[index].password));
    _showSnackBar('Password copied', Icons.content_copy);
  }
  void _deleteAccount(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete this account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _accounts.removeAt(index);
                });
                _saveAccounts();
                Navigator.of(context).pop();
                _showSnackBar('Account deleted', Icons.delete);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _clearAll() {
    if (_accounts.isEmpty) return;
   
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear All Accounts'),
          content: Text('Are you sure you want to delete all ${_accounts.length} accounts?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _accounts.clear();
                });
                _saveAccounts();
                Navigator.of(context).pop();
                _showSnackBar('All accounts deleted', Icons.clear_all);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary!,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('FB Saver', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Input'),
            Tab(icon: Icon(Icons.swap_vert), text: 'Import/Export'),
            Tab(icon: Icon(Icons.list), text: 'Saved'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Input
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_editingIndex != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.tertiary!.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary, size: 18),
                        const SizedBox(width: 8),
                        Text('Editing Account', style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        )),
                      ],
                    ),
                  ),
                if (_editingIndex != null) const SizedBox(height: 12),
               
                if (_showEmailInput) ...[
                  _buildInputField(_emailController, 'Email Address (Optional)', Icons.email),
                  const SizedBox(height: 12),
                ],
                _buildInputField(_usernameController, 'Username', Icons.person),
                const SizedBox(height: 12),
                _buildPasswordField(),
                const SizedBox(height: 12),
                _buildInputField(_auth_codeController, '2FA Code (Optional)', Icons.security),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: Icon(_editingIndex != null ? Icons.update : Icons.save, size: 20),
                        label: Text(_editingIndex != null ? 'Update' : 'Save Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _clearFields,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Icon(Icons.clear, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
         
          // Tab 2: Import/Export
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.download, color: Theme.of(context).colorScheme.secondary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Export Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Download all your saved accounts as a JSON file.',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _downloadJson,
                          icon: const Icon(Icons.file_download, size: 18),
                          label: const Text('Download JSON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.upload, color: Theme.of(context).colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Import Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Paste JSON data to import accounts.',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _importController,
                          decoration: const InputDecoration(
                            labelText: 'Paste JSON here',
                            hintText: 'Paste your exported JSON data...',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 6,
                          minLines: 6,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _importJson,
                          icon: const Icon(Icons.file_upload, size: 18),
                          label: const Text('Import JSON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
         
          // Tab 3: Saved
          Column(
            children: [
              if (_accounts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${_accounts.length} accounts saved',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _accounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No accounts saved yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                            const SizedBox(height: 6),
                            Text('Add your first account in the Input tab',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _accounts.length,
                        itemBuilder: (context, i) {
                          final int accountIndex = _accounts.length - 1 - i;
                          final Account acc = _accounts[accountIndex];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (acc.email.isNotEmpty)
                                              Text(acc.email, style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.bold)),
                                            Text(acc.username, style: TextStyle(
                                              color: Colors.grey.shade600, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.lock, size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text('Password: ${acc.password}', style: const TextStyle(fontSize: 13))),
                                          ],
                                        ),
                                        if (acc.auth_code.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.security, size: 14),
                                              const SizedBox(width: 6),
                                              Expanded(child: Text('2FA: ${acc.auth_code}', style: const TextStyle(fontSize: 13))),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _editAccount(accountIndex),
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _copyAccountPassword(accountIndex),
                                        icon: const Icon(Icons.content_copy, size: 14),
                                        label: const Text('Copy', style: TextStyle(fontSize: 12)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _deleteAccount(accountIndex),
                                        icon: const Icon(Icons.delete, size: 14),
                                        label: const Text('Delete', style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context).colorScheme.error,
                                        ),
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
          // Tab 4: Settings
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.email, color: Theme.of(context).colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Email Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Show Email Input', style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  )),
                                  Text('Toggle email field visibility in input form',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _showEmailInput,
                              onChanged: (value) {
                                setState(() {
                                  _showEmailInput = value;
                                });
                                _prefs.setBool('show_email_input', value);
                              },
                              activeColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.password, color: Theme.of(context).colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Password Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment<int>(
                              value: 0,
                              label: Text('Prefix Method'),
                            ),
                            ButtonSegment<int>(
                              value: 1,
                              label: Text('Word Method'),
                            ),
                          ],
                          selected: {_passwordMethod},
                          onSelectionChanged: (Set<int> newSelection) {
                            setState(() {
                              _passwordMethod = newSelection.first;
                              if (_passwordMethod == 1 && _passwordController.text.isEmpty) {
                                _generateRandomPassword();
                              }
                            });
                            _prefs.setInt('password_method', _passwordMethod);
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_passwordMethod == 0) ..._buildPrefixMethodSettings(),
                        if (_passwordMethod == 1) ..._buildWordMethodSettings(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Theme.of(context).colorScheme.secondary, size: 20),
                            const SizedBox(width: 8),
                            const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('FB Saver v2.0',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Secure FBgram account manager',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  List<Widget> _buildPrefixMethodSettings() {
    return [
      TextField(
        controller: _prefixController,
        decoration: InputDecoration(
          labelText: 'Password Prefix',
          hintText: 'Enter your password prefix',
          prefixIcon: Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: _copyPassword,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Password Format:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 13,
              )),
            const SizedBox(height: 4),
            Text('${_prefixController.text.isNotEmpty ? _prefixController.text : '(prefix)'}@${DateTime.now().day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Example: If prefix is "Yaseen" and today is ${DateTime.now().day}, password will be: Yaseen@${DateTime.now().day.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    ];
  }
  List<Widget> _buildWordMethodSettings() {
    return [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Date: ${DateTime.now().day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 13,
              )),
            const SizedBox(height: 4),
            Text('Generated passwords will be random mixed case letters (8-13 chars) appended with today\'s date (2 digits).',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            const SizedBox(height: 6),
            Text('Total length: 10-15 characters. You can generate and edit in the Input tab.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    ];
  }
  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
  Widget _buildPasswordField() {
    final theme = Theme.of(context);
    if (_passwordMethod == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password', style: TextStyle(color: Colors.grey.shade700, fontSize: 14,)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _currentPassword.isEmpty ? 'Configure password in Settings' : _currentPassword,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _currentPassword.isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _copyPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.content_copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Format: (prefix)@(today\'s date) • Today is ${DateTime.now().day.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password', style: TextStyle(color: Colors.grey.shade700, fontSize: 14,)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Generate or enter password',
              prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generateRandomPassword,
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy),
                      onPressed: _copyPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Format: Random mixed case letters + date • 10-15 chars',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      );
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _auth_codeController.dispose();
    _importController.dispose();
    _prefixController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}