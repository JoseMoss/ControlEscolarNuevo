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

class _ReporteAsistenciaScreenState extends State<ReporteAsistenciaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _grupos = ['A', 'B'];

  DateTime _fechaSeleccionada = DateTime.now();
  bool _cargando = true;

  List<DocumentSnapshot> _alumnosGrupoA = [];
  List<DocumentSnapshot> _alumnosGrupoB = [];
  Map<String, String> _registrosAsistencia = {};
  bool _existeRegistroEnFecha = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _grupos.length, vsync: this);
    _cargarDatosCompletos(_fechaSeleccionada);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatoFecha(DateTime fecha) {
    return fecha.toIso8601String().split('T')[0];
  }

  Future<void> _cargarDatosCompletos(DateTime fecha) async {
    setState(() {
      _cargando = true;
      _fechaSeleccionada = fecha;
    });

    try {
      var snapA = await FirebaseFirestore.instance
          .collection('alumnos')
          .where('grupo', isEqualTo: 'Grupo A')
          .get();
      if (snapA.docs.isEmpty) {
        snapA = await FirebaseFirestore.instance
            .collection('alumnos')
            .where('grupo', isEqualTo: 'A')
            .get();
      }
      _alumnosGrupoA = snapA.docs;

      var snapB = await FirebaseFirestore.instance
          .collection('alumnos')
          .where('grupo', isEqualTo: 'Grupo B')
          .get();
      if (snapB.docs.isEmpty) {
        snapB = await FirebaseFirestore.instance
            .collection('alumnos')
            .where('grupo', isEqualTo: 'B')
            .get();
      }
      _alumnosGrupoB = snapB.docs;

      String fechaStr = _formatoFecha(fecha);
      Map<String, String> tempRegistros = {};
      bool anyExists = false;

      for (String grupo in _grupos) {
        String docId = '$fechaStr-Grupo $grupo';
        var doc = await FirebaseFirestore.instance
            .collection('materias')
            .doc(widget.materiaId)
            .collection('asistencias')
            .doc(docId)
            .get();

        if (!doc.exists) {
          docId = '$fechaStr-$grupo';
          doc = await FirebaseFirestore.instance
              .collection('materias')
              .doc(widget.materiaId)
              .collection('asistencias')
              .doc(docId)
              .get();
        }

        if (doc.exists) {
          anyExists = true;
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('asistencias')) {
            var mapAsistencias = data['asistencias'] as Map<String, dynamic>;
            mapAsistencias.forEach((alumnoId, estado) {
              tempRegistros[alumnoId] = estado.toString();
            });
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _registrosAsistencia = tempRegistros;
        _existeRegistroEnFecha = anyExists;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarFechaCalendario(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      _cargarDatosCompletos(picked);
    }
  }

  // Historial detallado por alumno consultando todas las fechas guardadas
  Future<void> _mostrarHistorialAlumno(String alumnoId, String nombreCompleto) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Historial: $nombreCompleto'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('materias')
                  .doc(widget.materiaId)
                  .collection('asistencias')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay registros históricos de asistencia.'));
                }

                int presentes = 0;
                int retardos = 0;
                int faltas = 0;
                int justificadas = 0;
                List<Map<String, String>> historialFechas = [];

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String fecha = data['fecha'] ?? doc.id.split('-').first;
                  if (data.containsKey('asistencias')) {
                    var map = data['asistencias'] as Map<String, dynamic>;
                    if (map.containsKey(alumnoId)) {
                      String estado = map[alumnoId].toString();
                      if (estado == 'P') presentes++;
                      if (estado == 'R') retardos++;
                      if (estado == 'F') faltas++;
                      if (estado == 'FJ') justificadas++;

                      historialFechas.add({'fecha': fecha, 'estado': estado});
                    }
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatChip('P: $presentes', Colors.green),
                            _buildStatChip('R: $retardos', Colors.amber.shade800),
                            _buildStatChip('F: $faltas', Colors.red),
                            _buildStatChip('FJ: $justificadas', Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    const Text('Registros por fecha:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: historialFechas.isEmpty
                          ? const Center(child: Text('Sin asistencias registradas aún.'))
                          : ListView.builder(
                              itemCount: historialFechas.length,
                              itemBuilder: (context, idx) {
                                var item = historialFechas[idx];
                                return ListTile(
                                  dense: true,
                                  title: Text('Fecha: ${item['fecha']}'),
                                  trailing: Chip(
                                    label: Text(_traducirEstado(item['estado']!)),
                                    backgroundColor: _obtenerColorEstado(item['estado']!).withValues(alpha: 0.2),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fechaTexto = _formatoFecha(_fechaSeleccionada);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte: ${widget.nombreMateria}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: '📂 Grupo A'),
            Tab(text: '📂 Grupo B'),
          ],
        ),
      ),
      body: Column(
        children: [
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
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
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
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListaGrupo(_alumnosGrupoA, 'A'),
                          _buildListaGrupo(_alumnosGrupoB, 'B'),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaGrupo(List<DocumentSnapshot> alumnosGrupo, String grupoNombre) {
    if (alumnosGrupo.isEmpty) {
      return Center(
        child: Text('No hay alumnos registrados en el Grupo $grupoNombre.'),
      );
    }

    final listaOrdenada = List.from(alumnosGrupo);
    listaOrdenada.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final nombreA = (dataA['nombre'] ?? '').toString().toLowerCase();
      final nombreB = (dataB['nombre'] ?? '').toString().toLowerCase();
      return nombreA.compareTo(nombreB);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: listaOrdenada.length,
      itemBuilder: (context, index) {
        var alumnoDoc = listaOrdenada[index];
        var alumnoData = alumnoDoc.data() as Map<String, dynamic>;
        String alumnoId = alumnoDoc.id;

        String nombreCompleto =
            '${alumnoData['nombre'] ?? ''} ${alumnoData['apellidoPaterno'] ?? ''} ${alumnoData['apellidoMaterno'] ?? ''}'
                .trim();

        String codigoEstado = _registrosAsistencia[alumnoId] ?? 'Sin registro';
        String estadoTexto = _traducirEstado(codigoEstado);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: () => _mostrarHistorialAlumno(alumnoId, nombreCompleto),
            leading: CircleAvatar(
              backgroundColor: _obtenerColorEstado(codigoEstado)
                  .withValues(alpha: 0.2),
              child: Text(
                codigoEstado == 'Sin registro' ? '?' : codigoEstado,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: codigoEstado == 'FJ' ? 10 : 14,
                  color: _obtenerColorEstado(codigoEstado),
                ),
              ),
            ),
            title: Text(
              '${index + 1}. ${nombreCompleto.isEmpty ? 'Sin Nombre' : nombreCompleto}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Grupo: $grupoNombre (Toca para ver historial)'),
            trailing: Chip(
              label: Text(
                estadoTexto,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _obtenerColorEstado(codigoEstado),
            ),
          ),
        );
      },
    );
  }

  String _traducirEstado(String codigo) {
    switch (codigo) {
      case 'P':
        return 'Presente';
      case 'R':
        return 'Retardo';
      case 'F':
        return 'Falta';
      case 'FJ':
        return 'Falta Justificada';
      default:
        return 'Sin registro';
    }
  }

  Color _obtenerColorEstado(String codigo) {
    switch (codigo) {
      case 'P':
        return Colors.green;
      case 'R':
        return Colors.amber.shade700;
      case 'F':
        return Colors.red;
      case 'FJ':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }
}