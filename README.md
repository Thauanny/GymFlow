# GymFlow

App (Flutter Web) para academia: você marca os equipamentos que existem, o app sugere
alternativas e monta treinos conforme os **dias da semana** e a **função** de cada dia.

## Funcionalidades
- **Academia**: seleção de aparelhos (presets, busca, filtro por músculo, pesos de halteres) e alternativas com GIF.
- **Plano semanal**: objetivo (hipertrofia, força, emagrecimento, resistência), nível, tempo por treino,
  divisão automática (full body, upper/lower, push/pull/legs), foco e músculos em destaque por dia,
  motivo de cada exercício, troca por substitutos, volume semanal por músculo e aviso de recuperação.
- **Treinos**: ficha com checklist, carga por exercício (com progressão sugerida), cronômetro de descanso, editor manual.
- **Explorar** (grade de exercícios) e **Progresso** (constância, peso corporal, histórico).
- **Visual**: tema claro por padrão (escuro opcional), fonte Barlow embutida, lima de marca, blocos pastel,
  barra superior em telas largas e navegação inferior no celular.

## Arquitetura (`lib/`)
| Pasta | Responsabilidade |
|---|---|
| `models/` | Entidades simples (Exercise, Workout, PlanItem...) |
| `data/` | Base de exercícios (asset offline), catálogo de equipamentos, GIFs, alternativas, armazenamento |
| `domain/training/` | **Motor de treino** puro (sem Flutter): modelos de dia, vagas, pontuação, prescrição, divisão, volume |
| `ai/` | Interpretação do objetivo em texto; ranking por palavras-chave ou IA semântica opcional |
| `state/` | Estado com **BLoC** (Cubits): catálogo, equipamentos, treinos, progresso, planejador, tema, navegação |
| `core/theme/` | Tokens de cor (`AppPalette`), tipografia (`AppText`) e tema Material |
| `ui/` | Widgets compartilhados e telas por funcionalidade (`ui/features/*`) |

Princípios: um arquivo, uma responsabilidade (nenhum passa de ~250 linhas); UI só lê estado e dispara ações;
regras de treino ficam no domínio e são testadas (`test/`).

## Como o treino é montado
1. A divisão da semana vem do nº de dias e do nível (`split_planner.dart`).
2. Cada dia tem um modelo de vagas (músculo + composto/isolado) (`day_template.dart`); músculos em destaque ganham vagas.
3. Cada vaga escolhe o melhor exercício disponível com o equipamento do usuário, por pontuação
   (tipo, nível, equipamento, variedade entre dias/aparelhos, objetivo em texto) (`exercise_scorer.dart`).
4. Compostos vêm primeiro; séries/reps/descanso seguem o objetivo (`prescription.dart`).

## Rodar
```
flutter pub get
flutter run -d chrome
flutter test
```
