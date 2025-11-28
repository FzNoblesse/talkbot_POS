import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dashborard_sreen.dart';

class LoginScreen extends StatefulWidget
{
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
{
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";

  void _iniciarSesion() async
  {
    setState
    (()
    {
      _isLoading = true;
      _errorMessage = "";
    });

    String user = _userController.text.trim();
    String pass = _passController.text.trim();
    
    var usuarioEncontrado = await DatabaseHelper().login(user, pass);
    setState
    (()
    {
      _isLoading = false;
    });

    if (usuarioEncontrado != null)
    {
      if (!mounted) return;
      Navigator.pushReplacement
      (
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(usuario: usuarioEncontrado)),
      );
    }
    else
    {
      setState(()
      {
        _errorMessage = "Usuario o contraseña incorrectos";
      });
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      backgroundColor: Colors.blue.shade800,
      body: Center
      (
        child: Card
        (
          elevation: 8,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container
          (
            width: 350,
            padding: const EdgeInsets.all(30.0),
            child: Column
            (
              mainAxisSize: MainAxisSize.min,
              children:
              [
                const Icon(Icons.storefront, size: 60, color: Colors.blue),
                const SizedBox(height: 10),
                const Text
                (
                  "Bienvenido",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                TextField
                (
                  controller: _userController,
                  decoration: const InputDecoration
                  (
                    labelText: "Usuario",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                
                TextField
                (
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration
                  (
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                
                if (_errorMessage.isNotEmpty)
                  Padding
                  (
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  ),

                const SizedBox(height: 30),
                
                SizedBox
                (
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton
                  (
                    style: ElevatedButton.styleFrom
                    (
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _iniciarSesion,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("INGRESAR AL SISTEMA", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}