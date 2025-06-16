import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/articulo.dart';
import '../db/database.dart';

// Pantalla principal donde se hace la búsqueda y gestión de artículos
class BusquedaArticuloScreen extends StatefulWidget {
  const BusquedaArticuloScreen({super.key});

  @override
  State<BusquedaArticuloScreen> createState() => _BusquedaArticuloScreenState();
}

class _BusquedaArticuloScreenState extends State<BusquedaArticuloScreen> {
  final TextEditingController txtVBusquedaArticuloNombre = TextEditingController();
  final ScrollController scrollVBusquedaArticuloResultado = ScrollController();

  String strVBusquedaArticuloResultado = '';
  String? strVBusquedaArticuloError;
  bool blnVBusquedaArticuloCargando = false;

  List<Map<String, dynamic>> articulosGuardados = [];
  List<bool> seleccionadosGuardados = [];
  List<Articulo> articulosBusqueda = [];
  List<bool> seleccionados = [];

  @override
  void initState() {
    super.initState();
    cargarArticulosGuardados();
  }

  Future<void> cargarArticulosGuardados() async {
    articulosGuardados = await DatabaseHelper.obtenerArticulos();
    seleccionadosGuardados = List.generate(articulosGuardados.length, (index) => false);
    setState(() {});
  }

  Future<void> guardarSeleccionadosEnBD() async {
    int guardados = 0;
    for (int i = 0; i < articulosBusqueda.length; i++) {
      if (seleccionados[i]) {
        final art = articulosBusqueda[i];
        await DatabaseHelper.insertarArticulo(art.codigo, art.nombre, art.descripcion, art.pvp1);
        guardados++;
      }
    }
    await cargarArticulosGuardados();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Se guardaron $guardados artículos seleccionados en la base de datos")),
    );
  }

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

  Future<void> eliminarTodosGuardados() async {
    await DatabaseHelper.eliminarTodosLosArticulos();
    await cargarArticulosGuardados();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Se eliminaron todos los artículos guardados")),
    );
  }

  void _parsearResultados() {
    articulosBusqueda.clear();
    seleccionados.clear();

    final lineas = strVBusquedaArticuloResultado.split('\n');
    final datos = lineas.where((l) => l.trim().isNotEmpty && !l.startsWith("Tabla")).toList();

    for (var linea in datos) {
      final campos = linea.split(';');
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
        seleccionados.add(false);
      }
    }
  }

  Future<void> btnVBusquedaArticuloBuscar_onPressed() async {
    setState(() {
      blnVBusquedaArticuloCargando = true;
      strVBusquedaArticuloResultado = '';
      strVBusquedaArticuloError = null;
      articulosBusqueda.clear();
      seleccionados.clear();
    });

    final String nombreArticulo = txtVBusquedaArticuloNombre.text.trim();
    if (nombreArticulo.isEmpty) {
      setState(() {
        strVBusquedaArticuloResultado = '';
        strVBusquedaArticuloError = 'Introduce el nombre de un artículo.';
        blnVBusquedaArticuloCargando = false;
      });
      return;
    }

    final String url =
        'https://www.trivalle.com/api/trvTrivalle.php?Token=LojGUjH5C3Pifi5l6vck&Bd=qahg530&Code=104&Empresa=1&NomArticulo=${Uri.encodeComponent(nombreArticulo)}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': '*/*',
        },
      );
      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty || response.body.contains("no encontrado") || response.body.toLowerCase().contains("error")) {
          setState(() {
            strVBusquedaArticuloResultado = '';
            strVBusquedaArticuloError = 'No se encontraron resultados para "$nombreArticulo".';
            articulosBusqueda.clear();
            seleccionados.clear();
          });
        } else {
          setState(() {
            strVBusquedaArticuloResultado = response.body;
            strVBusquedaArticuloError = null;
            _parsearResultados();
          });
        }
      } else {
        setState(() {
          strVBusquedaArticuloResultado = '';
          strVBusquedaArticuloError = 'Error: Código de estado ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        strVBusquedaArticuloResultado = '';
        strVBusquedaArticuloError = 'Error al consultar la API: $e';
      });
    } finally {
      setState(() {
        blnVBusquedaArticuloCargando = false;
      });
    }
  }

  void btnVBusquedaArticuloLimpiar_on_pressed() {
    txtVBusquedaArticuloNombre.clear();
    setState(() {
      strVBusquedaArticuloResultado = '';
      strVBusquedaArticuloError = null;
      articulosBusqueda.clear();
      seleccionados.clear();
    });
  }

  // --- FUNCIÓN PARA HACER POST ---
  Future<void> insertarArticuloRemotoEjemplo() async {
    final url = 'https://www.trivalle.com/api/trvTrivalle.php';

    final Map<String, String> body = {
      'Token': 'LojGUjH5C3Pifi5l6vck',
      'Bd': 'qame400',
      'Code': '117',
      'CodEmp': '1',
      'CodArticulo': '1015000',
      'NomArticulo': 'Probando',
      'CodFamilia': '1',
      'Referencia': 'Ref1234',
      'Pvp1': '10',
      'Stock': '100',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': '*/*',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Respuesta POST: ${response.body}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error POST: ${response.statusCode} - ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de red: $e")),
      );
    }
  }

  @override
  void dispose() {
    txtVBusquedaArticuloNombre.dispose();
    scrollVBusquedaArticuloResultado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador Trivalle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Limpiar',
            onPressed: btnVBusquedaArticuloLimpiar_on_pressed,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 18),
              
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

              if (articulosGuardados.isNotEmpty)
                const Divider(
                  thickness: 2,
                  height: 32,
                  indent: 8,
                  endIndent: 8,
                ),

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
                              subtitle: Text('Código: ${articulo['codigo']}  ·  PVP: ${articulo['pvp1']} €'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
