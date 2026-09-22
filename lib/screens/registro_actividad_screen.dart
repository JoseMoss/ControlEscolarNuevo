import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroActividadScreen extends StatefulWidget {
  const RegistroActividadScreen({super.key});

  @override
  State<RegistroActividadScreen> createState() =>
      _RegistroActividadScreenState();
}

class _RegistroActividadScreenState extends State<RegistroActividadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();

  // Variable para almacenar el ID de la materia seleccionada
  String? _materiaSeleccionadaId;
  String? _nombreMateriaSeleccionada;

  Future<void> _guardarActividad() async {
    if (_formKey.currentState!.validate()) {
      if (_materiaSeleccionadaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una materia')),
        );
        return;
      }

      // Guardamos la actividad en la colección 'actividades'
      await FirebaseFirestore.instance.collection('actividades').add({
        'titulo': _tituloController.text,
        'descripcion': _descController.text,
        'idMateria': _materiaSeleccionadaId,
        'nombreMateria': _nombreMateriaSeleccionada,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Actividad creada con éxito!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Actividad / Tarea")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. Selector dinámico de Materias desde Firestore
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('materias')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error al cargar materias');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text(
                      'No hay materias registradas. Da de alta una primero.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _materiaSeleccionadaId,
                    decoration: const InputDecoration(
                      labelText: 'Materia Correspondiente',
                    ),
                    hint: const Text('Selecciona una materia'),
                    items: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id, // Guardamos el ID del documento
                        child: Text(
                          "${data['nombre']} (${data['grado'] ?? 'General'})",
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _materiaSeleccionadaId = val;
                        // Buscamos el nombre correspondiente para guardarlo de referencia rápida
                        final selectedDoc = docs.firstWhere(
                          (doc) => doc.id == val,
                        );
                        final data = selectedDoc.data() as Map<String, dynamic>;
                        _nombreMateriaSeleccionada = data['nombre'];
                      });
                    },
                    validator: (val) =>
                        val == null ? 'Selecciona una materia' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Título de la actividad
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Actividad (Ej. Práctica 1)',
                ),
                validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // 3. Descripción detallada
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Instrucciones o Descripción',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 30),

              // Botón para guardar
              ElevatedButton.icon(
                onPressed: _guardarActividad,
                icon: const Icon(Icons.assignment_turned_in),
                label: const Text("Publicar Actividad"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
