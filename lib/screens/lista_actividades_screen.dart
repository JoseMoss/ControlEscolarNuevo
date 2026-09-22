// Importamos la librería principal de Flutter para componentes visuales
import 'package:flutter/material.dart';

// Importamos Cloud Firestore para consultar los datos en la nube
import 'package:cloud_firestore/cloud_firestore.dart';

// Importamos la pantalla del detalle de entregas por alumno
import 'package:control_escolar/screens/detalle_actividad_screen.dart';

/// Pantalla que muestra el listado de actividades creadas para una materia específica,
/// permitiendo filtrar por Grupo (A o B) y consultando los datos en tiempo real desde Firebase Firestore.
class ListaActividadesScreen extends StatefulWidget {
  final String materiaId; // ID único de la materia en Firestore
  final String nombreMateria; // Nombre de la materia para mostrarlo en el AppBar

  const ListaActividadesScreen({
    super.key,
    required this.materiaId,
    required this.nombreMateria,
  });

  @override
  State<ListaActividadesScreen> createState() => _ListaActividadesScreenState();
}

class _ListaActividadesScreenState extends State<ListaActividadesScreen> {
  // Variable de estado para controlar qué grupo está seleccionado actualmente ('A' o 'B')
  String _grupoSeleccionado = 'A';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior con el nombre de la materia seleccionada
      appBar: AppBar(
        title: Text('Actividades de ${widget.nombreMateria}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 1. Selector de Grupo (A / B) en la parte superior
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Grupo: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  isSelected: [
                    _grupoSeleccionado == 'A',
                    _grupoSeleccionado == 'B',
                  ],
                  onPressed: (int index) {
                    setState(() {
                      _grupoSeleccionado = index == 0 ? 'A' : 'B';
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Colors.blueAccent,
                  color: Colors.black,
                  constraints: const BoxConstraints(
                    minHeight: 38,
                    minWidth: 90,
                  ),
                  children: const [
                    Text(
                      'Grupo A',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Grupo B',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenedor principal de la lista
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de Prácticas y Tareas - Grupo $_grupoSeleccionado',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // StreamBuilder para escuchar las actividades de esta materia y grupo en tiempo real
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('actividades')
                          .where('idMateria', isEqualTo: widget.materiaId)
                          // Filtro opcional por grupo si tus documentos de actividades guardan el campo 'grupo'. 
                          // Si tus actividades aplican para ambos grupos de la materia, puedes omitir este .where()
                          // .where('grupo', isEqualTo: _grupoSeleccionado)
                          .snapshots(),
                      builder: (context, snapshot) {
                        // 1. Manejo de errores en la conexión
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error al cargar las actividades.'),
                          );
                        }

                        // 2. Indicador de carga mientras responde Firebase
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        // 3. Mensaje si todavía no hay actividades registradas
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay actividades registradas para el Grupo $_grupoSeleccionado.',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        // 4. Construcción de la lista visual de actividades
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final actividadId = doc.id;

                            // Extracción de datos del documento
                            final titulo = data['titulo'] ?? 'Sin título';
                            final descripcion =
                                data['descripcion'] ?? 'Sin descripción';

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent.shade100,
                                  child: const Icon(
                                    Icons.assignment,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                title: Text(
                                  titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    descripcion,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                // 5. Al hacer clic, navega al detalle de entregas pasándole los datos
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleActividadScreen(
                                        actividadId: actividadId,
                                        tituloActividad: titulo,
                                        descripcionActividad: descripcion,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}