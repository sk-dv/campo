import '../models/exercise.dart';
import '../models/training_session.dart';

class SeedData {
  static List<Exercise> buildExercises() {
    return [
      // ── Lunes ──────────────────────────────────────────────────────────────
      Exercise(
        id: 'ex-mon-1',
        name: 'Automasaje con pelota de tenis en piernas',
        category: ExerciseCategory.movilidad,
        durationMinutes: 10,
        instructions: [
          'Coloca la pelota de tenis bajo el cuádriceps y apoya tu peso sobre ella.',
          'Rueda lentamente buscando puntos de tensión.',
          'Repite en gemelos y planta del pie.',
          'Detente 20-30 segundos en los puntos más tensos.',
        ],
      ),
      Exercise(
        id: 'ex-mon-2',
        name: 'Movilidad de cadera, tobillos y columna',
        category: ExerciseCategory.movilidad,
        durationMinutes: 10,
        instructions: [
          'Realiza círculos lentos de cadera en ambas direcciones, 10 repeticiones.',
          'Moviliza los tobillos rotando cada pie.',
          'Haz giros suaves de columna sentado o de pie.',
          'Mantén cada posición 3-5 segundos.',
        ],
      ),
      Exercise(
        id: 'ex-mon-3',
        name: 'Trote suave',
        category: ExerciseCategory.fisico,
        durationMinutes: 15,
        instructions: [
          'Arranca a paso muy tranquilo, sin exigirte ritmo.',
          'Mantén respiración nasal si puedes.',
          'Si sientes fatiga, camina 1-2 minutos y retoma.',
          'Termina los últimos 2 minutos caminando.',
        ],
      ),
      Exercise(
        id: 'ex-mon-4',
        name: 'Estiramientos estáticos',
        category: ExerciseCategory.movilidad,
        durationMinutes: 5,
        instructions: [
          'Estira cuádriceps de pie, sostén 30 segundos cada pierna.',
          'Isquiotibiales sentado, inclínate hacia adelante suavemente.',
          'Gemelos contra una pared.',
          'No rebotes, mantén cada posición.',
        ],
      ),

      // ── Martes ─────────────────────────────────────────────────────────────
      Exercise(
        id: 'ex-tue-1',
        name: 'Calentamiento con balón',
        category: ExerciseCategory.tecnica,
        durationMinutes: 8,
        instructions: [
          'Conduce el balón caminando, cambia de pie cada 5 metros.',
          'Toque suave alternando interior de ambos pies.',
          'Aumenta velocidad gradualmente.',
          'Incluye giros y cambios de dirección lentos.',
        ],
      ),
      Exercise(
        id: 'ex-tue-2',
        name: 'Control y primer toque',
        category: ExerciseCategory.tecnica,
        durationMinutes: 15,
        instructions: [
          'Lanza el balón contra la pared desde 3 metros.',
          'Controla con interior, exterior o planta alternando cada toque.',
          'Control orientado: recibe y ya sabes hacia dónde vas — no controles para después decidir.',
          'Mantén el balón cerca, no más de 30cm del pie.',
          'Descansa 1 min entre series de 3 min.',
        ],
      ),
      Exercise(
        id: 'ex-tue-3',
        name: 'Conducción y regate',
        category: ExerciseCategory.tecnica,
        durationMinutes: 15,
        instructions: [
          'Coloca conos o marcas en el piso separados 1.5 metros.',
          'Conduce en slalom a velocidad moderada.',
          'Practica cambios de dirección con el interior y exterior del pie.',
          'Aumenta velocidad en las últimas series.',
        ],
      ),
      Exercise(
        id: 'ex-tue-4',
        name: 'Pase con pared',
        category: ExerciseCategory.tecnica,
        durationMinutes: 10,
        instructions: [
          'Posiciónate a 4-5 metros de la pared.',
          'Realiza pases con el interior del pie, controlando el rebote.',
          'Alterna pie derecho e izquierdo.',
          'Varía la fuerza del pase para trabajar distintos rangos.',
        ],
      ),
      Exercise(
        id: 'ex-tue-5',
        name: 'Finalización',
        category: ExerciseCategory.tecnica,
        durationMinutes: 10,
        instructions: [
          'Define una portería o marca en la pared como objetivo.',
          'Conduce y remata desde distintos ángulos.',
          'Practica el disparo con ambos pies.',
          'Incluye algún remate tras control previo.',
        ],
      ),

      // ── Miércoles ──────────────────────────────────────────────────────────
      Exercise(
        id: 'ex-wed-1',
        name: 'Calentamiento trote',
        category: ExerciseCategory.fisico,
        durationMinutes: 5,
        instructions: [
          'Trota suave para elevar la temperatura muscular.',
          'Incluye skipping bajo y talones al glúteo.',
          'Realiza movilidad dinámica de caderas y tobillos.',
          'Los últimos 30 segundos aumenta un poco el ritmo.',
        ],
      ),
      Exercise(
        id: 'ex-wed-2',
        name: '4×400m resistencia',
        category: ExerciseCategory.fisico,
        durationMinutes: 25,
        instructions: [
          'Corre 400m a ritmo moderado-fuerte, donde puedas mantener conversación corta.',
          'Descansa 90 segundos caminando entre cada repetición.',
          'En las primeras 2 semanas realiza solo 2×400m.',
          'Registra mentalmente si el ritmo se mantiene estable.',
        ],
      ),
      Exercise(
        id: 'ex-wed-3',
        name: 'Sprints 30m ×6',
        category: ExerciseCategory.fisico,
        durationMinutes: 10,
        instructions: [
          'Marca una distancia de 30 metros.',
          'Arranca desde parado a máxima velocidad.',
          'Camina de regreso como recuperación.',
          'En las primeras 2 semanas realiza solo 3-4 sprints.',
        ],
      ),
      Exercise(
        id: 'ex-wed-4',
        name: 'Dominadas 3 series',
        category: ExerciseCategory.fisico,
        durationMinutes: 8,
        instructions: [
          'Agárrate a la barra con las palmas hacia afuera, ancho de hombros.',
          'Sube hasta que la barbilla supere la barra.',
          'Baja de forma controlada sin soltarte.',
          'Si no puedes completar la serie, usa asistencia o haz negativas.',
        ],
      ),
      Exercise(
        id: 'ex-wed-5',
        name: 'Fondos en paralelas 3×10',
        category: ExerciseCategory.fisico,
        durationMinutes: 5,
        instructions: [
          'Apóyate en las paralelas con los brazos extendidos.',
          'Baja controlando el movimiento hasta 90 grados de codo.',
          'Empuja hacia arriba sin bloquear los codos.',
          'En las primeras semanas reduce a 3×6 si es necesario.',
        ],
      ),

      // ── Jueves ─────────────────────────────────────────────────────────────
      Exercise(
        id: 'ex-thu-1',
        name: 'Calentamiento dinámico sin balón',
        category: ExerciseCategory.movilidad,
        durationMinutes: 8,
        instructions: [
          'Skipping alto y bajo alternados, 2 series de 20 metros.',
          'Movilidad de cadera en movimiento, pasos laterales.',
          'Talones al glúteo trotando 20 metros.',
          'Termina con 2 aceleraciones suaves de 15 metros.',
        ],
      ),
      Exercise(
        id: 'ex-thu-2',
        name: 'Técnica del día (rotación semanal)',
        category: ExerciseCategory.tecnica,
        durationMinutes: 20,
        instructions: [
          'Semana 1: trabaja regate — sombrero, recorte, elastico.',
          'Semana 2: cabeceo — posición, timing, dirección.',
          'Semana 3: pase largo — apoyo del pie, contacto con el empeine.',
          'Semana 4: primer toque bajo presión simulada con obstáculos.',
        ],
      ),
      Exercise(
        id: 'ex-thu-3',
        name: 'Conducción explosiva',
        category: ExerciseCategory.tecnica,
        durationMinutes: 15,
        instructions: [
          'Conduce el balón a máxima velocidad durante 20 metros.',
          'Para en seco y cambia de dirección.',
          'Remata al terminar cada serie.',
          'Descansa 45 segundos entre repeticiones.',
        ],
      ),

      // ── Viernes ────────────────────────────────────────────────────────────
      Exercise(
        id: 'ex-fri-1',
        name: 'Trote suave de activación',
        category: ExerciseCategory.fisico,
        durationMinutes: 10,
        instructions: [
          'Trota sin exigencia a un ritmo muy cómodo.',
          'No busques rendimiento, solo activar el cuerpo.',
          'Incluye cambios de dirección suaves.',
          'Termina los últimos 2 minutos caminando.',
        ],
      ),
      Exercise(
        id: 'ex-fri-2',
        name: 'Toques libres con balón',
        category: ExerciseCategory.tecnica,
        durationMinutes: 10,
        instructions: [
          'Juega libremente con el balón sin estructura.',
          'Practica caños, toques de cabeza, malabares.',
          'Sin presión ni objetivo fijo.',
          'Disfruta el contacto con el balón antes del partido.',
        ],
      ),
      Exercise(
        id: 'ex-fri-3',
        name: 'Estiramientos dinámicos',
        category: ExerciseCategory.movilidad,
        durationMinutes: 5,
        instructions: [
          'Balanceo de piernas hacia adelante y atrás, 10 repeticiones.',
          'Estocadas caminando, 5 cada pierna.',
          'Rotación de tronco con brazos extendidos.',
          'Círculos de tobillo y rodilla.',
        ],
      ),
      Exercise(
        id: 'ex-fri-4',
        name: 'Visualización pre-partido',
        category: ExerciseCategory.movilidad,
        durationMinutes: 5,
        instructions: [
          'Cierra los ojos y visualiza tu posición en el partido.',
          'Imagina movimientos que quieres ejecutar mañana.',
          'Piensa en situaciones de partido que quieres resolver mejor.',
          'Termina con una respiración profunda y mentalidad positiva.',
        ],
      ),

      // ── Ejercicios del ciclo — Técnica lateral ────────────────────────────
      Exercise(
        id: 'ex-lateral-centros',
        name: 'Centros desde la banda',
        category: ExerciseCategory.tecnica,
        durationMinutes: 15,
        instructions: [
          'Posiciónate en la banda derecha o izquierda a ~20 metros del área.',
          'Conduce 10 metros hacia la línea de fondo antes de centrar.',
          'Apoyo del pie contrario firme al suelo al momento del contacto.',
          'Contacto con el empeine interior, no con la punta.',
          'Sigue el movimiento del pie después del contacto — no cortes el gesto.',
          'Si estás solo, practica la mecánica del movimiento sin balón o contra la pared.',
          'Alterna 5 repeticiones con cada pie.',
        ],
      ),
      Exercise(
        id: 'ex-lateral-circuit',
        name: 'Circuito lateral — subida, centro, regreso',
        category: ExerciseCategory.fisico,
        durationMinutes: 15,
        instructions: [
          'Conduce 20 metros a ritmo moderado simulando la subida del lateral.',
          'Al llegar al extremo: realiza un centro o pase fuerte a la pared.',
          'Trota de regreso al punto de inicio.',
          'Descansa 45 segundos.',
          'Repite 8 series.',
          'Objetivo: simular el trabajo real del lateral — subida → entrega → regreso.',
        ],
      ),

      // ── Fuerza ─────────────────────────────────────────────────────────────
      Exercise(
        id: 'ex-strength-core',
        name: 'Circuito core — peso corporal',
        category: ExerciseCategory.fisico,
        durationMinutes: 20,
        instructions: [
          'Plancha frontal: 3 series de 30 segundos. Cuerpo recto, no dejes caer las caderas.',
          'Plancha lateral: 3 series de 20 segundos por lado.',
          'Sentadillas: 3 series de 12 repeticiones. Baja hasta 90°, rodillas alineadas.',
          'Zancadas caminando: 3 series de 10 pasos por pierna.',
          'Descanso 45 segundos entre ejercicios.',
        ],
      ),
      Exercise(
        id: 'ex-run-easy',
        name: 'Carrera continua 30 min — ritmo conversacional',
        category: ExerciseCategory.fisico,
        durationMinutes: 30,
        instructions: [
          'Ritmo cómodo donde puedas mantener una conversación corta.',
          'Los primeros 5 minutos: muy suave, solo activar.',
          'Minutos 5-25: ritmo constante, no subas aunque te sientas bien.',
          'Últimos 5 minutos: baja el ritmo gradualmente, termina caminando.',
          'No importa la velocidad — importa sostener el ritmo sin parar.',
        ],
      ),
      Exercise(
        id: 'ex-run-medium',
        name: 'Correr 35 min + 4 sprints de 30m',
        category: ExerciseCategory.fisico,
        durationMinutes: 40,
        instructions: [
          'Corre 35 minutos a ritmo moderado-fuerte (más exigente que la semana 1).',
          'Al terminar los 35 minutos: descansa 2 minutos caminando.',
          'Realiza 4 sprints de 30 metros a máxima velocidad.',
          'Entre sprints: camina de regreso como recuperación completa.',
          'Termina con 5 minutos de trote suave.',
        ],
      ),
      Exercise(
        id: 'ex-sprints-short',
        name: 'Sprints cortos 15m ×3 — activación pre-partido',
        category: ExerciseCategory.fisico,
        durationMinutes: 5,
        instructions: [
          'Marca 15 metros.',
          'Corre al 80% de tu máximo — no a tope, solo encender el cuerpo.',
          'Camina de regreso entre cada sprint.',
          'Objetivo: sentir el cuerpo rápido, no agotarlo.',
          'Máximo 3 sprints. Si te sientes bien, no hagas más.',
        ],
      ),

      // ── Ejercicios mentales ───────────────────────────────────────────────
      Exercise(
        id: 'ex-mental-viz',
        name: 'Visualización de jugada exitosa',
        category: ExerciseCategory.mental,
        durationMinutes: 10,
        instructions: [
          'Siéntate en un lugar tranquilo. Cierra los ojos.',
          'Recuerda una jugada tuya que salió bien en cualquier partido anterior.',
          'Detalla el movimiento: la recepción, el primer toque, la decisión, la ejecución.',
          'Siente el contacto del balón, la posición del cuerpo, el resultado.',
          'Repite la imagen 3 veces con detalle creciente.',
          'Termina con una respiración profunda.',
          'Úsala: viernes pre-partido o cualquier día de bajo ánimo.',
        ],
      ),
      Exercise(
        id: 'ex-mental-reset',
        name: 'Reset de desánimo',
        category: ExerciseCategory.mental,
        durationMinutes: 5,
        instructions: [
          'Di o escribe 1 cosa concreta que sí lograste esta semana relacionada con el fútbol.',
          'Recuérdate: una sesión perdida no borra las anteriores.',
          'Visualiza el partido del 12 de abril — ya llevas 20 minutos jugando bien.',
          'Respiración 4-7-8: inhala 4 seg, retén 7, exhala 8.',
          'Repite la respiración 3 veces.',
          'Úsalo: cuando pierdas un día o el ánimo baje.',
        ],
      ),
      Exercise(
        id: 'ex-mental-prepartido',
        name: 'Protocolo pre-partido',
        category: ExerciseCategory.mental,
        durationMinutes: 15,
        instructions: [
          '2 horas antes: sin redes sociales. Pon música que te active — tu playlist de Tritón funciona.',
          '45 min antes: visualiza tus primeras 3 subidas por banda del partido.',
          'Imagina la recepción, la conducción, el centro — con detalle.',
          '15 min antes: respiración 4-7-8 tres veces.',
          'Al entrar a la cancha: di tu frase corta de activación (defínela tú, que sea tuya).',
          'En el calentamiento: un sprint corto para sentir el cuerpo.',
        ],
      ),
    ];
  }

