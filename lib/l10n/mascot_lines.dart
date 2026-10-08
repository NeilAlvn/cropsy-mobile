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
    de: 'Füg eine Pflanze hinzu, und deine Saison legt sich hier von selbst aus.',
  );

  static const gardenPlanningEmpty = LocalizedText(
    nl: 'Nog niets gepland. Tik "Plan het" bij een gewas en het komt hier te staan.',
    en: 'Nothing planned yet. Tap "Plan it" on a crop and it lands here.',
    de: 'Noch nichts geplant. Tippe bei einer Pflanze auf „Einplanen“, dann landet sie hier.',
  );

  static const gardenGrowingEmpty = LocalizedText(
    nl: 'Nog niets aan het groeien. Start een geplant gewas, dan begint het pad.',
    en: 'Nothing growing yet. Start a planned crop and the path begins.',
    de: 'Noch nichts im Anbau. Starte eine geplante Pflanze, dann beginnt der Pfad.',
  );

  static const harvestEmpty = LocalizedText(
    nl: 'Nog niets geoogst. Log je eerste oogst, dan begint de teller te lopen.',
    en: 'Nothing picked yet. Log a harvest and the tally starts.',
    de: 'Noch nichts geerntet. Trag eine Ernte ein, dann beginnt die Bilanz.',
  );

  static const pathEmpty = LocalizedText(
    nl: 'Nog geen pad. Druk op Start als deze plant de grond in gaat, het pad bouwt zichzelf.',
    en: 'No path yet. Press Start when this plant goes in. The path builds itself.',
    de: 'Noch kein Pfad. Tippe auf Start, wenn die Pflanze in die Erde kommt. Der Pfad baut sich von selbst.',
  );

  // ── the plan moved, nobody is behind (PRD §7.2) ───────────────────────────
  static const notBehindNothingMoved = LocalizedText(
    nl: 'Genoteerd. De rest van het plan hoefde niet te schuiven.',
    en: 'Logged. Nothing else needed to move.',
    de: 'Eingetragen. Sonst musste nichts verschoben werden.',
  );

  /// Takes the step, the number of days and how many later steps followed.
  static LocalizedText notBehind({
    required LocalizedText step,
    required int days,
    required bool later,
    required int moved,
  }) => LocalizedText(
    nl:
        'Je loopt niet achter. ${step.nl} was $days dagen '
        '${later ? 'later' : 'eerder'} dan gepland, dus $moved volgende '
        '${moved == 1 ? 'stap schuift' : 'stappen schuiven'} mee.',
    en:
        "You're not behind. ${step.en} was $days days "
        '${later ? 'later' : 'earlier'} than planned, so $moved upcoming '
        '${moved == 1 ? 'step moves' : 'steps move'} with it.',
    de:
        'Du hängst nicht hinterher. ${step.pick('de')} war $days '
        '${days == 1 ? 'Tag' : 'Tage'} ${later ? 'später' : 'früher'} als '
        'geplant, darum '
        '${moved == 1 ? 'zieht 1 weiterer Schritt' : 'ziehen $moved weitere Schritte'} mit.',
  );

  static const frostWarning = LocalizedText(
    nl:
        'Let op: de nieuwe oogstdatum valt vlak bij de eerste vorst. Doorgaan '
        'mag, een snellere variëteit is veiliger.',
    en:
        'Careful: the new harvest date lands near the first frost. Growing it '
        'anyway is fine, a faster variety is safer.',
    de: 'Achtung: Das neue Erntedatum liegt nah am ersten Frost. Weitermachen ist okay, eine schnellere Sorte ist sicherer.',
  );

  // ── the season's own markers ──────────────────────────────────────────────
  static const ijsheiligen = LocalizedText(
    nl:
        'De ijsheiligen, 11 tot en met 15 mei. Nachtvorst in deze week is in '
        'Nederland heel gewoon, dus tomaat, courgette en basilicum blijven tot '
        'daarna binnen of onder een doek.',
    en:
        'The ice saints, 11 to 15 May. A late night frost in this week is '
        'common in the Netherlands, so tomatoes, courgettes and basil stay '
        'under cover until it passes.',
    de: 'Die Eisheiligen, 11. bis 15. Mai. Ein später Nachtfrost in dieser Woche ist in den Niederlanden häufig, darum bleiben Tomaten, Zucchini und Basilikum geschützt, bis sie vorbei sind.',
  );

  static const lastFrost = LocalizedText(
    nl:
        'De gemiddelde laatste voorjaarsvorst voor jouw regio. Elke zaaidatum '
        'in de app telt vanaf hier, en een gemiddelde is geen belofte: kijk de '
        'dagen ervoor en erna naar het weerbericht.',
    en:
        'The average last spring frost for your region. Every sowing date in '
        'the app is counted from it, and an average is not a promise: watch '
        'the forecast either side of it.',
    de: 'Der durchschnittliche letzte Frühjahrsfrost in deiner Region. Jedes Aussaatdatum in der App wird von ihm aus gerechnet, und ein Durchschnitt ist kein Versprechen: Behalte rund um den Termin die Vorhersage im Blick.',
  );

  static const firstFrost = LocalizedText(
    nl:
        'De gemiddelde eerste najaarsvorst voor jouw regio. Oogstvensters '
        'tellen hiervandaan terug, dus wat na deze datum nog moet rijpen, '
        'leeft op geleende tijd.',
    en:
        'The average first autumn frost for your region. Harvest windows are '
        'counted back from it, so anything still ripening after this date is '
        'on borrowed time.',
    de: 'Der durchschnittliche erste Herbstfrost in deiner Region. Erntefenster werden von ihm aus zurückgerechnet, für alles, was danach noch reift, wird es also knapp.',
  );

  static const recap = LocalizedText(
    nl:
        'Eind december telt het seizoen op: wat je hebt geteeld, wat je hebt '
        'geoogst en wat het je heeft bespaard.',
    en:
        'At the end of December the season adds up: what you grew, what you '
        'picked, and what it saved you.',
    de: 'Ende Dezember zieht die Saison Bilanz: was du angebaut und geerntet hast und was es dir gespart hat.',
  );

  static const seedOrder = LocalizedText(
    nl:
        'Januari is zaadmaand. Bestel nu, dan ligt alles klaar als de grond '
        'opwarmt.',
    en:
        'January is seed month. Order now and everything is ready when the '
        'soil warms up.',
    de: 'Januar ist Saatgut-Monat. Bestell jetzt, dann liegt alles bereit, wenn der Boden warm wird.',
  );

  // ── the weather moved something (F4) ──────────────────────────────────────
  static const rainSkipped = LocalizedText(
    nl:
        'De regen heeft het water geven overgenomen. Overgeslagen voor je, je '
        'reeks telt gewoon door.',
    en: 'Rain did the watering. Skipped for you, and your streak still counts.',
    de: 'Der Regen hat gegossen. Für dich übersprungen, und deine Serie zählt trotzdem.',
  );

  static const heatAhead = LocalizedText(
    nl:
        'Hitte op komst. Potten drogen binnen een dag uit, dus water geven '
        'schuift naar voren.',
    en:
        'Heat on the way. Containers dry out in a day, so watering moves '
        'earlier.',
    de: 'Hitze im Anmarsch. Töpfe trocknen an einem Tag aus, darum rückt das Gießen nach vorne.',
  );

  static const soilCold = LocalizedText(
    nl:
        'De grond is nog te koud. Zaaien wacht tot het warmer wordt, dat '
        'scheelt je een mislukte zaaibeurt.',
    en:
        'The soil is still too cold. Sowing waits until it warms up, which '
        'saves you a failed sowing.',
    de: 'Der Boden ist noch zu kalt. Gesät wird, sobald er wärmer ist, das erspart dir eine misslungene Aussaat.',
  );

  // ── the streak, which is never a stick (PRD §7.5) ─────────────────────────
  static const streakStart = LocalizedText(
    nl: 'Vink één taak af, of sla er één over met een reden. Regen telt mee.',
    en: 'Tick one task, or skip one with a reason. Rain counts.',
    de: 'Hak eine Aufgabe ab oder überspring eine mit Grund. Regen zählt.',
  );

  static LocalizedText streakGoing(int days) => LocalizedText(
    nl: '$days ${days == 1 ? 'dag' : 'dagen'} op rij. Mooi bezig.',
    en: '$days ${days == 1 ? 'day' : 'days'} in a row. Nicely done.',
    de: '$days ${days == 1 ? 'Tag' : 'Tage'} in Folge. Gut gemacht.',
  );

  static const streakBrokenBySeason = LocalizedText(
    nl:
        'In de winter valt er weinig te doen, dus je reeks pauzeert gewoon. '
        'Hij pakt door zodra het seizoen dat ook doet.',
    en:
        'There is little to do in winter, so your streak simply pauses. It '
        'picks up when the season does.',
    de: 'Im Winter gibt es wenig zu tun, darum pausiert deine Serie einfach. Sie geht weiter, wenn die Saison weitergeht.',
  );

  // ── scanning, which is always a guess ─────────────────────────────────────
  static const scanNotAPlant = LocalizedText(
    nl:
        'Dat lijkt geen plant. We zijn thuis in groente en fruit, probeer een '
        'blad of een vrucht.',
    en:
        'That does not look like a plant. We know fruit and veg, so try a leaf '
        'or a fruit.',
    de: 'Das sieht nicht nach einer Pflanze aus. Wir kennen Obst und Gemüse, versuch es mit einem Blatt oder einer Frucht.',
  );

  static const scanNoMatch = LocalizedText(
    nl:
        'Geen match. Probeer een scherpere foto van een blad of bloem, of zoek '
        'op naam.',
    en: 'No match. Try a closer shot of a leaf or flower, or search by name.',
    de: 'Kein Treffer. Versuch eine nähere Aufnahme von einem Blatt oder einer Blüte, oder such nach dem Namen.',
  );

  static const scanHealthy = LocalizedText(
    nl: 'Ziet er gezond uit van hieraf.',
    en: 'Looks healthy from here.',
    de: 'Sieht von hier gesund aus.',
  );

  static const scanNothingRecognisable = LocalizedText(
    nl:
        'Niets herkenbaars. Blader hieronder door de veelvoorkomende '
        'problemen.',
    en: 'Nothing recognisable. Browse the common problems below instead.',
    de: 'Nichts erkennbar. Schau stattdessen unten bei den häufigen Problemen.',
  );

  static const scanBestGuesses = LocalizedText(
    nl:
        'Beste gokken, meest waarschijnlijke eerst. Niet deze plant? Kies een '
        'andere of zoek op naam.',
    en:
        'Best guesses, most likely first. Not this plant? Pick another or '
        'search by name.',
    de: 'Beste Vermutungen, die wahrscheinlichste zuerst. Nicht diese Pflanze? Wähl eine andere oder such nach dem Namen.',
  );

  static const scanIsAGuess = LocalizedText(
    nl: 'Dit is een gok op basis van de foto, geen diagnose.',
    en: 'This is a guess from the photo, not a diagnosis.',
    de: 'Das ist eine Vermutung anhand des Fotos, keine Diagnose.',
  );

  static const problemsComing = LocalizedText(
    nl:
        'De 25 problemen die op Nederlandse balkons spelen, slakken, luizen, '
        'meeldauw, neusrot, worden geschreven en nagekeken. Ze komen met de '
        'contentupdate.',
    en:
        'The 25 problems common on Dutch balconies, slakken, luizen, meeldauw, '
        'neusrot, are being written and checked. They land with the content '
        'update.',
    de: 'Die 25 häufigsten Probleme auf niederländischen Balkonen, Schnecken, Läuse, Mehltau, Blütenendfäule, werden geschrieben und geprüft. Sie kommen mit dem Inhalts-Update.',
  );

  static const seasonLaysItselfOut = LocalizedText(
    nl: 'Zet een plant neer en het seizoen legt zichzelf hier uit.',
    en: 'Add a plant and the season lays itself out here.',
    de: 'Füg eine Pflanze hinzu, und die Saison legt sich hier von selbst aus.',
  );

  static const scanSignIn = LocalizedText(
    nl: 'Log eerst in bij Instellingen. Scans tellen per account.',
    en: 'Sign in first, under Settings. Scans are counted per account.',
    de: 'Melde dich zuerst unter Einstellungen an. Scans werden pro Konto gezählt.',
  );

  // ── onboarding ────────────────────────────────────────────────────────────
  static const welcome = LocalizedText(
    nl: 'Hoi! Even kennismaken.',
    en: "Hi! Let's get to know each other.",
    de: 'Hallo! Lernen wir uns kennen.',
  );

  static const buildingPlan = LocalizedText(
    nl: 'Ik reken je seizoen door. Even geduld.',
    en: 'Working out your season. One moment.',
    de: 'Ich rechne deine Saison aus. Einen Moment.',
  );

  static const planReady = LocalizedText(
    nl: 'Je plan staat. Vanaf hier vertel ik je elke week wat er te doen is.',
    en: 'Your plan is ready. From here I tell you what to do each week.',
    de: 'Dein Plan ist fertig. Ab jetzt sage ich dir jede Woche, was zu tun ist.',
  );

  // ── plant insights (features/garden/insights.dart) ────────────────────────
  static LocalizedText insightHarvestPastFrost(String firstFrost) => LocalizedText(
    nl: 'Het oogstvenster loopt door tot na de eerste vorst '
        '($firstFrost). Doorgaan mag voor wat als eerste rijpt: '
        'zet de pot binnen, of kies volgend jaar een snellere variëteit.',
    en: 'The harvest window runs past the first frost '
        '($firstFrost). Grow it anyway for what ripens first, '
        'move the pot inside, or swap for a faster variety next time.',
    de: 'Das Erntefenster reicht über den ersten Frost hinaus '
        '($firstFrost). Für das, was zuerst reif wird, lohnt es sich trotzdem: '
        'Hol den Topf rein, oder nimm nächstes Mal eine schnellere Sorte.',
  );

  static LocalizedText insightFirstFrostSoon(int days, String firstFrost, LocalizedText crop) =>
      LocalizedText(
    nl: 'De eerste vorst wordt over ongeveer $days dagen verwacht '
        '($firstFrost). ${crop.nl} overleeft dat niet. '
        'Pluk wat rijp is en dek af of zet binnen.',
    en: 'First frost is expected in about $days days '
        '($firstFrost). ${crop.en} does not survive it. '
        'Pick what is ripe and cover or move it in.',
    de: 'Der erste Frost wird in etwa $days Tagen erwartet '
        '($firstFrost). ${crop.pick('de')} übersteht ihn nicht. '
        'Ernte, was reif ist, und deck ab oder hol es rein.',
  );

  static LocalizedText insightLastFrostAhead(int days, String lastFrost, LocalizedText crop) =>
      LocalizedText(
    nl: 'De laatste vorst is nog ~$days dagen weg ($lastFrost). '
        'Houd ${crop.nl.toLowerCase()} binnen tot na de ijsheiligen.',
    en: 'Last frost is still ~$days days away ($lastFrost). '
        'Keep ${crop.en.toLowerCase()} inside until after IJsheiligen.',
    // German nouns keep their capital.
    de: 'Der letzte Frost ist noch ~$days Tage entfernt ($lastFrost). '
        'Lass ${crop.pick('de')} bis nach den Eisheiligen drinnen.',
  );

  static LocalizedText insightColdNight(int tempC, String date) => LocalizedText(
    nl: 'Koude nacht op komst: $tempC°C op '
        '$date. Dek af of zet de potten binnen.',
    en: 'Cold night ahead: $tempC°C on '
        '$date. Fleece or bring pots in.',
    de: 'Kalte Nacht im Anmarsch: $tempC °C am '
        '$date. Deck ab oder hol die Töpfe rein.',
  );

  static LocalizedText insightHeat(int tempC, String date, int litres) => LocalizedText(
    nl: '$tempC°C op '
        '$date: een pot van $litres L '
        'droogt in één dag uit. Geef water in de ochtend en zet de pot '
        'in de schaduw als dat kan.',
    en: '$tempC°C on '
        '$date: a $litres L pot dries out '
        'in a day. Water in the morning, shade the pot if you can.',
    de: '$tempC °C am '
        '$date: Ein Topf mit $litres L trocknet an einem Tag aus. Gieß '
        'morgens und stell den Topf in den Schatten, wenn es geht.',
  );

  static LocalizedText insightRain(int mm) => LocalizedText(
    nl: '$mm mm regen in de komende drie dagen. Sla het '
        'water geven over en controleer de gaatjes in de pot.',
    en: '$mm mm of rain in the next three days. Skip '
        'watering and check the drainage holes.',
    de: '$mm mm Regen in den nächsten drei Tagen. Lass das '
        'Gießen aus und prüf die Abzugslöcher.',
  );
}
