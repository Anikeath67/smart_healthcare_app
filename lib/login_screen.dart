import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final idController = TextEditingController();
  final passController = TextEditingController();

  static const BASE_URL = "http://192.168.1.3:3000";

  // ================= LOGIN =================
  Future<void> login() async {
    final res = await http.post(
      Uri.parse("$BASE_URL/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "provider_id": idController.text,
        "access_key": passController.text,
      }),
    );

    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      showMsg("Invalid credentials");
    }
  }

  // ================= REGISTER =================
  Future<void> register() async {
    final res = await http.post(
      Uri.parse("$BASE_URL/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "provider_id": idController.text,
        "access_key": passController.text,
      }),
    );

    final data = jsonDecode(res.body);
    showMsg(data["message"]);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "CAMPCARE LOGIN",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: idController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Provider ID",
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Access Key",
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: login,
                child: const Text("LOGIN"),
              ),

              ElevatedButton(
                onPressed: register,
                child: const Text("REGISTER"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}