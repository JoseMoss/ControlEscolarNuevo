// Importamos la librería principal de Flutter para componentes visuales
import 'package:flutter/material.dart';

// Importamos las pantallas de navegación del sistema escolar
import 'package:control_escolar/screens/grupo_screen.dart';
import 'package:control_escolar/screens/prepa_semestres_screen.dart';
import 'package:control_escolar/screens/registro_alumno_screen.dart';
import 'package:control_escolar/screens/registroMateriaScreen.dart';
import 'package:control_escolar/screens/registro_actividad_screen.dart';
import 'package:control_escolar/screens/lista_materias_screen.dart';
import 'package:control_escolar/screens/horario_screen.dart';

/// Pantalla principal (Dashboard) de la aplicación Synapse Classroom
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior de la aplicación con el nuevo nombre tecnológico
      appBar: AppBar(
        title: const Text('Synapse Classroom'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Botón para ver el Horario de clases
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Ver Horario',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HorarioScreen(),
                ),
              );
            },
          ),
          // Botón para ver la lista general de materias registradas
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Ver Materias Registradas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaMateriasScreen(),
                ),
              );
            },
          ),
          // Botón para registrar una nueva Materia
          IconButton(
            icon: const Icon(Icons.library_add),
            tooltip: 'Registrar Materia',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistroMateriaScreen(),
                ),
              );
            },
          ),
          // Botón para registrar una nueva Actividad o Práctica
          IconButton(
            icon: const Icon(Icons.assignment_add),
            tooltip: 'Registrar Actividad',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistroActividadScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Cuerpo central de la pantalla principal organizado en una cuadrícula de grados
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el Grado y Nivel',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.extent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: const [
                  GradoCard(
                    titulo: '1° Secundaria',
                    icono: Icons.school,
                    esPrepa: false,
                  ),
                  GradoCard(
                    titulo: '2° Secundaria',
                    icono: Icons.school,
                    esPrepa: false,
                  ),
                  GradoCard(
                    titulo: '3° Secundaria',
                    icono: Icons.school,
                    esPrepa: false,
                  ),
                  GradoCard(
                    titulo: 'Preparatoria',
                    icono: Icons.computer,
                    esPrepa: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Botón flotante inferior para dar de alta un nuevo alumno en el sistema
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistroAlumnoScreen(),
            ),
          );
        },
        label: const Text('Nuevo Alumno'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}

/// Widget personalizado para representar cada tarjeta de Grado / Nivel en la cuadrícula
class GradoCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final bool esPrepa;

  const GradoCard({
    super.key,
    required this.titulo,
    required this.icono,
    required this.esPrepa,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Si es preparatoria, redirige a la selección de semestres; si es secundaria, al grupo correspondiente
          if (esPrepa) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrepaSemestresScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GrupoScreen(nombreGrado: titulo),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 50, color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}