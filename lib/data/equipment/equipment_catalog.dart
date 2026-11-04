import 'catalog_barbell.dart';
import 'catalog_cable.dart';
import 'catalog_cardio.dart';
import 'catalog_dumbbell.dart';
import 'catalog_machine.dart';
import 'catalog_other.dart';
import 'equip_item.dart';

export 'equip_item.dart';

/// Todos os aparelhos. A ordem importa: dentro de cada grupo, o primeiro
/// padrão que combina com o nome do exercício vence (itens `rest` pegam o resto).
const equipItems = <EquipItem>[
  ...cardioItems,
  ...machineItems,
  ...cableItems,
  ...barbellItems,
  ...dumbbellItems,
  ...otherItems,
];

const dumbbellWeights = [
  1,
  2,
  3,
  4,
  5,
  6,
  8,
  10,
  12,
  14,
  16,
  18,
  20,
  22,
  24,
  26,
  28,
  30,
  32,
  34,
  36,
  38,
  40,
];
