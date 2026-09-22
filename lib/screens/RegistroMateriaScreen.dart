import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Importamos la pantalla que creamos anteriormente para listar las materias
import 'package:control_escolar/screens/lista_materias_screen.dart';

class RegistroMateriaScreen extends StatefulWidget {
  const RegistroMateriaScreen({super.key});

  @override
  State<RegistroMateriaScreen> createState() => _RegistroMateriaScreenState();
}

class _RegistroMateriaScreenState extends State<RegistroMateriaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descController = TextEditingController();

  // Lista de grados para que la materia sepa a quién pertenece
  final List<String> _grados = [
    '1° Secundaria',
    '2° Secundaria',
    '3° Secundaria',
    'Prepa - 1er Semestre',
    'Prepa - 2do Semestre',
    'Prepa - 3er Semestre',
    'Prepa - 4to Semestre',
    'Prepa - 5to Semestre',
    'Prepa - 6to Semestre',
  ];

  String? _gradoSeleccionado;

  /// Función para guardar la nueva materia directamente en Firestore
  Future<void> _guardarMateria() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('materias').add({
        'nombre': _nombreController.text,
        'descripcion': _descController.text,
        'grado': _gradoSeleccionado,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materia registrada con éxito')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Materia"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo de texto para el nombre de la materia
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Materia',
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Campo de texto para la descripción breve
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción breve',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 20),

              // Selector desplegable del grado escolar
              DropdownButtonFormField<String>(
                initialValue: _gradoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Asignar a Grado',
                  prefixIcon: Icon(Icons.school),
                ),
                items: _grados
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gradoSeleccionado = val),
                validator: (val) => val == null ? 'Selecciona un grado' : null,
              ),
              const SizedBox(height: 30),

              // Botón principal para guardar en Firebase
              ElevatedButton.icon(
                onPressed: _guardarMateria,
                icon: const Icon(Icons.save),
                label: const Text("Guardar Materia"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 15),

              // Botón que ahora sí navega a la pantalla de listado de materias y sus actividades
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListaMateriasScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text("Ver Materias Registradas"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
