// Importamos las librerías necesarias de Flutter y Firebase Firestore
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importamos la pantalla de registro para poder usar el botón de agregar alumno filtrado
import 'registro_alumno_screen.dart';

// Pantalla para gestionar y ver los alumnos de un grado específico
class GrupoScreen extends StatefulWidget {
  final String nombreGrado;

  const GrupoScreen({super.key, required this.nombreGrado});

  @override
  State<GrupoScreen> createState() => _GrupoScreenState();
}

class _GrupoScreenState extends State<GrupoScreen> {
  // Variable de estado para controlar el grupo seleccionado: 0 para 'A', 1 para 'B'
  int _selectedGroupIndex = 0;

  // 1. Diálogo de confirmación para eliminar alumno
  void _confirmarEliminarAlumno(
    BuildContext context,
    String alumnoId,
    String nombreAlumno,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Alumno'),
          content: Text(
            '¿Estás seguro de eliminar a $nombreAlumno? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await FirebaseFirestore.instance
                      .collection('alumnos')
                      .doc(alumnoId)
                      .delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Alumno eliminado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 2. Formulario modal para Editar Alumno
  void _mostrarModalEditarAlumno(
    BuildContext context,
    String alumnoId,
    Map<String, dynamic> datosActuales,
  ) {
    final nombreController = TextEditingController(
      text: datosActuales['nombre'] ?? '',
    );
    final apPaternoController = TextEditingController(
      text: datosActuales['apellidoPaterno'] ?? '',
    );
    final apMaternoController = TextEditingController(
      text: datosActuales['apellidoMaterno'] ?? '',
    );
    final tutorController = TextEditingController(
      text: datosActuales['nombreTutor'] ?? '',
    );
    final telefonoController = TextEditingController(
      text: datosActuales['numeroTutor'] ?? '',
    );
    bool esAdventista = datosActuales['esAdventista'] ?? false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Editar Alumno'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre(s)'),
                    ),
                    TextField(
                      controller: apPaternoController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido Paterno',
                      ),
                    ),
                    TextField(
                      controller: apMaternoController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido Materno',
                      ),
                    ),
                    TextField(
                      controller: tutorController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Tutor',
                      ),
                    ),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono del Tutor',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('¿Es Adventista?'),
                      value: esAdventista,
                      activeThumbColor: Colors.amber,
                      onChanged: (val) {
                        setStateModal(() {
                          esAdventista = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('alumnos')
                          .doc(alumnoId)
                          .update({
                        'nombre': nombreController.text.trim(),
                        'apellidoPaterno': apPaternoController.text.trim(),
                        'apellidoMaterno': apMaternoController.text.trim(),
                        'nombreTutor': tutorController.text.trim(),
                        'numeroTutor': telefonoController.text.trim(),
                        'esAdventista': esAdventista,
                      });
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Datos actualizados con éxito'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupoActual = _selectedGroupIndex == 0 ? 'Grupo A' : 'Grupo B';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreGrado),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Selector de Grupos (Grupo A / Grupo B)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: [_selectedGroupIndex == 0, _selectedGroupIndex == 1],
                  onPressed: (index) {
                    setState(() {
                      _selectedGroupIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(10.0),
                  selectedColor: Colors.white,
                  fillColor: Colors.indigo,
                  color: Colors.indigo,
                  constraints: const BoxConstraints(minHeight: 40.0, minWidth: 130.0),
                  children: const [
                    Text('Grupo A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Grupo B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),

          // Lista de alumnos obtenida desde Firebase con filtrado flexible por grupo
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alumnos')
                  .where('grupo', isEqualTo: grupoActual)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar los datos: ${snapshot.error}'),
                  );
                }

                final todosLosDocumentos = snapshot.data?.docs ?? [];

                // Filtro flexible para que coincida con el grado seleccionado sin importar variaciones de texto
                final documentos = todosLosDocumentos.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final gradoAlumno = data['grado']?.toString().toLowerCase() ?? '';
                  final gradoWidget = widget.nombreGrado.toLowerCase();
                  return gradoAlumno.contains(gradoWidget) ||
                         gradoWidget.contains(gradoAlumno) ||
                         gradoAlumno.isEmpty;
                }).toList();

                if (documentos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No hay alumnos registrados en ${widget.nombreGrado} ($grupoActual).\nPresiona el botón "+" para agregar el primero.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    final alumnoDoc = documentos[index];
                    final alumnoData = alumnoDoc.data() as Map<String, dynamic>;
                    final alumnoId = alumnoDoc.id;

                    final nombre = alumnoData['nombre'] ?? '';
                    final apellidoPaterno = alumnoData['apellidoPaterno'] ?? '';
                    final apellidoMaterno = alumnoData['apellidoMaterno'] ?? '';
                    final tutor = alumnoData['nombreTutor'] ?? 'Sin tutor';
                    final telefono = alumnoData['numeroTutor'] ?? 'Sin teléfono';
                    final esAdventista = alumnoData['esAdventista'] ?? false;

                    final nombreCompleto = '$nombre $apellidoPaterno $apellidoMaterno'
                        .trim();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          nombreCompleto.isNotEmpty ? nombreCompleto : 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Tutor: $tutor\nTel: $telefono'),
                        isThreeLine: true,

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (esAdventista)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Tooltip(
                                  message: 'Alumno Adventista',
                                  child: Icon(Icons.star, color: Colors.amber),
                                ),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  _mostrarModalEditarAlumno(
                                    context,
                                    alumnoId,
                                    alumnoData,
                                  );
                                } else if (value == 'eliminar') {
                                  _confirmarEliminarAlumno(
                                    context,
                                    alumnoId,
                                    nombreCompleto,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'editar',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'eliminar',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Eliminar'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RegistroAlumnoScreen(gradoPredefinido: widget.nombreGrado),
            ),
          );
        },
        label: const Text('Registrar Alumno'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}