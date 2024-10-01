import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EmotionChartScreen extends StatefulWidget {
  @override
  _EmotionChartScreenState createState() => _EmotionChartScreenState();
}

class _EmotionChartScreenState extends State<EmotionChartScreen> {
  late SharedPreferences _prefs;
  Map<String, Map<String, int>> allData = {};
  String? selectedDay;
  Map<String, int> emotionDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

  void _onBarTap(String day) {
    setState(() {
      selectedDay = day;
      emotionDistribution = allData[day] ?? {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotion Charts')),
      body: allData.isEmpty
          ? const Center(child: Text('No data available'))
          : Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  """Here's your usage!""",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 300,
                  child: _buildBarChart(),
                ),
                if (selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Emotion Distribution for $selectedDay',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (selectedDay != null)
                  SizedBox(
                    height: 300,
                    child: _buildPieChart(),
                  ),
                if (selectedDay != null) _buildLegend(),
              ],
            ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        
        alignment: BarChartAlignment.spaceAround,
        maxY: 60, // Adjust based on the expected maximum time
        barGroups: _getCurrentWeekDays().map((day) {
          return BarChartGroupData(
            x: DateFormat('yyyy-MM-dd').parse(day).weekday, // Use weekday as x value
            barRods: [
              BarChartRodData(
                toY: _getTotalTimeForDay(day).toDouble(),
                color: _getColorForDay(day), // Use dynamic color based on the day
                width: 20,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }).toList(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)), 
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)), // Hide left titles
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Map the weekdays to their names
                    switch (value.toInt()) {
                      case 1:
                        return Text('Mon', style: TextStyle(color: Colors.black));
                      case 2:
                        return Text('Tue', style: TextStyle(color: Colors.black));
                      case 3:
                        return Text('Wed', style: TextStyle(color: Colors.black));
                      case 4:
                        return Text('Thu', style: TextStyle(color: Colors.black));
                      case 5:
                        return Text('Fri', style: TextStyle(color: Colors.black));
                      case 6:
                        return Text('Sat', style: TextStyle(color: Colors.black));
                      case 7:
                        return Text('Sun', style: TextStyle(color: Colors.black));
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
              final day = _getCurrentWeekDays()[barTouchResponse.spot!.touchedBarGroupIndex];
              _onBarTap(day);
            }
          },
        ),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
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
}
