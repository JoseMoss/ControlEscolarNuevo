class ClaseModel {
  final int periodo; // Número del 1 al 9
  final String horaInicio;
  final String horaFin;
  final String materia; // 'TECNOLOGÍA' o 'CULTURA DIGITAL'
  final String grupo;   // Ej. '2o SEC A', '1o SEM B'

  ClaseModel({
    required this.periodo,
    required this.horaInicio,
    required this.horaFin,
    required this.materia,
    required this.grupo,
  });
}