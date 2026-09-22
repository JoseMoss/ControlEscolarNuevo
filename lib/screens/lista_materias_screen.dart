// Importamos la librería principal de Flutter para componentes visuales
import 'package:flutter/material.dart';

// Importamos Cloud Firestore para interactuar con la base de datos en la nube
import 'package:cloud_firestore/cloud_firestore.dart';

// Importamos la pantalla de actividades para conectar la navegación
import 'package:control_escolar/screens/lista_actividades_screen.dart';

// Importamos la pantalla de asistencias que acabamos de crear
import 'package:control_escolar/screens/asistencia_screen.dart';

// Importamos la pantalla del reporte mensual de asistencias
import 'package:control_escolar/screens/reporte_asistencia_screen.dart';

/// Pantalla que muestra el listado de materias registradas en Firestore
/// en tiempo real y permite seleccionarlas para ver sus actividades, pasar lista o ver reportes.
class ListaMateriasScreen extends StatelessWidget {
  const ListaMateriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior de la pantalla
      appBar: AppBar(
        title: const Text("Materias Registradas"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // StreamBuilder para escuchar los cambios en tiempo real de la colección 'materias'
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('materias').snapshots(),
        builder: (context, snapshot) {
          // 1. Manejo de errores en la conexión con la base de datos
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las materias'));
          }

          // 2. Indicador de carga mientras Firestore responde
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Obtenemos la lista de documentos obtenidos de la colección
          final docs = snapshot.data!.docs;

          // 3. Validación si la colección está vacía
          if (docs.isEmpty) {
            return const Center(
              child: Text('No hay materias registradas aún.'),
            );
          }

          // 4. Construcción dinámica de la lista de materias en pantalla
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final materiaId = doc.id; // ID único del documento en Firestore
              final nombre = data['nombre'] ?? 'Sin Nombre';
              final descripcion = data['descripcion'] ?? '';
              final grado = data['grado'] ?? 'Sin Grado';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.book)),
                  title: Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$grado\n$descripcion'),
                  isThreeLine: true,

                  // Botones de acción rápida a la derecha de cada tarjeta
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón para ver el Reporte Mensual de Asistencias
                      IconButton(
                        icon: const Icon(
                          Icons.assignment_turned_in,
                          color: Colors.blue,
                        ),
                        tooltip: 'Ver Reporte Mensual',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReporteAsistenciaScreen(
                                materiaId: materiaId,
                                nombreMateria: nombre,
                                gradoMateria: grado,
                              ),
                            ),
                          );
                        },
                      ),
                      // Botón para ir al control de Asistencias del día
                      IconButton(
                        icon: const Icon(Icons.fact_check, color: Colors.green),
                        tooltip: 'Pase de Lista / Asistencia',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AsistenciaScreen(
                                materiaId: materiaId,
                                nombreMateria: nombre,
                                gradoMateria: grado, // Pasa el grado exacto para filtrar los alumnos
                              ),
                            ),
                          );
                        },
                      ),
                      // Flecha indicadora para entrar a las actividades de la materia
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  // 5. Acción al tocar toda la tarjeta: Navega a la lista de actividades
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListaActividadesScreen(
                          materiaId: materiaId,
                          nombreMateria: nombre,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
