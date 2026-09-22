// Importamos las librerías necesarias de Flutter y Firebase
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pantalla con estado (StatefulWidget) para manejar controladores, selectores y lógica de guardado
class RegistroAlumnoScreen extends StatefulWidget {
  // Recibimos opcionalmente el grado. Si viene desde un grupo específico, se asigna solo.
  final String? gradoPredefinido;

  const RegistroAlumnoScreen({super.key, this.gradoPredefinido});

  @override
  State<RegistroAlumnoScreen> createState() => _RegistroAlumnoScreenState();
}

class _RegistroAlumnoScreenState extends State<RegistroAlumnoScreen> {
  // Llave global para controlar y validar el estado del formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para capturar los datos del alumno y tutor
  final _nombreController = TextEditingController();
  final _apePaternoController = TextEditingController();
  final _apeMaternoController = TextEditingController();
  final _tutorController = TextEditingController();
  final _telTutorController = TextEditingController();

  // Variable para almacenar el grado seleccionado
  String? _gradoSeleccionado;

  // CORRECCIÓN: Se ajustó el formato de los nombres de los grados para que coincidan
  // exactamente con el formato esperado por GrupoScreen ("Prepa - X Semestre")
  final List<String> _gradosDisponibles = [
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

  // Variable booleana para el interruptor de adventista (por defecto falso)
  bool _esAdventista = false;

  @override
  void initState() {
    super.initState();
    // Si nos pasaron un grado desde la pantalla anterior, lo fijamos automáticamente
    if (widget.gradoPredefinido != null) {
      _gradoSeleccionado = widget.gradoPredefinido;
    }
  }

  // Función asíncrona para enviar los datos a Firestore de manera segura
  Future<void> _guardarAlumno() async {
    // Verificamos que el formulario cumpla con las reglas de validación
    if (_formKey.currentState!.validate()) {
      // Creamos el mapa con los datos recolectados, asegurando que el grado vaya incluido
      final nuevoAlumno = {
        'nombre': _nombreController.text,
        'apellidoPaterno': _apePaternoController.text,
        'apellidoMaterno': _apeMaternoController.text,
        'nombreTutor': _tutorController.text,
        'numeroTutor': _telTutorController.text,
        'grado':
            _gradoSeleccionado ??
            '', // Asocia directamente al alumno con su lista/grupo correcto
        'esAdventista': _esAdventista,
        'fechaNacimiento': '', // Campo preparado para futuras mejoras
      };

      // Nos conectamos a Firestore y agregamos el documento a la colección 'alumnos'
      await FirebaseFirestore.instance.collection('alumnos').add(nuevoAlumno);

      // Verificamos que la pantalla siga activa antes de interactuar con el contexto
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Alumno registrado y asignado a su grupo correctamente!',
            ),
          ),
        );
        Navigator.pop(context); // Regresa a la pantalla anterior
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gradoPredefinido != null
              ? "Registrar en ${widget.gradoPredefinido}"
              : "Registrar Nuevo Alumno",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Vinculamos la llave del formulario
          child: ListView(
            children: [
              // Campo de texto para el nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),

              // Apellido Paterno
              TextFormField(
                controller: _apePaternoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido Paterno',
                ),
              ),

              // Apellido Materno
              TextFormField(
                controller: _apeMaternoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido Materno',
                ),
              ),

              const SizedBox(height: 10),

              // CONDICIONAL INTELIGENTE PARA EL GRADO:
              // Si ya se especificó un grado (ej. 1° Secundaria), mostramos un aviso visual fijo.
              // Si no, mostramos el menú desplegable para que el usuario elija.
              widget.gradoPredefinido != null
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Grado asignado automáticamente: ${widget.gradoPredefinido}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _gradoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Grado o Semestre',
                      ),
                      hint: const Text('Selecciona el nivel correspondiente'),
                      items: _gradosDisponibles.map((String grado) {
                        return DropdownMenuItem<String>(
                          value: grado,
                          child: Text(grado),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          _gradoSeleccionado = nuevoValor;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Por favor selecciona un grado'
                          : null,
                    ),

              const SizedBox(height: 10),

              // Nombre del Tutor
              TextFormField(
                controller: _tutorController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Tutor',
                ),
              ),

              // Teléfono del Tutor
              TextFormField(
                controller: _telTutorController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono del Tutor',
                ),
                keyboardType: TextInputType.phone,
              ),

              // Interruptor (Switch) para definir si es adventista
              SwitchListTile(
                title: const Text("¿Es adventista?"),
                subtitle: const Text(
                  "Indicador para actividades institucionales o de capellanía",
                ),
                value: _esAdventista,
                onChanged: (val) {
                  setState(() {
                    _esAdventista = val;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Botón de guardado
              ElevatedButton.icon(
                onPressed: _guardarAlumno,
                icon: const Icon(Icons.save),
                label: const Text("Guardar en la Base de Datos"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
