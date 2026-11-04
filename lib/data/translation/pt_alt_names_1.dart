// Nomes das alternativas em PT-BR (parte 1/4). Chave: nome original em minúsculas.
const ptAltNames1 = <String, String>{
  '45° side bend': 'Flexão lateral 45°',
  'all fours squad stretch': 'Alongamento de quadríceps de quatro apoios',
  'alternate lateral pulldown': 'Puxada lateral alternada',
  'alternating seated dumbbell shoulder press':
      'Desenvolvimento alternado sentado com halteres',
  'archer pull-up': 'Barra fixa arqueiro',
  'archer push up': 'Flexão arqueiro',
  'arm slingers hanging bent knee legs':
      'Elevação de joelhos suspenso com balanço de braços',
  'arm slingers hanging straight-legs':
      'Elevação de pernas retas suspenso com balanço de braços',
  'arms apart circular toe touch': 'Toque nos pés circular com braços abertos',
  'arms overhead full sit-up': 'Abdominal completo com braços acima da cabeça',
  'assisted chest dip (kneeling)':
      'Paralelas para peito assistidas (de joelhos)',
  'assisted hanging knee raise': 'Elevação de joelhos suspenso assistida',
  'assisted hanging knee raise with throw down':
      'Elevação de joelhos suspenso assistida com arremesso',
  'assisted lying calves stretch':
      'Alongamento de panturrilhas deitado assistido',
  'assisted lying glutes stretch': 'Alongamento de glúteos deitado assistido',
  'assisted lying gluteus and piriformis stretch':
      'Alongamento de glúteo e piriforme deitado assistido',
  'assisted lying leg raise with throw down':
      'Elevação de pernas deitado assistida com arremesso',
  'assisted motion russian twist': 'Rotação russa assistida',
  'assisted parallel close-grip pull-up':
      'Barra fixa paralela fechada assistida',
  'assisted prone hamstring': 'Alongamento de posterior de bruços assistido',
  'assisted prone lying quads stretch':
      'Alongamento de quadríceps de bruços assistido',
  'assisted prone rectus femoris stretch':
      'Alongamento de reto femoral de bruços assistido',
  'assisted pull-up': 'Barra fixa assistida',
  'assisted seated pectoralis major stretch with stability ball':
      'Alongamento de peitoral sentado assistido com bola suíça',
  'assisted side-lying adductor stretch':
      'Alongamento de adutores deitado de lado assistido',
  'assisted sit-up': 'Abdominal assistido',
  'assisted standing chin-up': 'Barra fixa supinada assistida em pé',
  'assisted standing pull-up': 'Barra fixa assistida em pé',
  'assisted standing triceps extension (with towel)':
      'Tríceps assistido em pé (com toalha)',
  'assisted triceps dip (kneeling)':
      'Mergulho de tríceps assistido (de joelhos)',
  'assisted wide-grip chest dip (kneeling)':
      'Paralelas abertas para peito assistidas (de joelhos)',
  'back extension on exercise ball': 'Extensão lombar na bola suíça',
  'back lever': 'Back lever (alavanca de costas)',
  'back pec stretch': 'Alongamento de peitoral por trás',
  'backward jump': 'Salto para trás',
  'band alternating biceps curl': 'Rosca alternada com elástico',
  'band alternating v-up': 'Abdominal em V alternado com elástico',
  'band assisted wheel rollout': 'Roda abdominal assistida com elástico',
  'band bent-over hip extension': 'Extensão de quadril curvado com elástico',
  'band bicycle crunch': 'Abdominal bicicleta com elástico',
  'band close-grip pulldown': 'Puxada fechada com elástico',
  'band close-grip push-up': 'Flexão fechada com elástico',
  'band concentration curl': 'Rosca concentrada com elástico',
  'band fixed back close-grip pulldown':
      'Puxada fechada com elástico (costas fixas)',
  'band fixed back underhand pulldown':
      'Puxada supinada com elástico (costas fixas)',
  'band front lateral raise': 'Elevação frontal e lateral com elástico',
  'band front raise': 'Elevação frontal com elástico',
  'band hip thrusts on knees': 'Elevação de quadril de joelhos com elástico',
  'band horizontal pallof press': 'Pallof press horizontal com elástico',
  'band jack knife sit-up': 'Abdominal canivete com elástico',
  'band kneeling single-arm pulldown':
      'Puxada unilateral ajoelhado com elástico',
  'band kneeling twisting crunch':
      'Abdominal com rotação ajoelhado com elástico',
  'band leg extension': 'Extensão de pernas com elástico',
  'band lying hip internal rotation':
      'Rotação interna de quadril deitado com elástico',
  'band lying straight-leg raise':
      'Elevação de perna reta deitado com elástico',
  'band pull through': 'Puxada entre as pernas com elástico',
  'band push sit-up': 'Abdominal com empurrada e elástico',
  'band reverse fly': 'Crucifixo inverso com elástico',
  'band reverse wrist curl': 'Rosca de punho inversa com elástico',
  'band seated biceps curl': 'Rosca sentado com elástico',
  'band seated chest press': 'Supino sentado com elástico',
  'band seated hip abduction': 'Abdução de quadril sentado com elástico',
  'band seated hip internal rotation':
      'Rotação interna de quadril sentado com elástico',
  'band seated shoulder press': 'Desenvolvimento sentado com elástico',
  'band seated straight back row': 'Remada sentada com elástico (costas retas)',
  'band seated twist': 'Rotação sentado com elástico',
  'band shrug': 'Encolhimento com elástico',
  'band side triceps extension': 'Tríceps lateral com elástico',
  'band single leg calf raise': 'Panturrilha unilateral com elástico',
  'band single leg reverse calf raise':
      'Panturrilha invertida unilateral com elástico',
  'band single leg split squat': 'Agachamento búlgaro unilateral com elástico',
  'band single-arm overhead biceps curl':
      'Rosca unilateral acima da cabeça com elástico',
  'band single-arm single leg split squat':
      'Agachamento búlgaro unilateral com elástico e um braço',
  'band single-arm standing low row':
      'Remada baixa unilateral em pé com elástico',
  'band single-arm twisting chest press':
      'Supino unilateral com rotação e elástico',
  'band single-arm twisting seated row':
      'Remada unilateral sentada com rotação e elástico',
  'band squat row': 'Agachamento com remada e elástico',
  'band standing crunch': 'Abdominal em pé com elástico',
  'band standing rear delt row':
      'Remada para deltoide posterior em pé com elástico',
  'band standing twisting crunch': 'Abdominal com rotação em pé com elástico',
  'band step-up': 'Subida no banco com elástico',
  'band stiff leg deadlift': 'Stiff com elástico',
  'band straight back stiff leg deadlift': 'Stiff com elástico (costas retas)',
  'band straight-leg deadlift':
      'Levantamento terra de pernas retas com elástico',
  'band twisting overhead press': 'Desenvolvimento com rotação e elástico',
  'band two-leg calf raise - (band under both legs)':
      'Panturrilha com elástico sob os dois pés',
  'band underhand pulldown': 'Puxada supinada com elástico',
  'band v-up': 'Abdominal em V com elástico',
  'band vertical pallof press': 'Pallof press vertical com elástico',
  'band wrist curl': 'Rosca de punho com elástico',
  'band y-raise': 'Elevação em Y com elástico',
  'barbell alternate biceps curl': 'Rosca alternada com barra',
  'barbell bench press': 'Supino reto com barra',
  'barbell biceps curl (with arm blaster)':
      'Rosca direta com barra (com arm blaster)',
  'barbell clean and press': 'Clean e desenvolvimento com barra',
  'barbell clean-grip front squat':
      'Agachamento frontal com barra (pegada clean)',
  'barbell decline bent arm pullover':
      'Pullover declinado com barra (braços flexionados)',
  'barbell decline close-grip to skull press':
      'Supino declinado fechado até tríceps testa com barra',
  'barbell decline pullover': 'Pullover declinado com barra',
  'barbell decline wide-grip press': 'Supino declinado aberto com barra',
  'barbell drag curl': 'Rosca arrastada com barra',
  'barbell floor calf raise': 'Panturrilha no chão com barra',
  'barbell front chest squat': 'Agachamento frontal com barra',
  'barbell front raise': 'Elevação frontal com barra',
  'barbell front raise and pullover': 'Elevação frontal e pullover com barra',
  'barbell full squat (back pov)':
      'Agachamento completo com barra (visão de costas)',
  'barbell full zercher squat': 'Agachamento Zercher completo com barra',
  'barbell glute bridge two-leg on bench':
      'Ponte de glúteos com barra no banco',
  'barbell good morning': 'Bom dia com barra',
  'barbell high bar squat': 'Agachamento com barra alta',
  'barbell incline bench press': 'Supino inclinado com barra',
  'barbell incline close-grip bench press':
      'Supino inclinado fechado com barra',
  'barbell incline reverse-grip press':
      'Supino inclinado com barra (pegada supinada)',
  'barbell incline row': 'Remada inclinada com barra',
  'barbell jefferson squat': 'Agachamento Jefferson com barra',
  'barbell jm bench press': 'JM press com barra',
  'barbell jump squat': 'Agachamento com salto e barra',
  'barbell lateral lunge': 'Avanço lateral com barra',
  'barbell low bar squat': 'Agachamento com barra baixa',
  'barbell lying back of the head triceps extension':
      'Tríceps testa com barra atrás da cabeça',
  'barbell lying close-grip press': 'Supino fechado deitado com barra',
  'barbell lying close-grip triceps extension':
      'Tríceps testa fechado com barra',
  'barbell lying extension': 'Extensão deitado com barra',
  'barbell lying lifting (on hip)': 'Elevação de quadril deitado com barra',
  'barbell lying preacher curl': 'Rosca Scott deitado com barra',
  'barbell lying triceps extension': 'Tríceps testa com barra',
  'barbell lying triceps extension skull crusher':
      'Tríceps testa (skull crusher) com barra',
  'barbell narrow stance squat': 'Agachamento com pés juntos e barra',
  'barbell overhead squat': 'Agachamento com barra acima da cabeça',
  'barbell palms down wrist curl over a bench':
      'Rosca de punho inversa com barra no banco',
  'barbell pendlay row': 'Remada Pendlay com barra',
  'barbell pin presses': 'Supino com pinos e barra',
  'barbell preacher curl': 'Rosca Scott com barra',
  'barbell press sit-up': 'Abdominal com desenvolvimento e barra',
  'barbell prone incline curl': 'Rosca inclinada de bruços com barra',
  'barbell pullover': 'Pullover com barra',
  'barbell pullover to press': 'Pullover com barra até o supino',
  'barbell rack pull': 'Rack pull com barra',
  'barbell rear delt raise': 'Elevação posterior com barra',
  'barbell rear lunge': 'Avanço reverso com barra',
  'barbell reverse close-grip bench press':
      'Supino fechado com barra (pegada supinada)',
  'barbell reverse wrist curl': 'Rosca de punho inversa com barra',
  'barbell reverse-grip bent over row':
      'Remada curvada com barra (pegada supinada)',
  'barbell reverse-grip decline bench press':
      'Supino declinado com barra (pegada supinada)',
  'barbell reverse-grip incline bench press':
      'Supino inclinado com barra (pegada supinada)',
  'barbell reverse-grip incline bench row':
      'Remada no banco inclinado com barra (pegada supinada)',
  'barbell reverse-grip skullcrusher':
      'Tríceps testa com barra (pegada supinada)',
  'barbell rollout': 'Rolinho abdominal com barra',
  'barbell romanian deadlift': 'Levantamento terra romeno com barra',
  'barbell seated alternate leg raise':
      'Elevação alternada de pernas sentado com barra',
  'barbell seated behind head military press':
      'Desenvolvimento atrás da nuca sentado com barra',
  'barbell seated bradford rocky press':
      'Desenvolvimento Bradford sentado com barra',
  'barbell seated close-grip behind neck triceps extension':
      'Tríceps atrás da nuca sentado com barra (pegada fechada)',
  'barbell seated good morning': 'Bom dia sentado com barra',
  'barbell seated overhead press': 'Desenvolvimento sentado com barra',
  'barbell seated overhead triceps extension':
      'Tríceps francês sentado com barra',
  'barbell side bent': 'Flexão lateral com barra',
  'barbell single leg deadlift': 'Levantamento terra unilateral com barra',
  'barbell single leg split squat': 'Agachamento búlgaro unilateral com barra',
  'barbell single-arm bent over row': 'Remada curvada unilateral com barra',
  'barbell single-arm floor press': 'Supino no chão unilateral com barra',
  'barbell single-arm side deadlift':
      'Levantamento terra lateral unilateral com barra',
  'barbell single-arm snatch': 'Arranco unilateral com barra',
  'barbell single-leg squat': 'Agachamento unilateral com barra',
  'barbell skier': 'Esquiador com barra',
  'barbell speed squat': 'Agachamento de velocidade com barra',
  'barbell split squat': 'Agachamento afundo com barra',
  'barbell squat (on knees)': 'Agachamento de joelhos com barra',
  'barbell squat jump step rear lunge':
      'Agachamento com salto e avanço reverso com barra',
  'barbell standing ab rollout': 'Rolinho abdominal em pé com barra',
  'barbell standing back wrist curl':
      'Rosca de punho atrás das costas em pé com barra',
  'barbell standing bradford press': 'Desenvolvimento Bradford em pé com barra',
  'barbell standing close-grip military press':
      'Desenvolvimento militar fechado em pé com barra',
  'barbell standing concentration curl': 'Rosca concentrada em pé com barra',
  'barbell standing leg calf raise': 'Panturrilha em pé com barra',
  'barbell standing reverse-grip curl': 'Rosca inversa em pé com barra',
  'barbell standing rocking leg calf raise':
      'Panturrilha em pé com balanço e barra',
  'barbell standing twist': 'Rotação em pé com barra',
  'barbell standing wide military press':
      'Desenvolvimento militar aberto em pé com barra',
  'barbell standing wide-grip biceps curl':
      'Rosca direta aberta em pé com barra',
  'barbell step-up': 'Subida no banco com barra',
  'barbell straight-leg deadlift': 'Stiff com barra',
  'barbell sumo deadlift': 'Levantamento terra sumô com barra',
  'barbell thruster': 'Thruster com barra',
  'barbell wide bench press': 'Supino reto aberto com barra',
  'barbell wide reverse-grip bench press':
      'Supino aberto com barra (pegada supinada)',
  'barbell wide squat': 'Agachamento sumô com barra',
  'barbell wide-grip upright row': 'Remada alta aberta com barra',
  'barbell wrist curl': 'Rosca de punho com barra',
  'barbell zercher squat': 'Agachamento Zercher com barra',
  'bench dip (knees bent)': 'Mergulho no banco (joelhos flexionados)',
  'bench dip on floor': 'Mergulho no banco com pés no chão',
  'bench hip extension': 'Extensão de quadril no banco',
  'bench pull-ups': 'Barra fixa no banco',
  'bent knee lying twist': 'Rotação de tronco deitado com joelhos flexionados',
  'biceps leg concentration curl': 'Rosca concentrada apoiada na perna',
  'biceps narrow pull-ups': 'Barra fixa fechada para bíceps',
  'biceps pull-up': 'Barra fixa para bíceps',
  'bicycle crunch': 'Abdominal bicicleta',
  'bodyweight drop jump squat':
      'Agachamento com salto em queda (peso do corpo)',
  'bodyweight incline side plank': 'Prancha lateral inclinada (peso do corpo)',
  'bodyweight kneeling triceps extension': 'Tríceps ajoelhado (peso do corpo)',
  'bodyweight side-lying biceps curl': 'Rosca deitado de lado (peso do corpo)',
  'bodyweight squatting row': 'Remada agachado (peso do corpo)',
  'bodyweight squatting row (with towel)':
      'Remada agachado com toalha (peso do corpo)',
  'bodyweight standing calf raise': 'Panturrilha em pé (peso do corpo)',
  'bodyweight standing close-grip row': 'Remada fechada em pé (peso do corpo)',
  'bodyweight standing row': 'Remada em pé (peso do corpo)',
  'bodyweight standing row (with towel)':
      'Remada em pé com toalha (peso do corpo)',
  'bodyweight standing single-arm row':
      'Remada unilateral em pé (peso do corpo)',
  'bodyweight standing single-arm row (with towel)':
      'Remada unilateral em pé com toalha (peso do corpo)',
  'box jump down with single-leg stabilization':
      'Descida da caixa com estabilização unilateral',
  'bridge - mountain climber (cross body)': 'Ponte com escalador cruzado',
  'butterfly yoga pose': 'Postura borboleta (ioga)',
  'cable alternate shoulder press': 'Desenvolvimento alternado na polia',
  'cable alternate triceps extension': 'Tríceps alternado na polia',
  'cable assisted inverse leg curl':
      'Flexão de pernas invertida assistida na polia',
  'cable bar lateral pulldown': 'Puxada alta na polia com barra',
  'cable bench press': 'Supino na polia',
  'cable close-grip curl': 'Rosca fechada na polia',
  'cable concentration curl': 'Rosca concentrada na polia',
  'cable concentration extension (on knee)':
      'Extensão concentrada na polia (apoiado no joelho)',
  'cable crossover lateral pulldown': 'Puxada lateral em crossover na polia',
  'cable crossover reverse fly': 'Crucifixo inverso em crossover na polia',
  'cable curl': 'Rosca na polia',
  'cable decline fly': 'Crucifixo declinado na polia',
  'cable decline press': 'Supino declinado na polia',
  'cable decline seated wide-grip row':
      'Remada sentada declinada aberta na polia',
  'cable decline single-arm press': 'Supino declinado unilateral na polia',
  'cable drag curl': 'Rosca arrastada na polia',
  'cable floor seated wide-grip row': 'Remada sentada no chão aberta na polia',
  'cable forward raise': 'Elevação frontal na polia',
  'cable front shoulder raise': 'Elevação frontal de ombro na polia',
  'cable hammer curl (with rope)': 'Rosca martelo na polia com corda',
  'cable high pulley overhead triceps extension':
      'Tríceps francês na polia alta',
  'cable high row (kneeling)': 'Remada alta na polia (ajoelhado)',
  'cable incline bench press': 'Supino inclinado na polia',
  'cable incline bench row': 'Remada no banco inclinado na polia',
  'cable incline fly': 'Crucifixo inclinado na polia',
  'cable incline fly (on stability ball)':
      'Crucifixo inclinado na polia (na bola suíça)',
  'cable kickback': 'Coice na polia',
  'cable kneeling crunch': 'Abdominal ajoelhado na polia',
  'cable kneeling rear delt row (with rope)':
      'Remada para deltoide posterior ajoelhado na polia com corda',
  'cable lat pulldown full range of motion':
      'Puxada alta na polia com amplitude completa',
  'cable lateral pulldown (with rope attachment)':
      'Puxada lateral na polia com corda',
  'cable lateral pulldown with v-bar': 'Puxada lateral na polia com barra V',
  'cable lateral raise': 'Elevação lateral na polia',
  'cable low fly': 'Crucifixo baixo na polia',
  'cable low seated row': 'Remada baixa sentada na polia',
  'cable lying biceps curl': 'Rosca deitado na polia',
  'cable lying close-grip curl': 'Rosca fechada deitado na polia',
};
