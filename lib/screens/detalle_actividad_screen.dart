import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetalleActividadScreen extends StatefulWidget {
  final String actividadId;
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

class _DetalleActividadScreenState extends State<DetalleActividadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _grupos = ['A', 'B'];

  final TextEditingController _searchControllerA = TextEditingController();
  final TextEditingController _searchControllerB = TextEditingController();
  String _filtroA = '';
  String _filtroB = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _grupos.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchControllerA.dispose();
    _searchControllerB.dispose();
    super.dispose();
  }

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
      appBar: AppBar(
        title: Text(widget.tituloActividad),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: '📂 Grupo A'),
            Tab(text: '📂 Grupo B'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción de la Actividad:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.descripcionActividad.isEmpty
                          ? 'Sin descripción adicional.'
                          : widget.descripcionActividad,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVistaGrupo('A', _searchControllerA, _filtroA, (val) {
                  setState(() => _filtroA = val);
                }),
                _buildVistaGrupo('B', _searchControllerB, _filtroB, (val) {
                  setState(() => _filtroB = val);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaGrupo(
    String grupoFiltro,
    TextEditingController controller,
    String filtro,
    Function(String) onFiltroChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onFiltroChanged,
            decoration: InputDecoration(
              hintText: 'Buscar alumno en Grupo $grupoFiltro...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filtro.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onFiltroChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('alumnos').snapshots(),
              builder: (context, snapshotAlumnos) {
                if (snapshotAlumnos.hasError) {
                  return const Center(child: Text('Error al cargar alumnos'));
                }
                if (snapshotAlumnos.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshotAlumnos.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay alumnos registrados en el sistema.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                final grupoTarget = grupoFiltro.toLowerCase();
                final filtroLower = filtro.toLowerCase().trim();

                final listaFiltrada = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Validación flexible para detectar "Grupo A", "Grupo B" o "A"/"B"
                  final grupoDoc = (data['grupo'] ?? data['Group'] ?? '')
                      .toString()
                      .toLowerCase();

                  bool esDelGrupo = grupoDoc.contains(grupoTarget) ||
                      grupoDoc.endsWith(grupoTarget);
                  if (!esDelGrupo) return false;

                  // Filtrar por nombre si hay texto en la barra de búsqueda
                  final nombre =
                      (data['nombre'] ?? '').toString().toLowerCase();
                  final apellidoPaterno =
                      (data['apellidoPaterno'] ?? '').toString().toLowerCase();
                  final apellidoMaterno =
                      (data['apellidoMaterno'] ?? '').toString().toLowerCase();
                  final completo = '$nombre $apellidoPaterno $apellidoMaterno';

                  return completo.contains(filtroLower);
                }).toList();

                // Ordenar alfabéticamente
                listaFiltrada.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final nombreA =
                      (dataA['nombre'] ?? '').toString().toLowerCase();
                  final nombreB =
                      (dataB['nombre'] ?? '').toString().toLowerCase();
                  return nombreA.compareTo(nombreB);
                });

                if (listaFiltrada.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron alumnos en el Grupo $grupoFiltro.',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

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
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        final alumnoDoc = listaFiltrada[index];
                        final alumnoData =
                            alumnoDoc.data() as Map<String, dynamic>;
                        final alumnoId = alumnoDoc.id;

                        final nombre = alumnoData['nombre'] ?? '';
                        final apellidoPaterno =
                            alumnoData['apellidoPaterno'] ?? '';
                        final apellidoMaterno =
                            alumnoData['apellidoMaterno'] ?? '';
                        final nombreCompleto =
                            '$nombre $apellidoPaterno $apellidoMaterno'.trim();

                        final bool yaEntrega = mapEntregas[alumnoId] ?? false;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: CheckboxListTile(
                            title: Text(
                              '${index + 1}. ${nombreCompleto.isEmpty ? 'Sin Nombre' : nombreCompleto}',
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
                                color: yaEntrega ? Colors.green : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: yaEntrega
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              child: Icon(
                                yaEntrega ? Icons.check : Icons.access_time,
                                color: yaEntrega ? Colors.green : Colors.orange,
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
    );
  }
}
