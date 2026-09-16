/// The mascot's copy deck (PRD §6).
///
/// One voice, two languages, written once and kept here rather than inline in
/// screens. Tone: warm, short, never guilt. The mascot explains what changed
/// and what to do next; it never sells, and it never says "overdue".
///
/// Dutch is the launch language, so `nl` is written first and `en` follows it
/// rather than the other way round.
library;

import '../timing/types.dart';

/// Every line the mascot can say, keyed by where it says it.
abstract final class MascotLines {
  // ── empty states (base 8.16) ──────────────────────────────────────────────
  static const seasonEmpty = LocalizedText(
    nl: 'Zet een plant in je tuin, dan legt je seizoen zich hier vanzelf neer.',
    en: 'Add a plant and your season lays itself out here.',
  );

  static const gardenPlanningEmpty = LocalizedText(
    nl: 'Nog niets gepland. Tik "Plan het" bij een gewas en het komt hier te staan.',
    en: 'Nothing planned yet. Tap "Plan it" on a crop and it lands here.',
  );

  static const gardenGrowingEmpty = LocalizedText(
    nl: 'Nog niets aan het groeien. Start een geplant gewas, dan begint het pad.',
    en: 'Nothing growing yet. Start a planned crop and the path begins.',
  );

  static const harvestEmpty = LocalizedText(
    nl: 'Nog niets geoogst. Log je eerste oogst, dan begint de teller te lopen.',
    en: 'Nothing picked yet. Log a harvest and the tally starts.',
  );

  static const pathEmpty = LocalizedText(
    nl: 'Nog geen pad. Druk op Start als deze plant de grond in gaat, het pad bouwt zichzelf.',
    en: 'No path yet. Press Start when this plant goes in. The path builds itself.',
  );

  // ── the plan moved, nobody is behind (PRD §7.2) ───────────────────────────
  static const notBehindNothingMoved = LocalizedText(
    nl: 'Genoteerd. De rest van het plan hoefde niet te schuiven.',
    en: 'Logged. Nothing else needed to move.',
  );

  /// Takes the step, the number of days and how many later steps followed.
  static LocalizedText notBehind({
    required LocalizedText step,
    required int days,
    required bool later,
    required int moved,
  }) =>
      LocalizedText(
        nl: 'Je loopt niet achter. ${step.nl} was $days dagen '
            '${later ? 'later' : 'eerder'} dan gepland, dus $moved volgende '
            '${moved == 1 ? 'stap schuift' : 'stappen schuiven'} mee.',
        en: "You're not behind. ${step.en} was $days days "
            '${later ? 'later' : 'earlier'} than planned, so $moved upcoming '
            '${moved == 1 ? 'step moves' : 'steps move'} with it.',
      );

  static const frostWarning = LocalizedText(
    nl: 'Let op: de nieuwe oogstdatum valt vlak bij de eerste vorst. Doorgaan '
        'mag, een snellere variëteit is veiliger.',
    en: 'Careful: the new harvest date lands near the first frost. Growing it '
        'anyway is fine, a faster variety is safer.',
  );

  // ── the season's own markers ──────────────────────────────────────────────
  static const ijsheiligen = LocalizedText(
    nl: 'De ijsheiligen, 11 tot en met 15 mei. Nachtvorst in deze week is in '
        'Nederland heel gewoon, dus tomaat, courgette en basilicum blijven tot '
        'daarna binnen of onder een doek.',
    en: 'The ice saints, 11 to 15 May. A late night frost in this week is '
        'common in the Netherlands, so tomatoes, courgettes and basil stay '
        'under cover until it passes.',
  );

  static const lastFrost = LocalizedText(
    nl: 'De gemiddelde laatste voorjaarsvorst voor jouw regio. Elke zaaidatum '
        'in de app telt vanaf hier, en een gemiddelde is geen belofte: kijk de '
        'dagen ervoor en erna naar het weerbericht.',
    en: 'The average last spring frost for your region. Every sowing date in '
        'the app is counted from it, and an average is not a promise: watch '
        'the forecast either side of it.',
  );

