import 'package:flutter/widgets.dart';

/// Larguras abaixo desta contam como celular.
const phoneWidth = 700.0;

bool isPhone(BuildContext context) =>
    MediaQuery.sizeOf(context).width < phoneWidth;
