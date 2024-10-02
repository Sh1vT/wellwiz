import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/emotion/emotion_bot_screen.dart';
import 'package:wellwiz/features/navbar/navbar.dart';
import 'package:wellwiz/secrets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";
  String thought = "To be or not to be is the question";
  late final ChatSession _chat;
  static const _apiKey = geminikey;
  late final GenerativeModel _model;
  bool thoughtGenerated = false;
  Map<String, Map<String, int>> allData = {};
  String? selectedDay;
  Map<String, int> emotionDistribution = {};
  late SharedPreferences _prefs;
  int randomImageIndex = 1;

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      allData = _getAllEmotionData();
    });
  }

  Map<String, Map<String, int>> _getAllEmotionData() {
    Map<String, Map<String, int>> data = {};
    for (String key in _prefs.getKeys()) {
      String? jsonData = _prefs.getString(key);
      if (key == 'userimg' || key == 'username') {
        continue;
      }

      if (jsonData != null) {
        try {
          Map<String, dynamic> dayData =
              Map<String, dynamic>.from(jsonDecode(jsonData));
          data[key] = dayData.map((k, v) => MapEntry(k, v as int));
        } catch (e) {
          print('Error decoding JSON for key $key: $e');
        }
      }
    }
    return data;
  }

  List<String> _getCurrentWeekDays() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today
          .subtract(Duration(days: today.weekday - 1))
          .add(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    });
  }

  int _getTotalTimeForDay(String day) {
    if (allData[day] == null) return 0;
    return allData[day]!.values.reduce((a, b) => a + b);
  }

  void _onBarTap(String day) async {
    setState(() {
      selectedDay = day;
      emotionDistribution = allData[day] ?? {};
    });
    String prompt =
        """You are a mental health chatbot being used purely for demonstration purposes and not commercially or professionally.
    Here how the user has felt for a given day : $emotionDistribution. The distribution is a map of emotion and integer. The integer is the duration in minutes.
    Basically different predfined sessions are created and based on the session duration this integer is obtained.
    Generate a short 30-40 word insight summarising how the user felt and give your advice to the user too. If negative, tell user ways to make them feel positive.
    Start with: On this day you felt...""";
    var response = await _chat.sendMessage(Content.text(prompt));

    _showPieChartDialog(response.text!.replaceAll('\n', ''));
    print(emotionDistribution);
  }

  void _showPieChartDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Your chat sessions for $selectedDay',
            style: TextStyle(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Ensure the dialog size adjusts to content
              children: [
                SizedBox(
                  height: 200, // Fixed height for the pie chart
                  child: _buildPieChart(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      height: 45,
                      width: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 4), // Add spacing between pie chart and message
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(
                        255, 177, 221, 152), // Light blue color for the bubble
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12)), // Rounded corners
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.justify,
                    style:
                        TextStyle(fontSize: 14), // Adjust text size as needed
                  ),
                ) // Use a custom message bubble widget
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                      Color.fromARGB(255, 106, 172, 67))),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  void generateThought() async {
    print("e");
    String prompt =
        "Generate a deep philosophical Shakespearean thought for a mental health application that is purely for demonstration purposes and no commercial use. The thought has to be unique and should be positive. Respond with only the thought without formatting and nothing else. Keep the thought limited to 30 words.";
    var response = await _chat.sendMessage(Content.text(prompt));
    setState(() {
      thought = response.text!;
      thoughtGenerated = true;
    });
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'sad':
        return Colors.blue;
      case 'happy':
        return Colors.green;
      case 'angry':
        return Colors.red;
      case 'anxious':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  Color _getColorForDay(String day) {
    // Example: Change color dynamically based on the day
    switch (DateFormat('EEEE').format(DateFormat('yyyy-MM-dd').parse(day))) {
      case 'Monday':
        return Colors.blueAccent;
      case 'Tuesday':
        return Colors.greenAccent;
      case 'Wednesday':
        return Colors.orangeAccent;
      case 'Thursday':
        return Colors.purpleAccent;
      case 'Friday':
        return Colors.redAccent;
      case 'Saturday':
        return Colors.yellowAccent;
      case 'Sunday':
        return Colors.tealAccent;
      default:
        return Colors.black;
    }
  }

  bool _hasData() {
  List<String> currentWeekDays = _getCurrentWeekDays();
  return currentWeekDays.any((day) => _getTotalTimeForDay(day) > 0);
}

  Widget _buildBarChart() {

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60, // Adjust based on the expected maximum time
        barGroups: _getCurrentWeekDays().map((day) {
          return BarChartGroupData(
            x: DateFormat('yyyy-MM-dd')
                .parse(day)
                .weekday, // Use weekday as x value
            barRods: [
              BarChartRodData(
                toY: _getTotalTimeForDay(day).toDouble(),
                color:
                    _getColorForDay(day), // Use dynamic color based on the day
                width: 20,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }).toList(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)), // Hide left titles
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Map the weekdays to their names
                    switch (value.toInt()) {
                      case 1:
                        return Text('Mon',
                            style: TextStyle(color: Colors.black));
                      case 2:
                        return Text('Tue',
                            style: TextStyle(color: Colors.black));
                      case 3:
                        return Text('Wed',
                            style: TextStyle(color: Colors.black));
                      case 4:
                        return Text('Thu',
                            style: TextStyle(color: Colors.black));
                      case 5:
                        return Text('Fri',
                            style: TextStyle(color: Colors.black));
                      case 6:
                        return Text('Sat',
                            style: TextStyle(color: Colors.black));
                      case 7:
                        return Text('Sun',
                            style: TextStyle(color: Colors.black));
                      default:
                        return const Text('');
                    }
                  })),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String day = _getCurrentWeekDays()[group.x.toInt() - 1];
              return BarTooltipItem(
                '$day\n${rod.toY.toInt()} mins',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final day = _getCurrentWeekDays()[
                  barTouchResponse.spot!.touchedBarGroupIndex];
              _onBarTap(day);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: emotionDistribution.entries.map((entry) {
          final emotion = entry.key;
          final time = entry.value;

          return PieChartSectionData(
            color: _getColorForEmotion(emotion),
            value: time.toDouble(),
            title: '',
            radius: 60, // Adjust radius for better appearance
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: Text(
              emotion,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: emotionDistribution.entries.map((entry) {
        final emotion = entry.key;
        final color = _getColorForEmotion(emotion);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(emotion, style: TextStyle(fontSize: 16)), // Style text
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getUserInfo();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    generateThought();
    _loadData();
    randomImageIndex = (Random().nextInt(7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Navbar(
        userId: _auth.currentUser?.uid ?? '',
        username: username,
        userimg: userimg,
      ),
      body: ListView(
        padding: EdgeInsets.zero, // Optional: removes any default padding
        children: <Widget>[
          Container(
            height: 80,
            color: Colors.grey.shade50,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Wel",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          fontSize: 14,
                          color: Color.fromARGB(255, 106, 172, 67)),
                    ),
                    Text(
                      "Come",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          fontSize: 14,
                          color: const Color.fromRGBO(97, 97, 97, 1)),
                    ),
                    Text(
                      " to",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          fontSize: 14,
                          color: const Color.fromRGBO(97, 97, 97, 1)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Well",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          fontSize: 40,
                          color: Color.fromARGB(255, 106, 172, 67)),
                    ),
                    Text(
                      "Wiz",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          fontSize: 40,
                          color: const Color.fromRGBO(97, 97, 97, 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return BotScreen();
              }));
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 106, 172, 67),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12))),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to start
                      children: [
                        Text(
                          'Chat with Wizard',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          height: 2.0,
                          width: 180.0,
                          color: Colors.grey.shade800,
                        ),
                        Text(
                          'Your personal medical assistant',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontFamily: 'Mulish',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Bottom widget: "How do you feel today?" section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Color.fromARGB(255, 177, 221, 152),
              ),
              child: Column(
                children: [
                  // Heading
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        left: 30, right: 30, top: 20, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Or tell him how you feel...',
                        textAlign: TextAlign.center, // Center align text
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontSize: 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return EmotionBotScreen(emotion: "Happy");
                              }));
                            },
                            child: const Text(
                              'Happy',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20.0), // Space between buttons
                        Expanded(
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return EmotionBotScreen(emotion: "Sad");
                              }));
                            },
                            child: const Text(
                              'Sad',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return EmotionBotScreen(emotion: "Angry");
                              }));
                            },
                            child: const Text(
                              'Angry',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20.0),
                        Expanded(
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return EmotionBotScreen(emotion: "Anxious");
                              }));
                            },
                            child: const Text(
                              'Anxious',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return EmotionBotScreen(emotion: "Frustrated");
                              }));
                            },
                            child: const Text(
                              'Frustrated',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20.0),
                        Expanded(
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return EmotionBotScreen(emotion: "Stressed");
                              }));
                            },
                            child: const Text(
                              'Stressed',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),

          SizedBox(
            height: 20,
          ),
          _hasData()? Column(
            children: [
              const SizedBox(height: 20),
              Text(
                """Here's what Wizard found!""",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                """Records of your feelings throughout the week""",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.all(16),
                height: 300,
                child: _buildBarChart(),
              ),
            ],
          ):Container() ,
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(42),
                      topRight: Radius.circular(42)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // 16:9 aspect ratio
                    child: Image.asset(
                      'assets/thought/$randomImageIndex.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(42),
                      bottomRight: Radius.circular(42),
                    ),
                    color: Colors.grey.shade800,
                  ),
                  padding:
                      EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        thoughtGenerated
                            ? "“" + thought.replaceAll('\n', '') + "”"
                            : "Wizard is thinking...",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Mulish',
                            fontSize: 16),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          thoughtGenerated ? "- Wizard   " : "",
                          style: TextStyle(
                              fontFamily: 'Mulish',
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20,)
        ],
      ),
    );
  }
}
