/// Próxima carga sugerida (kg) depois de completar o treino com [last].
double nextLoad(double last) {
  final step = last < 10 ? 1.0 : (last < 40 ? 2.0 : 2.5);
  return ((last + step) * 2).round() / 2;
}
