/// Aparelho do catálogo da academia.
class EquipItem {
  final String id, label, dbEquip, section, desc, imageId, kind;
  final String? pattern;
  final bool rest;
  const EquipItem(
    this.id,
    this.label,
    this.dbEquip,
    this.section,
    this.desc,
    this.imageId,
    this.kind, {
    this.pattern,
    this.rest = false,
  });
}

const sections = {
  'cardio': 'Cardio',
  'machine': 'Máquinas',
  'cable': 'Cabos e polias',
  'barbell': 'Barras, bancos e racks',
  'dumbbell': 'Halteres',
  'other': 'Acessórios e peso corporal',
};

const sectionKinds = {
  'cardio': 'cardio',
  'machine': 'stack',
  'cable': 'cable',
  'barbell': 'barbell',
  'dumbbell': 'dumbbell',
  'other': 'body',
};

/// A ordem importa: dentro de cada grupo, o primeiro padrão que combina com o
