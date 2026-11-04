import 'equip_item.dart';

const cardioItems = <EquipItem>[
  EquipItem(
    'm_cardio',
    'Esteira',
    'machine',
    'cardio',
    'Caminhada e corrida',
    'Jogging_Treadmill',
    'cardio',
    pattern: r'treadmill|jogging|running|walking',
  ),
  EquipItem(
    'm_stairs',
    'Escada (stairmaster)',
    'machine',
    'cardio',
    'Escada rolante e step mill',
    'Stairmaster',
    'cardio',
    pattern: r'stairmaster|step mill',
  ),
  EquipItem(
    'm_bike',
    'Bicicleta ergométrica',
    'machine',
    'cardio',
    'Bike e spinning',
    'Bicycling_Stationary',
    'cardio',
    pattern: r'bicycl|bike',
  ),
  EquipItem(
    'm_ellip',
    'Elíptico e remo',
    'machine',
    'cardio',
    'Elíptico e remo ergômetro',
    'Elliptical_Trainer',
    'cardio',
    pattern: r'elliptical|rowing',
  ),
];
