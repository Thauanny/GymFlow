/// Fora da web não há seletor/gravador de arquivos nesta versão do app.
Future<void> downloadTextFile(String name, String content) async =>
    throw UnsupportedError('Backup em arquivo só está disponível na web.');

Future<String?> pickTextFile() async =>
    throw UnsupportedError('Backup em arquivo só está disponível na web.');

Future<bool?> storageIsPersistent() async => null;

Future<bool> requestPersistentStorage() async => false;

/// Abre um link em outra aba (só na web nesta versão).
void openUrl(String url) =>
    throw UnsupportedError('Abrir links só está disponível na web.');

bool get isIos => false;

bool get isAndroid => false;

bool get isInstalledApp => false;

bool get canPromptInstall => false;

Future<bool> promptInstall() async => false;
