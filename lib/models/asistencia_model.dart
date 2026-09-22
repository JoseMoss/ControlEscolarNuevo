class AlumnoAsistencia {
  final String idAlumno;
  final String nombreCompleto;
  String estado; // 'Presente', 'Retardo', 'Falta'

  AlumnoAsistencia({
    required this.idAlumno,
    required this.nombreCompleto,
    this.estado = 'Presente', // Por defecto todos inician presentes
  });

  Map<String, dynamic> toJson() {
    return {
      'idAlumno': idAlumno,
      'nombreCompleto': nombreCompleto,
      'estado': estado,
    };
  }
}
