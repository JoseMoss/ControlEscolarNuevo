import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReporteAsistenciaScreen extends StatefulWidget {
  final String materiaId;
  final String nombreMateria;
  final String gradoMateria;

  const ReporteAsistenciaScreen({
    super.key,
    required this.materiaId,
    required this.nombreMateria,
    required this.gradoMateria,
  });

  @override
  State<ReporteAsistenciaScreen> createState() =>
      _ReporteAsistenciaScreenState();
}

class _ReporteAsistenciaScreenState extends State<ReporteAsistenciaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  bool _cargando = true;

  List<DocumentSnapshot> _alumnos = [];
  Map<String, String> _registrosDiaSeleccionado = {}; // { alumnoId: estado }
  bool _existeRegistroEnFecha = false;

  @override
  void initState() {
    super.initState();
    _cargarAlumnosYAsistencia(_fechaSeleccionada);
  }

  // Formatear fecha a YYYY-MM-DD para buscar el documento en Firestore
  String _formatoFecha(DateTime fecha) {
    return fecha.toIso8601String().split('T')[0];
  }

  Future<void> _cargarAlumnosYAsistencia(DateTime fecha) async {
    setState(() {
      _cargando = true;
      _fechaSeleccionada = fecha;
    });

    try {
      // 1. Cargar alumnos del grado correspondiente si aún no se han cargado
      if (_alumnos.isEmpty) {
        var alumnosSnapshot = await FirebaseFirestore.instance
            .collection('alumnos')
            .where('grado', isEqualTo: widget.gradoMateria)
            .get();
        _alumnos = alumnosSnapshot.docs;
      }

      // 2. Buscar el documento de asistencia de la fecha seleccionada
      String fechaStr = _formatoFecha(fecha);
      String documentoId = '${fechaStr}_${widget.materiaId}';

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('asistencias')
          .doc(documentoId)
          .get();

      Map<String, String> tempRegistros = {};
      bool existe = doc.exists;

      if (existe) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('registros')) {
          var registrosList = data['registros'] as List<dynamic>;
          for (var reg in registrosList) {
            String idAlumno = reg['idAlumno'] ?? '';
            String estado = reg['estado'] ?? 'Presente';
            tempRegistros[idAlumno] = estado;
          }
        }
      }

      setState(() {
        _registrosDiaSeleccionado = tempRegistros;
        _existeRegistroEnFecha = existe;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Abrir el selector de fecha (Calendario) sin forzar locale para evitar errores
  Future<void> _seleccionarFechaCalendario(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      _cargarAlumnosYAsistencia(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    String fechaTexto = _formatoFecha(_fechaSeleccionada);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte: ${widget.nombreMateria}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Barra superior con la fecha actual y botón para abrir el calendario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Fecha: $fechaTexto',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _seleccionarFechaCalendario(context),
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('Cambiar Fecha'),
                ),
              ],
            ),
          ),

          // Contenido Principal
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _alumnos.isEmpty
                ? const Center(
                    child: Text('No hay alumnos registrados en este grado.'),
                  )
                : !_existeRegistroEnFecha
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No hay pase de lista registrado para el día:\n$fechaTexto',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _alumnos.length,
                    itemBuilder: (context, index) {
                      var alumnoDoc = _alumnos[index];
                      var alumnoData = alumnoDoc.data() as Map<String, dynamic>;
                      String alumnoId = alumnoDoc.id;

                      String nombreCompleto =
                          '${alumnoData['nombre'] ?? ''} ${alumnoData['apellidoPaterno'] ?? ''} ${alumnoData['apellidoMaterno'] ?? ''}'
                              .trim();

                      String estado =
                          _registrosDiaSeleccionado[alumnoId] ?? 'Sin registro';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _obtenerColorEstado(estado)
                                .withValues(alpha: 0.2),
                            child: Text(
                              estado == 'Sin registro' ? '?' : estado[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _obtenerColorEstado(estado),
                              ),
                            ),
                          ),
                          title: Text(
                            nombreCompleto,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Grado: ${widget.gradoMateria}'),
                          trailing: Chip(
                            label: Text(
                              estado,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _obtenerColorEstado(estado),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'Presente':
        return Colors.green;
      case 'Retardo':
        return Colors.orange;
      case 'Falta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