  static List<TrainingSession> buildSessions() {
    return [
      // ── Sesiones base (estructura semanal original) ────────────────────────
      TrainingSession(
        id: 'session-1',
        weekday: 1,
        title: 'Recuperación activa',
        subtitle: 'Deportivo / Casa · 30-40 min',
        exerciseIds: ['ex-mon-1', 'ex-mon-2', 'ex-mon-3', 'ex-mon-4'],
      ),
      TrainingSession(
        id: 'session-2',
        weekday: 2,
        title: 'Técnica con balón',
        subtitle: 'Deportivo · 50-60 min',
        exerciseIds: [
          'ex-tue-1',
          'ex-tue-2',
          'ex-tue-3',
          'ex-tue-4',
          'ex-tue-5',
        ],
      ),
      TrainingSession(
        id: 'session-3',
        weekday: 3,
        title: 'Físico',
        subtitle: 'Pista + Barras · 50-60 min',
        exerciseIds: [
          'ex-wed-1',
          'ex-wed-2',
          'ex-wed-3',
          'ex-wed-4',
          'ex-wed-5',
        ],
      ),
      TrainingSession(
        id: 'session-4',
        weekday: 4,
        title: 'Técnica + velocidad',
        subtitle: 'Deportivo · 45-50 min',
        exerciseIds: ['ex-thu-1', 'ex-thu-2', 'ex-thu-3'],
      ),
      TrainingSession(
        id: 'session-5',
        weekday: 5,
        title: 'Activación pre-partido',
        subtitle: 'Deportivo / Casa · 25-30 min',
        exerciseIds: [
          'ex-fri-1',
          'ex-fri-2',
          'ex-fri-3',
          'ex-fri-4',
        ],
      ),

      // ── Sesiones del ciclo "Hacia el partido del 12 de abril" ──────────────
      TrainingSession(
        id: 'sesion-001',
        weekday: 3, // referencia sugerida (miércoles 1 abril)
        title: 'Arranque del ciclo — técnica lateral',
        subtitle: 'Deportivo · 60 min',
        exerciseIds: [
          'ex-mon-2',         // movilidad cadera/tobillos (bloque 1)
          'ex-tue-2',         // control y primer toque (bloque 2)
          'ex-lateral-centros', // centros desde la banda (bloque 2)
          'ex-lateral-circuit', // circuito lateral (bloque 3)
          'ex-mental-viz',    // visualización (bloque 4 — cierre mental)
        ],
      ),
      TrainingSession(
        id: 'sesion-correr-1',
        weekday: 0, // sin día fijo
        title: 'Correr — 30 min fácil',
        subtitle: 'Parque / Calle · 30 min',
        exerciseIds: ['ex-run-easy'],
      ),
      TrainingSession(
        id: 'sesion-fuerza-1',
        weekday: 0,
        title: 'Fuerza — core + piernas',
        subtitle: 'Barras / Casa · 35-40 min',
        exerciseIds: ['ex-wed-4', 'ex-wed-5', 'ex-strength-core'],
      ),
      TrainingSession(
        id: 'sesion-tecnica-2',
        weekday: 0,
        title: 'Técnica semana 2 — posición lateral + ritmo',
        subtitle: 'Deportivo · 60 min',
        exerciseIds: [
          'ex-tue-1',           // calentamiento con balón
          'ex-lateral-centros', // centros desde la banda
          'ex-tue-3',           // conducción y regate
          'ex-thu-3',           // conducción explosiva
        ],
      ),
      TrainingSession(
        id: 'sesion-correr-2',
        weekday: 0,
        title: 'Correr — 35 min + sprints',
        subtitle: 'Pista / Calle · 40 min',
        exerciseIds: ['ex-run-medium'],
      ),
      TrainingSession(
        id: 'sesion-pre-partido',
        weekday: 6, // sábado 11 abril
        title: 'Entrenamiento pre-partido',
        subtitle: 'Deportivo / Casa · 45 min',
        exerciseIds: [
          'ex-fri-1',              // trote suave
          'ex-fri-2',              // toques libres
          'ex-fri-3',              // estiramientos dinámicos
          'ex-mental-prepartido',  // protocolo pre-partido
          'ex-sprints-short',      // sprints cortos 15m
        ],
      ),
    ];
  }
}
