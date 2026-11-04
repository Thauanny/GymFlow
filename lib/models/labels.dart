const equipmentLabels = <String, String>{
  'body only': 'Peso corporal',
  'machine': 'Máquinas',
  'dumbbell': 'Halteres',
  'barbell': 'Barra',
  'cable': 'Cabos / Polia',
  'kettlebells': 'Kettlebell',
  'bands': 'Elásticos',
  'medicine ball': 'Medicine ball',
  'exercise ball': 'Bola suíça',
  'e-z curl bar': 'Barra W',
  'foam roll': 'Rolo de espuma',
  'other': 'Outros',
};

/// Chaves na ordem de exibição (grupos grandes primeiro).
const muscleNames = <String, String>{
  'chest': 'Peito',
  'lats': 'Dorsal',
  'middle back': 'Costas (meio)',
  'shoulders': 'Ombros',
  'biceps': 'Bíceps',
  'triceps': 'Tríceps',
  'forearms': 'Antebraço',
  'traps': 'Trapézio',
  'abdominals': 'Abdômen',
  'lower back': 'Lombar',
  'quadriceps': 'Quadríceps',
  'hamstrings': 'Posterior de coxa',
  'glutes': 'Glúteos',
  'calves': 'Panturrilha',
  'abductors': 'Abdutores',
  'adductors': 'Adutores',
  'neck': 'Pescoço',
};

const levelNames = <String, String>{
  'beginner': 'Iniciante',
  'intermediate': 'Intermediário',
  'expert': 'Avançado',
};

const weekdayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];
const weekdayFull = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

String equipLabel(String e) => equipmentLabels[e] ?? e;
String muscleLabel(String m) => muscleNames[m] ?? m;
