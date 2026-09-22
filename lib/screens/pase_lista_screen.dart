import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modelo de datos para manejar el estado de asistencia de cada alumno
class AlumnoAsistencia {
  final String idAlumno;
  final String nombreCompleto;
  String estado; // 'Presente', 'Retardo', 'Falta'

  AlumnoAsistencia({
    required this.idAlumno,
    required this.nombreCompleto,
    this.estado = 'Presente', // Por defecto todos inician como presentes
  });

  Map<String, dynamic> toJson() {
    return {
      'idAlumno': idAlumno,
      'nombreCompleto': nombreCompleto,
      'estado': estado,
    };
  }
}

class PaseListaScreen extends StatefulWidget {
  final String grado; // Ej. "1ro Secundaria" o "Prepa"
  final String materia;

  const PaseListaScreen({
    super.key,
    required this.grado,
    required this.materia,
  });

  @override
  State<PaseListaScreen> createState() => _PaseListaScreenState();
}

class _PaseListaScreenState extends State<PaseListaScreen> {
  bool isLoading = true;
  String grupoSeleccionado = 'A'; // Grupo por defecto (A o B)
  List<AlumnoAsistencia> alumnosLista = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  // Método para traer los alumnos de Firestore filtrando por Grado y Grupo (A o B)
  Future<void> _cargarAlumnos() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('alumnos')
          .where('grado', isEqualTo: widget.grado)
          .where('grupo', isEqualTo: grupoSeleccionado)
          .get();

      setState(() {
        alumnosLista = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String nombre = data['nombre'] ?? 'Sin nombre';
          return AlumnoAsistencia(idAlumno: doc.id, nombreCompleto: nombre);
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al cargar alumnos: $e')));
      }
    }
  }

  // Guardar la asistencia del día en Firestore
  Future<void> _guardarAsistencia() async {
    String fechaHoy = DateTime.now().toIso8601String().split('T')[0];
    String documentoId = '${fechaHoy}_${widget.grado}_$grupoSeleccionado';

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> datosAsistencia = {
        'fecha': fechaHoy,
        'grado': widget.grado,
        'grupo': grupoSeleccionado,
        'materia': widget.materia,
        'timestamp': FieldValue.serverTimestamp(),
        'registros': alumnosLista.map((a) => a.toJson()).toList(),
      };

      // Guardar en la colección 'asistencias' usando el ID combinado para evitar duplicados diarios
      await _firestore
          .collection('asistencias')
          .doc(documentoId)
          .set(datosAsistencia);

      if (mounted) Navigator.pop(context); // Cerrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Asistencia guardada correctamente en la nube!'),
          ),
        );
      }
      if (mounted) Navigator.pop(context); // Regresar a la pantalla anterior
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pase de Lista: ${widget.grado}')),
      body: Column(
        children: [
          // Selector de Grupo (A / B) en la parte superior
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Grupo: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 10),
                ToggleButtons(
                  isSelected: [grupoSeleccionado == 'A', grupoSeleccionado == 'B'],
                  onPressed: (int index) {
                    setState(() {
                      grupoSeleccionado = index == 0 ? 'A' : 'B';
                    });
                    _cargarAlumnos(); // Recarga los alumnos al cambiar de grupo
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Colors.blueAccent,
                  color: Colors.black,
                  constraints: const BoxConstraints(minHeight: 38, minWidth: 90),
                  children: const [
                    Text('Grupo A', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Grupo B', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenido principal de la lista
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : alumnosLista.isEmpty
                    ? Center(
                        child: Text('No hay alumnos registrados en el Grupo $grupoSeleccionado de ${widget.grado}.'),
                      )
                    : ListView.builder(
                        itemCount: alumnosLista.length,
                        itemBuilder: (context, index) {
                          final alumno = alumnosLista[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  // Botones de selección rápida (Presente, Retardo, Falta)
                                  ToggleButtons(
                                    isSelected: [
                                      alumno.estado == 'Presente',
                                      alumno.estado == 'Retardo',
                                      alumno.estado == 'Falta',
                                    ],
                                    onPressed: (int indexButton) {
                                      setState(() {
                                        if (indexButton == 0) alumno.estado = 'Presente';
                                        if (indexButton == 1) alumno.estado = 'Retardo';
                                        if (indexButton == 2) alumno.estado = 'Falta';
                                      });
                                    },
                                    color: Colors.grey,
                                    selectedColor: Colors.white,
                                    fillColor: indexButtonColor(alumno.estado),
                                    borderRadius: BorderRadius.circular(8),
                                    constraints: const BoxConstraints(
                                      minHeight: 36,
                                      minWidth: 45,
                                    ),
                                    children: const [
                                      Text(
                                        'P',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'R',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'F',
                                        style: TextStyle(fontWeight: FontWeight.bold),
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
        onPressed: alumnosLista.isEmpty ? null : _guardarAsistencia,
        label: const Text('Guardar Asistencia'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  // Color dinámico para el botón seleccionado
  Color indexButtonColor(String estado) {
    switch (estado) {
      case 'Presente':
        return Colors.green;
      case 'Retardo':
        return Colors.orange;
      case 'Falta':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}