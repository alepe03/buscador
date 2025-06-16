import 'package:sqflite/sqflite.dart';
// Importa path para construir rutas de archivos de manera segura entre plataformas
import 'package:path/path.dart';

// Clase que encapsula toda la lógica de la base de datos local (Singleton)
class DatabaseHelper {
  // Variable estática que guarda la instancia única de la base de datos
  static Database? _database;

  // Getter estático que devuelve la base de datos. Si no existe, la inicializa.
  static Future<Database> get database async {
    if (_database != null) return _database!; // Si ya existe, la retorna
    _database = await _initDB();              // Si no existe, la crea/inicializa
    return _database!;
  }

  // Método privado que inicializa y configura la base de datos
  static Future<Database> _initDB() async {
    // Obtiene la ruta del sistema donde guardar la base de datos
    String path = join(await getDatabasesPath(), 'trivalle.db');

    // Abre (o crea si no existe) la base de datos en la ruta especificada
    return await openDatabase(
      path,
      version: 1, // Versión de la base de datos (para migraciones futuras)
      onCreate: (db, version) async {
        // Crea la tabla 'articulos' si es la primera vez que se crea la base de datos
        await db.execute('''
          CREATE TABLE articulos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Clave primaria auto incremental
            codigo TEXT,                           -- Código del artículo
            nombre TEXT,                           -- Nombre del artículo
            descripcion TEXT,                      -- Descripción
            pvp1 TEXT                              -- Precio
          )
        ''');
      },
    );
  }

  // Inserta un artículo en la tabla 'articulos'
  static Future<void> insertarArticulo(String codigo, String nombre, String descripcion, String pvp1) async {
    final db = await database; // Obtiene la instancia de la base de datos
    await db.insert(
      'articulos',              // Tabla donde insertar
      {
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'pvp1': pvp1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Si hay un conflicto de clave, reemplaza el existente
    );
  }

  // Obtiene todos los artículos guardados en la tabla como una lista de mapas
  static Future<List<Map<String, dynamic>>> obtenerArticulos() async {
    final db = await database;
    return await db.query('articulos');
  }

  // Elimina un artículo por su id (clave primaria)
  static Future<void> eliminarArticulo(int id) async {
    final db = await database;
    await db.delete(
      'articulos',
      where: 'id = ?',         // Condición para borrar (solo el que tenga ese id)
      whereArgs: [id],
    );
  }

  // Elimina todos los artículos de la tabla (borrado masivo)
  static Future<void> eliminarTodosLosArticulos() async {
    final db = await database;
    await db.delete('articulos');
  }
}
