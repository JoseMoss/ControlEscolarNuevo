import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modelo interno para manejar el estado del alumno en la lista
class AlumnoAsistencia {
  final String idAlumno;
  final String nombreCompleto;
  final String grupo; // Campo para identificar si pertenece al Grupo A o Grupo B
  String estado; // 'Presente', 'Retardo', 'Falta', 'Falta Justificada'

  AlumnoAsistencia({
    required this.idAlumno,
    required this.nombreCompleto,
    required this.grupo,
    this.estado = 'Presente', // Por defecto todos inician presentes
  });

  Map<String, dynamic> toJson() {
    return {
      'idAlumno': idAlumno,
      'nombreCompleto': nombreCompleto,
      'grupo': grupo,
      'estado': estado,
    };
  }
}

class AsistenciaScreen extends StatefulWidget {
  final String materiaId;
  final String nombreMateria;
  final String gradoMateria; // Recibe el grado para filtrar a los alumnos correctos

  const AsistenciaScreen({
    super.key,
    required this.materiaId,
    required this.nombreMateria,
    required this.gradoMateria,
  });

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  bool isLoading = true;
  int _selectedGroupIndex = 0; // 0 para Grupo A, 1 para Grupo B
  List<AlumnoAsistencia> todosLosAlumnos = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  // Carga todos los alumnos del grado y los clasifica por grupo
  Future<void> _cargarAlumnos() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('alumnos')
          .where('grado', isEqualTo: widget.gradoMateria)
          .get();

      setState(() {
        todosLosAlumnos = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String nombre = data['nombre'] ?? '';
          String apellidoP = data['apellidoPaterno'] ?? '';
          String apellidoM = data['apellidoMaterno'] ?? '';
          String nombreCompleto = '$nombre $apellidoP $apellidoM'.trim();
          String grupo = data['grupo'] ?? 'Grupo A';

          return AlumnoAsistencia(
            idAlumno: doc.id,
            nombreCompleto: nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto,
            grupo: grupo,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cargar alumnos: $e')));
    }
  }

  // Guarda la asistencia general del día en Firestore para ambos grupos
  Future<void> _guardarAsistencia() async {
    String fechaHoy = DateTime.now().toIso8601String().split('T')[0];
    String documentoId = '${fechaHoy}_${widget.materiaId}';

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> datosAsistencia = {
        'fecha': fechaHoy,
        'materiaId': widget.materiaId,
        'materia': widget.nombreMateria,
        'grado': widget.gradoMateria,
        'timestamp': FieldValue.serverTimestamp(),
        'registros': todosLosAlumnos.map((a) => a.toJson()).toList(),
      };

      await _firestore
          .collection('asistencias')
          .doc(documentoId)
          .set(datosAsistencia);

      if (mounted) {
        Navigator.pop(context); // Quitar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Asistencia guardada correctamente en la nube!'),
          ),
        );
        Navigator.pop(context); // Regresar a la lista de materias
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupoActual = _selectedGroupIndex == 0 ? 'Grupo A' : 'Grupo B';
    final alumnosFiltrados = todosLosAlumnos
        .where((a) => a.grupo.toLowerCase() == grupoActual.toLowerCase())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia: ${widget.nombreMateria}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selector de Grupos (Grupo A / Grupo B)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ToggleButtons(
                        isSelected: [
                          _selectedGroupIndex == 0,
                          _selectedGroupIndex == 1,
                        ],
                        onPressed: (index) {
                          setState(() {
                            _selectedGroupIndex = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(10.0),
                        selectedColor: Colors.white,
                        fillColor: Colors.indigo,
                        color: Colors.indigo,
                        constraints: const BoxConstraints(
                          minHeight: 40.0,
                          minWidth: 130.0,
                        ),
                        children: const [
                          Text(
                            'Grupo A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Grupo B',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: alumnosFiltrados.isEmpty
                      ? Center(
                          child: Text(
                            'No hay alumnos registrados en ${widget.gradoMateria} ($grupoActual).',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: alumnosFiltrados.length,
                          itemBuilder: (context, index) {
                            final alumno = alumnosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${index + 1}. ${alumno.nombreCompleto}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Botones rápidos P / R / F / FJ
                                    ToggleButtons(
                                      isSelected: [
                                        alumno.estado == 'Presente',
                                        alumno.estado == 'Retardo',
                                        alumno.estado == 'Falta',
                                        alumno.estado == 'Falta Justificada',
                                      ],
                                      onPressed: (int indexButton) {
                                        setState(() {
                                          if (indexButton == 0) {
                                            alumno.estado = 'Presente';
                                          }
                                          if (indexButton == 1) {
                                            alumno.estado = 'Retardo';
                                          }
                                          if (indexButton == 2) {
                                            alumno.estado = 'Falta';
                                          }
                                          if (indexButton == 3) {
                                            alumno.estado = 'Falta Justificada';
                                          }
                                        });
                                      },
                                      color: Colors.grey,
                                      selectedColor: Colors.white,
                                      fillColor: _obtenerColorBoton(alumno.estado),
                                      borderRadius: BorderRadius.circular(8),
                                      constraints: const BoxConstraints(
                                        minHeight: 36,
                                        minWidth: 40,
                                      ),
                                      children: const [
                                        Text(
                                          'P',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'R',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'F',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'FJ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: todosLosAlumnos.isEmpty ? null : _guardarAsistencia,
        label: const Text('Guardar Asistencia'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Color _obtenerColorBoton(String estado) {
    switch (estado) {
      case 'Presente':
        return Colors.green;
      case 'Retardo':
        return Colors.orange;
      case 'Falta':
        return Colors.red;
      case 'Falta Justificada':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}