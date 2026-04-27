
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final idController = TextEditingController();
  final passController = TextEditingController();

  static const BASE_URL = "http://192.168.1.4:3000";

  bool isLoading = false;

  // ================= LOGIN =================
  Future<void> login() async {
    if (idController.text.isEmpty || passController.text.isEmpty) {
      showMsg("Enter credentials");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http
          .post(
            Uri.parse("$BASE_URL/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "provider_id": idController.text,
              "access_key": passController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      if (data["status"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("doctor_id", data["doctor_id"]);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        showMsg(data["message"] ?? "Invalid credentials");
      }
    } catch (e) {
      showMsg("Cannot connect to server");
    }

    setState(() => isLoading = false);
  }

  // ================= REGISTER =================
  Future<void> register() async {
    if (idController.text.isEmpty || passController.text.isEmpty) {
      showMsg("Enter credentials");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http
          .post(
            Uri.parse("$BASE_URL/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "provider_id": idController.text,
              "access_key": passController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      showMsg(data["message"] ?? "Registered successfully");
    } catch (e) {
      showMsg("Network error");
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
            
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // logo 
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "CAMPCARE",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  // fill up with login crendital
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: idController,
                            decoration: InputDecoration(
                              labelText: "Provider ID",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: passController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Access Key",
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔹 BUTTONS
                  isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("LOGIN"),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: register,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "REGISTER",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
