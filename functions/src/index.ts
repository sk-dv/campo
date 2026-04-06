import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { GoogleGenerativeAI } from '@google/generative-ai';

initializeApp();

const geminiKey = defineSecret('GEMINI_KEY');

const MONTHLY_CALL_LIMIT = 200;

interface Checkin {
  energyLevel: number;
  sleepHours: number;
  note: string;
}

interface CoachContext {
  cycleName: string;
  daysLeft: number;
  sessionsThisWeek: number;
  targetThisWeek: number;
  checkin?: Checkin;
}

export const askCoach = onCall(
  { secrets: [geminiKey], region: 'us-central1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Se requiere autenticación');
    }

    const uid = request.auth.uid;
    const db = getFirestore();

    // Guard: límite mensual
    const month = currentMonth();
    const usageRef = db.doc(`users/${uid}/usage/${month}`);
    const usageSnap = await usageRef.get();
    const calls = (usageSnap.data()?.calls as number) ?? 0;

    if (calls >= MONTHLY_CALL_LIMIT) {
      throw new HttpsError(
        'resource-exhausted',
        'Límite mensual alcanzado (200 sesiones)'
      );
    }

    const ctx = request.data.context as CoachContext;
    const prompt = buildPrompt(ctx);

    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
    const result = await model.generateContent(prompt);
    const text = result.response.text();

    await Promise.all([
      db.collection(`users/${uid}/coach_logs`).add({
        response: text,
        checkin: ctx.checkin ?? null,
        createdAt: FieldValue.serverTimestamp(),
      }),
      usageRef.set(
        {
          calls: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      ),
    ]);

    return { text };
  }
);

function buildPrompt(ctx: CoachContext): string {
  const checkinBlock = ctx.checkin
    ? `\nEstado de hoy: energía ${ctx.checkin.energyLevel}/10, sueño ${ctx.checkin.sleepHours}h. "${ctx.checkin.note}".`
    : '';

  return `Eres un coach deportivo personal. Tu atleta juega fútbol amateur \
como lateral y está en un ciclo de preparación.

Contexto:
- Ciclo: "${ctx.cycleName}" — faltan ${ctx.daysLeft} días.
- Esta semana: ${ctx.sessionsThisWeek} de ${ctx.targetThisWeek} sesiones \
completadas.${checkinBlock}

Dame retroalimentación en máximo 4 oraciones: reconoce lo que ha hecho, \
da una observación concreta sobre su progreso, y motívalo para lo que sigue. \
Tono directo, sin relleno. Habla en segunda persona.`;
}

function currentMonth(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}
