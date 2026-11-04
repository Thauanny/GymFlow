/// Variação de exercício com GIF, vinda do índice por equipamento.
class Alt {
  final String name, gif, equip, target;
  final bool have;
  const Alt(this.name, this.gif, this.equip, this.target, [this.have = false]);
  Alt withHave(bool h) => Alt(name, gif, equip, target, h);
}
