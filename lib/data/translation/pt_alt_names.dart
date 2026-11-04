import 'pt_alt_names_1.dart';
import 'pt_alt_names_2.dart';
import 'pt_alt_names_3.dart';
import 'pt_alt_names_4.dart';

/// Nomes em PT-BR das alternativas (base ExerciseDB), chave em minúsculas. As que
/// casam com um exercício da outra base usam a tradução curada dele
/// (ver `AlternativesService.altNamePt`).
const ptAltNames = <String, String>{
  ...ptAltNames1,
  ...ptAltNames2,
  ...ptAltNames3,
  ...ptAltNames4,
};
