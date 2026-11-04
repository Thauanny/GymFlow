const _stop = {
  'the',
  'with',
  'on',
  'of',
  'a',
  'to',
  'machine',
  'lever',
  'leverage',
  'sled',
  'exercise',
  'and',
  'in',
  'for',
  'full',
  'range',
  'motion',
};

/// Palavras relevantes de um nome de exercício (minúsculas, singular).
Set<String> nameTokens(String s) => s
    .toLowerCase()
    .replaceAll('stability ball', 'exercise ball')
    .replaceAll('one-arm', 'single-arm')
    .replaceAll('one arm', 'single arm')
    .replaceAll('stiff-legged', 'stiff leg')
    .replaceAll('straight-leg', 'stiff leg')
    .replaceAll('straight leg', 'stiff leg')
    .replaceAll('pull-up', 'pullup')
    .replaceAll('chin-up', 'chinup')
    .replaceAll('push-up', 'pushup')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .split(' ')
    .where((w) => w.length > 1 && !_stop.contains(w))
    .map(
      (w) => w.length > 3 && w.endsWith('s') && !w.endsWith('ss')
          ? w.substring(0, w.length - 1)
          : w,
    )
    .toSet();
