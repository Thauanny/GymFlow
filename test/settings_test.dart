import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/ui/features/settings/contact_sheet.dart';

void main() {
  test('o contato aponta para o LinkedIn correto', () {
    expect(linkedinUrl, 'https://www.linkedin.com/in/thauanny-ramos/');
    expect(Uri.parse(linkedinUrl).host, 'www.linkedin.com');
  });
}
