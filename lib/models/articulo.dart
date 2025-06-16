// Esta clase define el modelo de datos para un artículo.
// Usar una clase modelo hace que el manejo de datos sea más organizado, seguro y escalable.

class Articulo {
  // Atributos principales que describen cada artículo.

  final String codigo;       // Código identificador único del artículo (ej: "000234")
  final String nombre;       // Nombre del artículo (ej: "Plátano")
  final String descripcion;  // Descripción o detalle del artículo (puede repetirse con el nombre si la API no da más)
  final String pvp1;         // Precio de venta principal (ej: "1.25" euros como string)

  // Constructor de la clase. Se usa 'required' para obligar a que todos los campos estén presentes al crear un artículo.
  Articulo({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.pvp1,
  });
}
