import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/articulo.dart';      
import '../db/database.dart';        

// Pantalla principal donde se hace la búsqueda y gestión de artículos
class BusquedaArticuloScreen extends StatefulWidget {
  const BusquedaArticuloScreen({super.key}); // Constructor constante

  @override
  State<BusquedaArticuloScreen> createState() => _BusquedaArticuloScreenState();
}

// Estado asociado a la pantalla principal
class _BusquedaArticuloScreenState extends State<BusquedaArticuloScreen> {
  // Controlador para el campo de texto donde se escribe el nombre a buscar
  final TextEditingController txtVBusquedaArticuloNombre = TextEditingController();
  // Controlador para el scroll de los resultados (no imprescindible, pero útil si tienes muchos resultados)
  final ScrollController scrollVBusquedaArticuloResultado = ScrollController();

  // Variables de estado para la pantalla
  String strVBusquedaArticuloResultado = ''; // Guarda la respuesta cruda de la API (texto plano)
  String? strVBusquedaArticuloError;         // Mensaje de error si ocurre alguno
  bool blnVBusquedaArticuloCargando = false; // Para mostrar un loader mientras se busca

  // Listas para manejar los artículos guardados en BD y los buscados en la API
  List<Map<String, dynamic>> articulosGuardados = []; // Artículos guardados en la base de datos
  List<bool> seleccionadosGuardados = [];             // Cuáles están seleccionados para borrar
  List<Articulo> articulosBusqueda = [];              // Resultados actuales de la búsqueda
  List<bool> seleccionados = [];                      // Cuáles resultados están seleccionados para guardar

  @override
  void initState() {
    super.initState();
    cargarArticulosGuardados(); // Al iniciar la pantalla, carga los artículos ya guardados de la BD
  }

  // Carga los artículos guardados de la base de datos y actualiza la selección
  Future<void> cargarArticulosGuardados() async {
    articulosGuardados = await DatabaseHelper.obtenerArticulos();
    seleccionadosGuardados = List.generate(articulosGuardados.length, (index) => false);
    setState(() {}); // Redibuja la pantalla con la nueva información
  }