  static const firstFrost = LocalizedText(
    nl: 'De gemiddelde eerste najaarsvorst voor jouw regio. Oogstvensters '
        'tellen hiervandaan terug, dus wat na deze datum nog moet rijpen, '
        'leeft op geleende tijd.',
    en: 'The average first autumn frost for your region. Harvest windows are '
        'counted back from it, so anything still ripening after this date is '
        'on borrowed time.',
  );

  static const recap = LocalizedText(
    nl: 'Eind december telt het seizoen op: wat je hebt geteeld, wat je hebt '
        'geoogst en wat het je heeft bespaard.',
    en: 'At the end of December the season adds up: what you grew, what you '
        'picked, and what it saved you.',
  );

  static const seedOrder = LocalizedText(
    nl: 'Januari is zaadmaand. Bestel nu, dan ligt alles klaar als de grond '
        'opwarmt.',
    en: 'January is seed month. Order now and everything is ready when the '
        'soil warms up.',
  );

  // ── the weather moved something (F4) ──────────────────────────────────────
  static const rainSkipped = LocalizedText(
    nl: 'De regen heeft het water geven overgenomen. Overgeslagen voor je, je '
        'reeks telt gewoon door.',
    en: 'Rain did the watering. Skipped for you, and your streak still counts.',
  );

  static const heatAhead = LocalizedText(
    nl: 'Hitte op komst. Potten drogen binnen een dag uit, dus water geven '
        'schuift naar voren.',
    en: 'Heat on the way. Containers dry out in a day, so watering moves '
        'earlier.',
  );

  static const soilCold = LocalizedText(
    nl: 'De grond is nog te koud. Zaaien wacht tot het warmer wordt, dat '
        'scheelt je een mislukte zaaibeurt.',
    en: 'The soil is still too cold. Sowing waits until it warms up, which '
        'saves you a failed sowing.',
  );

  // ── the streak, which is never a stick (PRD §7.5) ─────────────────────────
  static const streakStart = LocalizedText(
    nl: 'Vink één taak af, of sla er één over met een reden. Regen telt mee.',
    en: 'Tick one task, or skip one with a reason. Rain counts.',
  );

  static LocalizedText streakGoing(int days) => LocalizedText(
        nl: '$days ${days == 1 ? 'dag' : 'dagen'} op rij. Mooi bezig.',
        en: '$days ${days == 1 ? 'day' : 'days'} in a row. Nicely done.',
      );

  static const streakBrokenBySeason = LocalizedText(
    nl: 'In de winter valt er weinig te doen, dus je reeks pauzeert gewoon. '
        'Hij pakt door zodra het seizoen dat ook doet.',
    en: 'There is little to do in winter, so your streak simply pauses. It '
        'picks up when the season does.',
  );

  // ── scanning, which is always a guess ─────────────────────────────────────
  static const scanNotAPlant = LocalizedText(
    nl: 'Dat lijkt geen plant. We zijn thuis in groente en fruit, probeer een '
        'blad of een vrucht.',
    en: 'That does not look like a plant. We know fruit and veg, so try a leaf '
        'or a fruit.',
  );

  static const scanNoMatch = LocalizedText(
    nl: 'Geen match. Probeer een scherpere foto van een blad of bloem, of zoek '
        'op naam.',
    en: 'No match. Try a closer shot of a leaf or flower, or search by name.',
  );

  static const scanHealthy = LocalizedText(
    nl: 'Ziet er gezond uit van hieraf.',
    en: 'Looks healthy from here.',
  );

  static const scanSignIn = LocalizedText(
    nl: 'Log eerst in bij Instellingen. Scans tellen per account.',
    en: 'Sign in first, under Settings. Scans are counted per account.',
  );

  // ── onboarding ────────────────────────────────────────────────────────────
  static const welcome = LocalizedText(
    nl: 'Hoi! Even kennismaken.',
    en: "Hi! Let's get to know each other.",
  );

  static const buildingPlan = LocalizedText(
    nl: 'Ik reken je seizoen door. Even geduld.',
    en: 'Working out your season. One moment.',
  );

  static const planReady = LocalizedText(
    nl: 'Je plan staat. Vanaf hier vertel ik je elke week wat er te doen is.',
    en: 'Your plan is ready. From here I tell you what to do each week.',
  );
}
