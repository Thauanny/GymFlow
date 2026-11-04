<div align="center">

# GymFlow

### Seu treino da semana, montado com o que a sua academia tem.

Marque os equipamentos, escolha os dias e pronto: o GymFlow monta treinos e
alongamentos sob medida, com GIFs que mostram como fazer cada exercício.
Grátis, sem cadastro e sem anúncios.

**[Abrir o GymFlow](https://thauanny.github.io/GymFlow/)**

</div>

---

## Para quem é

- Quem treina em academia e **não sabe o que fazer em cada dia**.
- Quem tem **uma academia pequena** ou com poucos aparelhos e quer um treino que
  caiba nela.
- Quem já monta o próprio treino e quer **tudo organizado num lugar só**, com
  carga, descanso e histórico.
- Quem quer **ficar longe de apps que pedem cadastro** e assinatura.

---

## Como funciona

**1. Marque o que existe na sua academia.**
Máquinas, polias, barras, halteres, elásticos, bolas... Você escolhe, e o app só
sugere exercícios que dá para fazer.

**2. Diga quando e como quer treinar.**
Objetivo (ganhar massa, força, emagrecer ou resistência), nível, tempo por
treino e os dias da semana. O GymFlow sugere a divisão: peito e tríceps, costas
e bíceps, pernas e glúteos, e assim por diante.

**3. Receba a semana pronta.**
Cada dia traz os exercícios, as séries, as repetições e o descanso. Não gostou
de algum? Troque por outro do mesmo músculo com um toque.

---

## O que você ganha

### Treino sob medida
- Plano gerado automaticamente a partir do seu objetivo, nível e tempo.
- Você pode **descrever o objetivo com as suas palavras** (por exemplo, "quero
  fortalecer as costas e os ombros") e o plano dá mais atenção a isso.
- Cada exercício explica **por que foi escolhido**.
- Prefere montar o seu? O **modo manual** usa a mesma tela, com os dias vazios
  para você preencher. Cada dia da semana é um treino separado.
- **Academia pequena?** Dá para tirar do plano a polia dupla ou qualquer
  aparelho que você não quer usar.

### Alongamentos de cada dia
- Uma ficha de alongamentos **só com os músculos que você treina naquele dia**.
- Aparece antes do treino, no mesmo formato dos exercícios, com cronômetro para
  cada posição.
- Dá para ligar e desligar, trocar, adicionar e remover.

### Veja como fazer
- **GIFs animados** mostrando o movimento e os músculos trabalhados.
- Fotos de uma pessoa nas duas posições, quando não há GIF.
- Sugestões de **variações** do mesmo exercício em outros equipamentos.

### Acompanhe a evolução
- Ficha com marcação de séries, **carga de cada exercício** e **cronômetro de
  descanso**.
- Botão **Evoluir**: o plano sobe carga, repetições ou séries no ritmo certo.
- **Calendário de constância**, histórico de treinos e gráfico do peso corporal.
- Os planos antigos ficam guardados e podem ser restaurados.

### Feito para o celular
- **Instale na tela de início** e abra como um app, em tela cheia.
- Tema claro e escuro.
- Tudo em português, inclusive os nomes dos exercícios.

---

## Seus dados são seus

- **Sem conta, sem login, sem servidor.** Tudo fica no seu aparelho.
- **Exportar backup** salva seus treinos e seu progresso num arquivo. Você
  guarda onde quiser (Arquivos, Drive, e-mail) e **restaura** quando precisar.
- O app lembra você de fazer backup quando há novidades.

> Navegadores podem apagar dados de sites que ficam muitos dias sem uso (o
> Safari do iPhone faz isso após 7 dias). Adicione o GymFlow à tela de início e
> faça o backup de vez em quando para não perder nada.

---

## Instalar no celular

| Aparelho | Como |
|---|---|
| **Android** (Chrome) | Toque em **Adicionar atalho** dentro do app, ou no menu ⋮ → *Instalar app*. |
| **iPhone / iPad** | Toque em **Compartilhar** → *Adicionar à Tela de Início*. |

No iPhone, o próprio sistema só permite criar o atalho por esse caminho, em
qualquer navegador. O app mostra o passo a passo do seu aparelho.

---

## Perguntas frequentes

**É grátis?**
Sim. Não há assinatura, anúncios nem versão paga.

**Preciso criar conta?**
Não. Abra e use.

**Funciona sem internet?**
Os treinos e seus dados ficam no aparelho. Os GIFs dos exercícios precisam de
internet para carregar; sem ela, o app mostra fotos e desenhos.

**Posso usar no computador?**
Sim, em qualquer navegador moderno.

**Troquei de celular. E agora?**
Exporte o backup no aparelho antigo e importe no novo.

**O treino substitui um profissional?**
Não. O GymFlow é uma ajuda para organizar o treino. Em caso de lesão, dor ou
condição de saúde, converse com um profissional de educação física ou médico.

---

## Projeto aberto

O GymFlow é um projeto open source feito com Flutter. Sugestões, ideias e
correções são bem-vindas.

- **Sugestões por e-mail:** gymflow.free@gmail.com (ou pelo menu do app, em *Contato e sugestões*).
- **Encontrou um problema ou tem uma ideia?** Abra uma
  [issue](https://github.com/Thauanny/GymFlow/issues).
- **Quer ajudar com código?** Veja "Para quem desenvolve" abaixo.

<details>
<summary><b>Para quem desenvolve</b></summary>

<br>

**Rodar localmente** (precisa do [Flutter](https://docs.flutter.dev/get-started/install)):

```bash
git clone https://github.com/Thauanny/GymFlow.git
cd GymFlow
flutter pub get
flutter run -d chrome
```

**Testar no celular, na mesma rede Wi-Fi:**

```bash
flutter build web
cd build/web
python3 -m http.server 8080 --bind 0.0.0.0
```

Abra `http://<IP-do-computador>:8080` no celular. Nesse modo (sem HTTPS), a
instalação nativa do Android e o compartilhamento do backup não funcionam; para
testá-los, use um túnel HTTPS (ngrok, cloudflared) ou o site publicado.

**Antes de enviar uma contribuição:**

```bash
flutter analyze
flutter test
```

**Organização do código** (`lib/`):

| Pasta | O que tem |
|---|---|
| `domain/training/` | Regras de montagem do treino e dos alongamentos (Dart puro, com testes) |
| `data/` | Exercícios, equipamentos, GIFs, traduções, armazenamento e backup |
| `state/` | Estado do app (Cubits) |
| `ui/features/` | Telas por função: início, academia, plano, treinos, explorar, progresso, ajustes |
| `core/theme/` | Cores, fonte e tema |

**Publicação:** o site vai para o GitHub Pages por Actions a cada push na
`main`. Em *Settings → Pages*, a fonte precisa ser **GitHub Actions**.

</details>

---

## Créditos

- Exercícios, instruções e fotos: [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
  (domínio público).
- GIFs animados: [ExerciseDB](https://exercisedb.dev). Confira os termos de uso
  deles antes de qualquer uso comercial.
- Fonte [Barlow](https://github.com/jpt/barlow) (licença OFL).

## Licença

O projeto ainda não tem uma licença definida. Para ser open source de fato, o
repositório precisa de um arquivo `LICENSE` (por exemplo MIT ou Apache-2.0).
Material de terceiros segue as licenças de cada fonte, listadas acima.
