import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla que muestra el detalle de la actividad y carga en tiempo real
/// la lista de alumnos desde Firestore para llevar el control de entregas.
class DetalleActividadScreen extends StatefulWidget {
  final String
  actividadId; // ID único del documento de la actividad en Firestore
  final String tituloActividad;
  final String descripcionActividad;

  const DetalleActividadScreen({
    super.key,
    required this.actividadId,
    required this.tituloActividad,
    required this.descripcionActividad,
  });

  @override
  State<DetalleActividadScreen> createState() => _DetalleActividadScreenState();
}

class _DetalleActividadScreenState extends State<DetalleActividadScreen> {
  /// Función para actualizar en Firestore si el alumno entregó o no la actividad.
  Future<void> _toggleEntrega(String alumnoId, bool estadoActual) async {
    try {
      final entregaRef = FirebaseFirestore.instance
          .collection('actividades')
          .doc(widget.actividadId)
          .collection('entregas')
          .doc(alumnoId);

      await entregaRef.set({
        'entregado': !estadoActual,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar entrega: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior con el título de la actividad
      appBar: AppBar(
        title: Text(widget.tituloActividad),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta informativa con la descripción de la tarea
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción de la Actividad:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.descripcionActividad.isEmpty
                          ? 'Sin descripción adicional.'
                          : widget.descripcionActividad,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Control de Entregas de Alumnos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // StreamBuilder principal para escuchar la lista de alumnos desde Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('alumnos')
                    .snapshots(),
                builder: (context, snapshotAlumnos) {
                  if (snapshotAlumnos.hasError) {
                    return const Center(
                      child: Text('Error al cargar los alumnos'),
                    );
                  }
                  if (snapshotAlumnos.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final alumnosDocs = snapshotAlumnos.data!.docs;

                  if (alumnosDocs.isEmpty) {
                    return const Center(
                      child: Text('No hay alumnos registrados en el sistema.'),
                    );
                  }

                  // StreamBuilder secundario para consultar las entregas de esta actividad
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('actividades')
                        .doc(widget.actividadId)
                        .collection('entregas')
                        .snapshots(),
                    builder: (context, snapshotEntregas) {
                      Map<String, bool> mapEntregas = {};
                      if (snapshotEntregas.hasData) {
                        for (var doc in snapshotEntregas.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          mapEntregas[doc.id] = data['entregado'] ?? false;
                        }
                      }

                      return ListView.builder(
                        itemCount: alumnosDocs.length,
                        itemBuilder: (context, index) {
                          final alumnoDoc = alumnosDocs[index];
                          final alumnoData =
                              alumnoDoc.data() as Map<String, dynamic>;
                          final alumnoId = alumnoDoc.id;

                          final nombreAlumno =
                              alumnoData['nombre'] ?? 'Sin Nombre';
                          final bool yaEntrega = mapEntregas[alumnoId] ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: CheckboxListTile(
                              title: Text(
                                nombreAlumno,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: yaEntrega
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: yaEntrega ? Colors.grey : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                yaEntrega ? 'Entregado' : 'Pendiente',
                                style: TextStyle(
                                  color: yaEntrega
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: yaEntrega
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  yaEntrega ? Icons.check : Icons.access_time,
                                  color: yaEntrega
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              value: yaEntrega,
                              onChanged: (bool? valor) {
                                _toggleEntrega(alumnoId, yaEntrega);
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
