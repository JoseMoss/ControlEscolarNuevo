// lib/models/alumno.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Alumno {
  final String id;
  // Datos básicos obligatorios
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String fechaNacimiento;
  final String nombreTutor;
  final String numeroTutor;

  // Datos opcionales / institucionales
  final bool esAdventista;
  final String iglesiaDeProcedencia;
  final String alergias;
  final String tipoSangre;
  final String telefonoEmergencia;
  final String observaciones;

  Alumno({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.fechaNacimiento,
    required this.nombreTutor,
    required this.numeroTutor,
    this.esAdventista = false,
    this.iglesiaDeProcedencia = '',
    this.alergias = '',
    this.tipoSangre = '',
    this.telefonoEmergencia = '',
    this.observaciones = '',
  });

  // Convertir de Firestore a Objeto
  factory Alumno.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Alumno(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellidoPaterno: data['apellidoPaterno'] ?? '',
      apellidoMaterno: data['apellidoMaterno'] ?? '',
      fechaNacimiento: data['fechaNacimiento'] ?? '',
      nombreTutor: data['nombreTutor'] ?? '',
      numeroTutor: data['numeroTutor'] ?? '',
      esAdventista: data['esAdventista'] ?? false,
      iglesiaDeProcedencia: data['iglesiaDeProcedencia'] ?? '',
      alergias: data['alergias'] ?? '',
      tipoSangre: data['tipoSangre'] ?? '',
      telefonoEmergencia: data['telefonoEmergencia'] ?? '',
      observaciones: data['observaciones'] ?? '',
    );
  }

  // Convertir de Objeto a Mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
      'fechaNacimiento': fechaNacimiento,
      'nombreTutor': nombreTutor,
      'numeroTutor': numeroTutor,
      'esAdventista': esAdventista,
      'iglesiaDeProcedencia': iglesiaDeProcedencia,
      'alergias': alergias,
      'tipoSangre': tipoSangre,
      'telefonoEmergencia': telefonoEmergencia,
      'observaciones': observaciones,
    };
  }
}