  // Guarda solo los artículos seleccionados de los resultados de búsqueda en la base de datos
  Future<void> guardarSeleccionadosEnBD() async {
    int guardados = 0;
    for (int i = 0; i < articulosBusqueda.length; i++) {
      if (seleccionados[i]) {
        final art = articulosBusqueda[i];
        await DatabaseHelper.insertarArticulo(art.codigo, art.nombre, art.descripcion, art.pvp1);
        guardados++;
      }
    }
    await cargarArticulosGuardados(); // Actualiza la lista de guardados tras guardar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Se guardaron $guardados artículos seleccionados en la base de datos")),
    );
  }

  // Guarda todos los resultados de búsqueda en la base de datos (no solo los seleccionados)
  Future<void> guardarTodosEnBD() async {
    int guardados = 0;
    for (final art in articulosBusqueda) {
      await DatabaseHelper.insertarArticulo(art.codigo, art.nombre, art.descripcion, art.pvp1);
      guardados++;
    }
    await cargarArticulosGuardados();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Se guardaron $guardados artículos en la base de datos")),
    );
  }

  // Elimina de la base de datos solo los artículos seleccionados por el usuario
  Future<void> eliminarSeleccionadosGuardados() async {
    int eliminados = 0;
    for (int i = 0; i < articulosGuardados.length; i++) {
      if (seleccionadosGuardados[i]) {
        final art = articulosGuardados[i];
        await DatabaseHelper.eliminarArticulo(art['id']);
        eliminados++;
      }
    }
    await cargarArticulosGuardados();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Se eliminaron $eliminados artículos seleccionados")),
    );
  }

  // Elimina todos los artículos guardados en la base de datos (borrado total)
  Future<void> eliminarTodosGuardados() async {
    await DatabaseHelper.eliminarTodosLosArticulos();
    await cargarArticulosGuardados();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Se eliminaron todos los artículos guardados")));
  }

  // Parsea el texto de resultados de la API y lo transforma en objetos Articulo
  void _parsearResultados() {
    articulosBusqueda.clear();
    seleccionados.clear();

    final lineas = strVBusquedaArticuloResultado.split('\n'); // Divide el resultado por líneas
    // Filtra líneas que no estén vacías ni empiecen por "Tabla"
    final datos = lineas.where((l) => l.trim().isNotEmpty && !l.startsWith("Tabla")).toList();

    for (var linea in datos) {
      final campos = linea.split(';'); // Cada campo viene separado por ;
      if (campos.length > 9) {
        final codigo = campos[2].trim();
        final nombre = campos[3].trim();
        final descripcion = campos[3].trim(); 
        final pvp1 = campos[9].trim(); 
        articulosBusqueda.add(Articulo(
          codigo: codigo,
          nombre: nombre,
          descripcion: descripcion,
          pvp1: pvp1,
        ));
        seleccionados.add(false); // Por defecto, no está seleccionado para guardar
      }
    }
  }

  // Función que se ejecuta cuando se pulsa el botón "Buscar"
  Future<void> btnVBusquedaArticuloBuscar_onPressed() async {
    setState(() {
      blnVBusquedaArticuloCargando = true;     // Muestra el loader (cargando)
      strVBusquedaArticuloResultado = '';
      strVBusquedaArticuloError = null;
      articulosBusqueda.clear();
      seleccionados.clear();
    });

    final String nombreArticulo = txtVBusquedaArticuloNombre.text.trim();
    if (nombreArticulo.isEmpty) {
      setState(() {
        strVBusquedaArticuloResultado = '';
        strVBusquedaArticuloError = 'Introduce el nombre de un artículo.'; // Mensaje si el campo está vacío
        blnVBusquedaArticuloCargando = false;
      });
      return;
    }

    // Construye la URL de la API con el nombre introducido
    final String url =
        'https://www.trivalle.com/api/trvTrivalle.php?Token=LojGUjH5C3Pifi5l6vck&Bd=qahg530&Code=104&Empresa=1&NomArticulo=${Uri.encodeComponent(nombreArticulo)}';

    try {
      // Hace la petición HTTP GET a la API de Trivalle
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0', // Agrega un User-Agent para evitar bloqueos por parte de la API
          'Accept': '*/*', 
        },
      );
      if (response.statusCode == 200) {
        // Si no hay resultados o hay un error en la respuesta
        if (response.body.trim().isEmpty || response.body.contains("no encontrado") || response.body.toLowerCase().contains("error")) {
          setState(() {
            strVBusquedaArticuloResultado = '';
            strVBusquedaArticuloError = 'No se encontraron resultados para "$nombreArticulo".';
            articulosBusqueda.clear();
            seleccionados.clear();
          });
        } else {
          // Si hay resultados, los guardo y los parseo
          setState(() {
            strVBusquedaArticuloResultado = response.body;
            strVBusquedaArticuloError = null;
            _parsearResultados();
          });
        }
      } else {
        // Si la API responde con error HTTP (no 200)
        setState(() {
          strVBusquedaArticuloResultado = '';
          strVBusquedaArticuloError = 'Error: Código de estado ${response.statusCode}';
        });
      }
    } catch (e) {
      // Si hay algún error de red o petición
      setState(() {
        strVBusquedaArticuloResultado = '';
        strVBusquedaArticuloError = 'Error al consultar la API: $e';
      });
    } finally {
      setState(() {
        blnVBusquedaArticuloCargando = false; // Oculta el loader (cargando)
      });
    }
  }

  // Limpia la búsqueda y reinicia el estado del input y los resultados
  void btnVBusquedaArticuloLimpiar_on_pressed() {
    txtVBusquedaArticuloNombre.clear();
    setState(() {
      strVBusquedaArticuloResultado = '';
      strVBusquedaArticuloError = null; // Limpia el mensaje de error
      articulosBusqueda.clear();
      seleccionados.clear();
    });
  }

  // Limpia los controladores de texto y scroll cuando se destruye la pantalla para liberar recursos
  @override
  void dispose() {
    txtVBusquedaArticuloNombre.dispose(); // Limpia el controlador del campo de texto
    scrollVBusquedaArticuloResultado.dispose(); // Limpia el controlador del scroll
    super.dispose();
  }

  // Construye toda la interfaz de la pantalla principal
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme; // Para estilos de texto globales

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador Trivalle'), // Título de la pantalla
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Limpiar',
            onPressed: btnVBusquedaArticuloLimpiar_on_pressed, // Botón para limpiar búsqueda y resultados
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ----------- INPUT DE BÚSQUEDA -----------
              TextField(
                controller: txtVBusquedaArticuloNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre del artículo',
                  hintText: 'Ejemplo: Platano',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                style: textTheme.bodyMedium,
                onSubmitted: (_) => btnVBusquedaArticuloBuscar_onPressed(),
              ),
              const SizedBox(height: 18),

              // ----------- BOTÓN DE BUSCAR -----------
              ElevatedButton(
                onPressed: blnVBusquedaArticuloCargando ? null : btnVBusquedaArticuloBuscar_onPressed,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                child: blnVBusquedaArticuloCargando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Buscar'),
              ),
              const SizedBox(height: 28),

              // ----------- MENSAJE DE ERROR (si ocurre) -----------
              if (strVBusquedaArticuloError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    strVBusquedaArticuloError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

              // ----------- RESULTADOS DE BÚSQUEDA -----------
              if (articulosBusqueda.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selecciona los artículos que quieras guardar:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                        // Lista de resultados de búsqueda con checkboxes para seleccionar
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: articulosBusqueda.length,
                          itemBuilder: (context, index) {
                            final articulo = articulosBusqueda[index];
                            return CheckboxListTile(
                              value: seleccionados[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  seleccionados[index] = value ?? false;
                                });
                              },
                              title: Text(articulo.nombre),
                              subtitle: Text('Código: ${articulo.codigo}  ·  PVP: ${articulo.pvp1} €'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Botón para guardar SOLO los seleccionados
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save, color: Colors.black),
                                label: const Text('Guardar SELECCIONADOS', style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[100],
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                onPressed: guardarSeleccionadosEnBD,
                              ),
                              const SizedBox(height: 10),
                              // Botón para guardar TODOS los resultados
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save_alt, color: Colors.black),
                                label: const Text('Guardar TODOS', style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[100],
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                onPressed: guardarTodosEnBD,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ----------- SEPARADOR si hay artículos guardados -----------
              if (articulosGuardados.isNotEmpty)
                const Divider(
                  thickness: 2,
                  height: 32,
                  indent: 8,
                  endIndent: 8,
                ),

              // ----------- LISTA DE ARTÍCULOS GUARDADOS -----------
              if (articulosGuardados.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Artículos guardados:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                        // Lista de artículos guardados en la base de datos, con checkboxes para seleccionar y eliminar
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: articulosGuardados.length,
                          itemBuilder: (context, index) {
                            final articulo = articulosGuardados[index];
                            return CheckboxListTile(
                              value: seleccionadosGuardados.length > index ? seleccionadosGuardados[index] : false,
                              onChanged: (bool? value) {
                                setState(() {
                                  seleccionadosGuardados[index] = value ?? false;
                                });
                              },
                              title: Text(articulo['nombre'] ?? ''),
                              subtitle: Text(
                                'Código: ${articulo['codigo']}  ·  PVP: ${articulo['pvp1']} €',
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Botón para eliminar SOLO los seleccionados
                            ElevatedButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.black),
                              label: const Text('Eliminar SELECCIONADOS', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[100],
                                foregroundColor: Colors.black,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: eliminarSeleccionadosGuardados,
                            ),
                            const SizedBox(height: 10),
                            // Botón para eliminar TODOS los guardados
                            ElevatedButton.icon(
                              icon: const Icon(Icons.delete_forever, color: Colors.black),
                              label: const Text('Eliminar TODOS', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[100],
                                foregroundColor: Colors.black,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: eliminarTodosGuardados,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
