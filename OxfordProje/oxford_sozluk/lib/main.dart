import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const OxfordApp());
}

class OxfordApp extends StatelessWidget {
  const OxfordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oxford 3000',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FlutterTts flutterTts;
  
  List<dynamic> allWords = [];
  List<dynamic> todaysWords = [];
  List<dynamic> oldWords = [];
  
  bool isLoading = true;
  int currentDay = 1;
  static const int wordsPerDay = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTts();
    _initializeData();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    currentDay = prefs.getInt('current_day') ?? 1;

    final String response = await rootBundle.loadString('assets/words.json');
    final List<dynamic> data = json.decode(response);

    setState(() {
      allWords = data;
      _distributeWords();
      isLoading = false;
    });
  }

  Future<void> _advanceDay() async {
    bool confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Günü Tamamla"),
        content: Text("$currentDay. gün bitti mi? Yeni kelimelere geçilecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hayır")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet, İlerle")),
        ],
      )
    ) ?? false;

    if (confirm) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        currentDay++;
        _distributeWords();
      });
      await prefs.setInt('current_day', currentDay);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$currentDay. Güne Geçildi!"), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _previousDay() async {
    if (currentDay <= 1) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentDay--;
      _distributeWords();
    });
    await prefs.setInt('current_day', currentDay);
  }

  void _distributeWords() {
    int startIndex = (currentDay - 1) * wordsPerDay;
    int endIndex = startIndex + wordsPerDay;

    if (startIndex < allWords.length) {
      int finalIndex = endIndex > allWords.length ? allWords.length : endIndex;
      todaysWords = allWords.sublist(startIndex, finalIndex);
    } else {
      todaysWords = []; 
    }

    if (startIndex > 0) {
      int oldWordsEndIndex = startIndex > allWords.length ? allWords.length : startIndex;
      oldWords = allWords.sublist(0, oldWordsEndIndex);
      oldWords.shuffle();
    } else {
      oldWords = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Oxford 3000", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("$currentDay. Gün", style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _previousDay,
            tooltip: "Önceki Güne Dön",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Çalış (${todaysWords.length})'),
            Tab(text: 'Tekrar (${oldWords.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _advanceDay,
        label: const Text("Günü Bitir"),
        icon: const Icon(Icons.check_circle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWordList(todaysWords, isToday: true),
          _buildWordList(oldWords, isToday: false),
        ],
      ),
    );
  }

  Widget _buildWordList(List<dynamic> words, {required bool isToday}) {
    if (words.isEmpty) {
      return Center(child: Text(isToday ? "Tüm kelimeler bitti!" : "Henüz geçmiş kelime yok."));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Card(
          elevation: isToday ? 3 : 1,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isToday ? Colors.indigo.shade100 : Colors.grey.shade200,
              child: Text("${index + 1}"),
            ),
            title: Text(
              word['en'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(word['tr'], style: const TextStyle(fontSize: 16)),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Colors.indigo),
              onPressed: () {
                _speak(word['en']);
              },
            ),
          ),
        );
      },
    );
  }
}