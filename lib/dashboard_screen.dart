import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'sync_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder(
            future: Future.wait([
              DBHelper.getTotalPatients(),
              DBHelper.getTodayPatients(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final patients = snapshot.data![0] as int;
              final today = snapshot.data![1] as int;

              return ListView(
                children: [

                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dashboard",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Healthcare Overview",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(Icons.person, color: Colors.teal),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// STATS (ONLY 2 CARDS)
                  Row(
                    children: [
                      Expanded(
                        child: dashCard(
                          "Patients",
                          patients,
                          Icons.people,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: dashCard(
                          "Today",
                          today,
                          Icons.today,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// LINE GRAPH
                  const Text(
                    "Weekly Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  FutureBuilder<List<int>>(
                    future: DBHelper.getWeeklyPatientData(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();

                      final data = snap.data!;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 241, 241, 241),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),

                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const days = ["M","T","W","T","F","S","S"];
                                      return Text(
                                        days[value.toInt()],
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              borderData: FlBorderData(show: false),

                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.teal,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),

                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.teal.withOpacity(0.2),
                                  ),

                                  spots: List.generate(
                                    data.length,
                                    (i) => FlSpot(
                                      i.toDouble(),
                                      data[i].toDouble(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  /// QUICK ACTIONS
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: actionCard(
                          context,
                          "Add Camp",
                          Icons.add,
                          Colors.blue,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Go to Camps tab"),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: actionCard(
                          context,
                          "Sync Now",
                          Icons.sync,
                          Colors.orange,
                          () async {
                            await SyncService.syncAll();
                          //  await SyncService.syncAllCamps();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sync Completed"),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// INFO
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.teal),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Data syncs automatically when internet is available.",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= DASH CARD =================

  Widget dashCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= ACTION CARD =================

  Widget actionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'db_helper.dart';
// import 'sync_service.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {

//   // ================= SYNC FUNCTION =================
//   Future<void> handleSync() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(
//         child: CircularProgressIndicator(),
//       ),
//     );

//     await SyncService.syncAll();

//     if (!mounted) return;

//     Navigator.pop(context); // close loader

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("All data synced")),
//     );

//     setState(() {}); // refresh UI
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF366288),
//               Color(0xFF6A7681),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16),

//             child: FutureBuilder(
//               future: Future.wait([
//                 DBHelper.getTotalPatients(),
//                 DBHelper.getTodayPatients(),
//               ]),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(
//                     child: CircularProgressIndicator(color: Colors.white),
//                   );
//                 }

//                 final patients = snapshot.data![0] as int;
//                 final today = snapshot.data![1] as int;

//                 return ListView(
//                   children: [

//                     // ================= HEADER =================
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Dashboard",
//                               style: TextStyle(
//                                 fontSize: 26,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             Text(
//                               "Healthcare Overview",
//                               style: TextStyle(color: Colors.white70),
//                             ),
//                           ],
//                         ),
//                         const CircleAvatar(
//                           backgroundColor: Colors.white24,
//                           child: Icon(Icons.person, color: Colors.white),
//                         )
//                       ],
//                     ),

//                     const SizedBox(height: 20),

//                     // ================= STATS =================
//                     Row(
//                       children: [
//                         Expanded(
//                           child: dashCard(
//                             "Patients",
//                             patients,
//                             Icons.people,
//                             Colors.green,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: dashCard(
//                             "Today",
//                             today,
//                             Icons.today,
//                             Colors.purple,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 25),

//                     // ================= GRAPH =================
//                     const Text(
//                       "Weekly Activity",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     FutureBuilder<List<int>>(
//                       future: DBHelper.getWeeklyPatientData(),
//                       builder: (context, snap) {
//                         if (!snap.hasData) return const SizedBox();

//                         final data = snap.data!;

//                         return glassCard(
//                           SizedBox(
//                             height: 200,
//                             child: LineChart(
//                               LineChartData(
//                                 gridData: FlGridData(show: true),
//                                 titlesData: FlTitlesData(
//                                   leftTitles: AxisTitles(
//                                     sideTitles: SideTitles(showTitles: true),
//                                   ),
//                                   bottomTitles: AxisTitles(
//                                     sideTitles: SideTitles(
//                                       showTitles: true,
//                                       getTitlesWidget: (value, meta) {
//                                         const days = ["M","T","W","T","F","S","S"];
//                                         return Text(
//                                           days[value.toInt()],
//                                           style: const TextStyle(fontSize: 10),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                                 borderData: FlBorderData(show: false),
//                                 lineBarsData: [
//                                   LineChartBarData(
//                                     isCurved: true,
//                                     color: Colors.teal,
//                                     barWidth: 3,
//                                     dotData: FlDotData(show: true),
//                                     belowBarData: BarAreaData(
//                                       show: true,
//                                       color: Colors.teal.withOpacity(0.2),
//                                     ),
//                                     spots: List.generate(
//                                       data.length,
//                                       (i) => FlSpot(
//                                         i.toDouble(),
//                                         data[i].toDouble(),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),

//                     const SizedBox(height: 30),

//                     // ================= ACTIONS =================
//                     const Text(
//                       "Quick Actions",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     Row(
//                       children: [
//                         Expanded(
//                           child: actionCard(
//                             "Add Camp",
//                             Icons.add,
//                             Colors.blue,
//                             () {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text("Go to Camps tab"),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: actionCard(
//                             "Sync Now",
//                             Icons.sync,
//                             Colors.orange,
//                             handleSync, // 🔥 SAFE SYNC
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 20),

//                     // ================= INFO =================
//                     glassCard(
//                       const Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.white),
//                           SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               "Data syncs automatically when internet is available.",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= GLASS CARD =================
//   Widget glassCard(Widget child) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: child,
//     );
//   }

//   // ================= DASH CARD =================
//   Widget dashCard(String title, int value, IconData icon, Color color) {
//     return glassCard(
//       Row(
//         children: [
//           Icon(icon, color: color),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               Text(
//                 title,
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= ACTION CARD =================
//   Widget actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: color),
//             const SizedBox(height: 6),
//             Text(title, style: const TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),
//     );
//   }
// }