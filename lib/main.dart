import 'package:flutter/material.dart';
import 'screens/busqueda_articulo_screen.dart';

// Función principal: punto de entrada de la aplicación Flutter
void main() => runApp(const MyApp());

// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructor constante, útil para mejorar el rendimiento si el widget no cambia

  @override
  Widget build(BuildContext context) {
    // MaterialApp define la configuración global de la app
    return MaterialApp(
      // Título de la aplicación (se ve al instalar la app o en el selector de apps)
      title: 'Buscador Trivalle',

      // Tema visual global de la app (colores, fuentes, estilos)
      theme: ThemeData(
        // Paleta de colores principal basada en un color semilla (azul)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),

        // Color de fondo por defecto para toda la app
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        // Estilos de texto globales para toda la app
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
          bodyMedium: TextStyle(fontSize: 18),
        ),

        // Estilo global para todos los campos de texto (InputDecoration)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF1F5F9), // Color de fondo de los inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)), // Bordes redondeados
            borderSide: BorderSide.none, // Sin borde visible
          ),
        ),

        // Estilo global para todas las barras superiores (AppBar)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // Color de fondo de la AppBar
          elevation: 4, // Sombra bajo la barra
          centerTitle: true, // Centra el título
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24), // Bordes redondeados solo abajo
            ),
          ),
        ),
      ),

      // Pantalla principal que se muestra al abrir la app
      home: const BusquedaArticuloScreen(),

      // Elimina la etiqueta de DEBUG en la esquina superior derecha en modo debug
      debugShowCheckedModeBanner: false,
    );
  }
}
