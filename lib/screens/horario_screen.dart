import 'package:flutter/material.dart';
import '../data/horario_data.dart';
import '../models/clase_model.dart';

class HorarioScreen extends StatelessWidget {
  const HorarioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie'];

    return DefaultTabController(
      length: dias.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Horario - Prof. José Luis'),
          bottom: TabBar(
            tabs: dias.map((dia) => Tab(text: dia)).toList(),
          ),
        ),
        body: TabBarView(
          children: dias.map((dia) {
            final clases = horarioProfesor[dia] ?? [];
            return _buildListaClases(clases);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListaClases(List<ClaseModel> clases) {
    if (clases.isEmpty) {
      return const Center(child: Text('Sin clases asignadas'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: clases.length,
      itemBuilder: (context, index) {
        final clase = clases[index];
        final esTecnologia = clase.materia == 'TECNOLOGÍA';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: esTecnologia ? Colors.blue.shade100 : Colors.teal.shade100,
              child: Text(
                '${clase.periodo}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: esTecnologia ? Colors.blue.shade900 : Colors.teal.shade900,
                ),
              ),
            ),
            title: Text(
              clase.materia,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Grupo: ${clase.grupo}'),
            trailing: Text(
              '${clase.horaInicio} - ${clase.horaFin}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        );
      },
    );
  }
}