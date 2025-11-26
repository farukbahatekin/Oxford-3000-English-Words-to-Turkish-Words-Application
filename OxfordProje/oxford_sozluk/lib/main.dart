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
  
  // DEĞİŞİKLİK 1: Eski kelimeleri artık "Gün Numarası -> Kelime Listesi" olarak tutuyoruz
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

  // DEĞİŞİKLİK 2: Kelimeleri dağıtırken eski günleri tek tek ayırıyoruz
  void _distributeWords() {
    // 1. Bugünün kelimelerini ayarla
    int startToday = (currentDay - 1) * wordsPerDay;
    int endToday = startToday + wordsPerDay;

    if (startToday < allWords.length) {
      int finalIndex = endToday > allWords.length ? allWords.length : endToday;
      todaysWords = allWords.sublist(startToday, finalIndex);
    } else {
      todaysWords = []; 
    }

    // 2. Eski günleri haritaya (Map) işle
    oldDaysMap.clear();
    // 1. günden başlayıp şu anki güne kadar (şu anki gün hariç) döngü kuruyoruz
    for (int day = 1; day < currentDay; day++) {
      int start = (day - 1) * wordsPerDay;
      int end = start + wordsPerDay;
      
      if (start < allWords.length) {
        int finalEnd = end > allWords.length ? allWords.length : end;
        // O güne ait kelimeleri listeye koyup haritaya ekliyoruz
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
            // Tekrar sekmesinde toplam kaç gün olduğunu gösterelim
            Tab(text: 'Tekrar (${oldDaysMap.length} Gün)'),
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
          // 1. Sekme: Bugün (Aynı)
          _buildTodayList(),
          // 2. Sekme: Eski Günler (YENİ GÖRÜNÜM)
          _buildOldDaysList(),
        ],
      ),
    );
  }

  // Bugünün listesi için widget
  Widget _buildTodayList() {
    if (todaysWords.isEmpty) {
      return const Center(child: Text("Tüm kelimeler bitti!"));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: todaysWords.length,
      itemBuilder: (context, index) {
        final word = todaysWords[index];
        return _buildWordCard(word, index + 1, true);
      },
    );
  }

  // DEĞİŞİKLİK 3: Eski günleri "Accordion" (Açılır/Kapanır) liste olarak gösteriyoruz
  Widget _buildOldDaysList() {
    if (oldDaysMap.isEmpty) {
      return const Center(child: Text("Henüz geçmiş gün yok.\nBir günü tamamladığında burada gözükecek."));
    }

    // Haritadaki günleri listeye çevirip ters çevirelim (En son gün en üstte olsun istersek reversed kullanırız)
    // Şimdilik 1. Gün en üstte olsun:
    var days = oldDaysMap.keys.toList(); 

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: days.length,
      itemBuilder: (context, index) {
        int dayNum = days[index]; // Gün numarası (örn: 1)
        List words = oldDaysMap[dayNum]!; // O günün kelimeleri

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            // Başlık kısmı
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: Text("$dayNum", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ),
            title: Text(
              "$dayNum. Gün",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${words.length} Kelime"),
            childrenPadding: const EdgeInsets.all(0),
            // Açılınca çıkacak kelimeler
            children: words.map((word) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200))
                ),
                child: ListTile(
                  dense: true, // Daha sıkı görünüm
                  title: Text(word['en'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(word['tr']),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up_rounded, size: 20, color: Colors.indigo),
                    onPressed: () => _speak(word['en']),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Tekrarlanan kart tasarımı (Temiz kod için ayırdım)
  Widget _buildWordCard(dynamic word, int index, bool isToday) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Text("$index"),
        ),
        title: Text(
          word['en'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(word['tr'], style: const TextStyle(fontSize: 16)),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up_rounded, color: Colors.indigo),
          onPressed: () => _speak(word['en']),
        ),
      ),
    );
  }
}