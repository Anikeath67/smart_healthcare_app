import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'sync_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  Future<Map<String, dynamic>> getData() async {
    int pending = await DBHelper.getTotalPendingSync();
    int total = await DBHelper.getTotalPatients();
    int today = await DBHelper.getTodayPatients();
    List<int> weekly = await DBHelper.getWeeklyPatientData();

    return {
      "pending": pending,
      "total": total,
      "today": today,
      "weekly": weekly,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await SyncService.syncAllCamps();
              setState(() {});
            },
          )
        ],
      ),

      body: FutureBuilder(
        future: getData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data as Map<String, dynamic>;

          int pending = data["pending"];
          int total = data["total"];
          int today = data["today"];
          List<int> weekly = data["weekly"];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              /// 🔥 SYNC CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.teal.shade300],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SYNC STATUS",
                        style: TextStyle(color: Colors.white70)),

                    const SizedBox(height: 10),

                    Text(
                      "$pending Records Pending",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: pending == 0 ? 1 : 0.4,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                      ),
                      onPressed: () async {
                        await SyncService.syncAllCamps();
                        setState(() {});
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text("Sync Now"),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 📊 STATS
              Row(
                children: [
                  Expanded(child: statCard("Patients", total, Icons.people)),
                  const SizedBox(width: 10),
                  Expanded(child: statCard("Today", today, Icons.today)),
                ],
              ),

              const SizedBox(height: 20),

              /// 📈 CHART
              const Text("Weekly Visits",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              Container(
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ["M", "T", "W", "T", "F", "S", "S"];
                            return Text(days[value.toInt()]);
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(7, (i) {
                      return makeBar(i, weekly[i].toDouble());
                    }),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  /// 📊 CARD
  Widget statCard(String title, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 8),
          Text(value.toString(),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title),
        ],
      ),
    );
  }

  /// 📊 BAR
  BarChartGroupData makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 14,
          borderRadius: BorderRadius.circular(4),
          color: Colors.teal,
        )
      ],
    );
  }
}