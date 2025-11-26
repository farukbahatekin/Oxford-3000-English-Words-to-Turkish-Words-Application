import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const OxfordApp());
}

class OxfordApp extends StatelessWidget {
  const OxfordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OX3000',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          secondary: const Color(0xFFF97316),
          background: const Color(0xFFF3F4F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        fontFamily: 'Roboto', 
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
  Map<int, List<dynamic>> oldDaysMap = {}; 
  
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
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text, String lang) async {
    await flutterTts.stop();
    if (text.isNotEmpty) {
      await flutterTts.setLanguage(lang);
      await flutterTts.speak(text);
    }
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    currentDay = prefs.getInt('current_day') ?? 1;

    try {
      final String response = await rootBundle.loadString('assets/words.json');
      final List<dynamic> data = json.decode(response);

      setState(() {
        allWords = data;
        _distributeWords();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _advanceDay() async {
    bool confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Tebrikler"),
        content: Text("$currentDay. günü tamamladın mı? Yeni kelimelere geçilecek."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Henüz Değil")),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text("Evet, Devam Et")
          ),
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
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Harika! $currentDay. Güne hoş geldin."), 
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
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
    int startToday = (currentDay - 1) * wordsPerDay;
    int endToday = startToday + wordsPerDay;

    if (startToday < allWords.length) {
      int finalIndex = endToday > allWords.length ? allWords.length : endToday;
      todaysWords = allWords.sublist(startToday, finalIndex);
    } else {
      todaysWords = []; 
    }

    oldDaysMap.clear();
    for (int day = 1; day < currentDay; day++) {
      int start = (day - 1) * wordsPerDay;
      int end = start + wordsPerDay;
      
      if (start < allWords.length) {
        int finalEnd = end > allWords.length ? allWords.length : end;
        oldDaysMap[day] = allWords.sublist(start, finalEnd);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Easy to B1 (EN-TR-DE)",
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w800,
                color: Colors.grey[800],
                letterSpacing: 0.5
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Level $currentDay",
                style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: Colors.grey[400]),
            onPressed: _previousDay,
            tooltip: "Geri Al",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            const Tab(text: 'Bugünü Çalış'),
            Tab(text: 'Arşiv (${oldDaysMap.length})'),
          ],
        ),
      ),
      
      floatingActionButton: Container(
        height: 65,
        width: 160,
        margin: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          onPressed: _advanceDay,
          elevation: 4,
          backgroundColor: const Color(0xFF4F46E5),
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: const Text(
            "Günü Bitir", 
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayList(),
          _buildOldDaysList(),
        ],
      ),
    );
  }

  Widget _buildTodayList() {
    if (todaysWords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
                "Tüm kelimeler bitti!\nTebrikler.", 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: todaysWords.length,
      itemBuilder: (context, index) {
        final word = todaysWords[index];
        return _buildFancyCard(word, index + 1);
      },
    );
  }

  Widget _buildOldDaysList() {
    if (oldDaysMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text("Henüz geçmiş gün yok.", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    var days = oldDaysMap.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: days.length,
      itemBuilder: (context, index) {
        int dayNum = days[index];
        List words = oldDaysMap[dayNum]!;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200)
          ),
          color: Colors.white,
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$dayNum", 
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))
              ),
            ),
            title: Text(
              "$dayNum. Gün Arşivi",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            subtitle: Text("${words.length} Kelime Öğrenildi"),
            childrenPadding: EdgeInsets.zero,
            children: words.map((word) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(word['en'], style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(word['tr'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            if (word['de'] != null)
                              Text(word['de'], style: const TextStyle(color: Color(0xFFE11D48), fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      _buildMiniSpeaker(word['en'], "en-US", const Color(0xFF4F46E5)),
                      const SizedBox(width: 8),
                      _buildMiniSpeaker(word['de'], "de-DE", const Color(0xFFE11D48)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFancyCard(dynamic word, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _speak(word['en'], "en-US"),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Center(
                    child: Text(
                      "$index",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word['en'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word['tr'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word['de'] ?? '', 
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFFE11D48), 
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    InkWell(
                      onTap: () => _speak(word['en'], "en-US"),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.volume_up_rounded, color: Color(0xFF4F46E5), size: 24),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                          var deText = word['de'];
                          if (deText != null && deText.toString().isNotEmpty) {
                            _speak(deText, "de-DE");
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Almanca ses henüz eklenmedi."), duration: Duration(milliseconds: 600))
                            );
                          }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.volume_up_rounded, color: Color(0xFFE11D48), size: 24),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSpeaker(dynamic text, String lang, Color color) {
    return InkWell(
      onTap: () {
        if (text != null && text.toString().isNotEmpty) {
          _speak(text, lang);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("$lang sesi yok."), duration: const Duration(milliseconds: 500))
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(Icons.volume_up_rounded, color: color, size: 22),
      ),
    );
  }
}