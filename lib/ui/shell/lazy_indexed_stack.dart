import 'package:flutter/widgets.dart';

/// IndexedStack que só monta uma aba na primeira vez que ela é aberta (e a
/// mantém depois). Evita construir as 5 telas já na abertura do app.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> builders;
  const LazyIndexedStack({
    required this.index,
    required this.builders,
    super.key,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final Set<int> _built = {widget.index};

  @override
  void didUpdateWidget(LazyIndexedStack old) {
    super.didUpdateWidget(old);
    _built.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (final (i, b) in widget.builders.indexed)
          _built.contains(i) ? b(context) : const SizedBox.shrink(),
      ],
    );
  }
}
