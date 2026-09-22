import 'package:flutter/material.dart';
import 'package:control_escolar/screens/grupo_screen.dart';

class PrepaSemestresScreen extends StatelessWidget {
  const PrepaSemestresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preparatoria - Semestres'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.extent(
          maxCrossAxisExtent: 300, // Ancho máximo de tarjeta.
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio:
              1.4, // Controla la proporción visual de los semestres.
          children: const [
            SemestreCard(semestre: '1er Semestre'),
            SemestreCard(semestre: '2do Semestre'),
            SemestreCard(semestre: '3er Semestre'),
            SemestreCard(semestre: '4to Semestre'),
            SemestreCard(semestre: '5to Semestre'),
            SemestreCard(semestre: '6to Semestre'),
          ],
        ),
      ),
    );
  }
}

class SemestreCard extends StatelessWidget {
  final String semestre;

  const SemestreCard({super.key, required this.semestre});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GrupoScreen(nombreGrado: 'Prepa - $semestre'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.computer, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              semestre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
