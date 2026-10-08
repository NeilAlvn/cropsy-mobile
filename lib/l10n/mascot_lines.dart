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
    fr: 'Ajoute une plante et ta saison se dessine ici toute seule.',
    sv: 'Lägg till en växt så växer din säsong fram här.',
  );

  static const gardenPlanningEmpty = LocalizedText(
    nl: 'Nog niets gepland. Tik "Plan het" bij een gewas en het komt hier te staan.',
    en: 'Nothing planned yet. Tap "Plan it" on a crop and it lands here.',
    de: 'Noch nichts geplant. Tippe bei einer Pflanze auf „Einplanen“, dann landet sie hier.',
    fr: 'Rien de planifié pour l\'instant. Touche « Planifier » sur une plante et elle arrive ici.',
    sv: 'Inget planerat än. Tryck på ”Planera” på en växt så hamnar den här.',
  );

  static const gardenGrowingEmpty = LocalizedText(
    nl: 'Nog niets aan het groeien. Start een geplant gewas, dan begint het pad.',
    en: 'Nothing growing yet. Start a planned crop and the path begins.',
    de: 'Noch nichts im Anbau. Starte eine geplante Pflanze, dann beginnt der Pfad.',
    fr: 'Rien en culture pour l\'instant. Démarre une plante planifiée et le parcours commence.',
    sv: 'Inget växer än. Starta en planerad växt så börjar vägen.',
  );

  static const harvestEmpty = LocalizedText(
    nl: 'Nog niets geoogst. Log je eerste oogst, dan begint de teller te lopen.',
    en: 'Nothing picked yet. Log a harvest and the tally starts.',
    de: 'Noch nichts geerntet. Trag eine Ernte ein, dann beginnt die Bilanz.',
    fr: 'Rien de récolté pour l\'instant. Note une récolte et le bilan démarre.',
    sv: 'Inget skördat än. Logga en skörd så börjar summeringen.',
  );

  static const pathEmpty = LocalizedText(
    nl: 'Nog geen pad. Druk op Start als deze plant de grond in gaat, het pad bouwt zichzelf.',
    en: 'No path yet. Press Start when this plant goes in. The path builds itself.',
    de: 'Noch kein Pfad. Tippe auf Start, wenn die Pflanze in die Erde kommt. Der Pfad baut sich von selbst.',
    fr: 'Pas encore de parcours. Touche Démarrer quand cette plante est mise en terre. Le parcours se construit tout seul.',
    sv: 'Ingen väg än. Tryck på Starta när växten kommer i jorden. Vägen bygger sig själv.',
  );

  // ── the plan moved, nobody is behind (PRD §7.2) ───────────────────────────
  static const notBehindNothingMoved = LocalizedText(
    nl: 'Genoteerd. De rest van het plan hoefde niet te schuiven.',
    en: 'Logged. Nothing else needed to move.',
    de: 'Eingetragen. Sonst musste nichts verschoben werden.',
    fr: 'C\'est noté. Rien d\'autre n\'a eu besoin de bouger.',
    sv: 'Loggat. Inget annat behövde flyttas.',
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
    fr:
        'Rien n\'est perdu. L\'étape « ${step.pick('fr')} » a été faite $days '
        '${days <= 1 ? 'jour' : 'jours'} ${later ? 'plus tard' : 'plus tôt'} que prévu, donc '
        '${moved <= 1 ? '$moved étape suivante se décale' : '$moved étapes suivantes se décalent'} aussi.',
    sv:
        'Du ligger inte efter. Steget ”${step.pick('sv')}” gjordes $days '
        '${days == 1 ? 'dag' : 'dagar'} ${later ? 'senare' : 'tidigare'} än planerat, så '
        '$moved kommande steg flyttas med.',
  );

  static const frostWarning = LocalizedText(
    nl:
        'Let op: de nieuwe oogstdatum valt vlak bij de eerste vorst. Doorgaan '
        'mag, een snellere variëteit is veiliger.',
    en:
        'Careful: the new harvest date lands near the first frost. Growing it '
        'anyway is fine, a faster variety is safer.',
    de: 'Achtung: Das neue Erntedatum liegt nah am ersten Frost. Weitermachen ist okay, eine schnellere Sorte ist sicherer.',
    fr: 'Attention : la nouvelle date de récolte tombe près des premières gelées. Tu peux continuer, une variété plus rapide est plus sûre.',
    sv: 'Se upp: det nya skördedatumet hamnar nära första frosten. Det går bra att odla den ändå, men en snabbare sort är säkrare.',
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
    fr: 'Les saints de glace, du 11 au 15 mai. Une gelée nocturne tardive cette semaine-là est fréquente aux Pays-Bas, alors tomates, courgettes et basilic restent à l\'abri jusqu\'à la fin de cette période.',
    sv: 'Sista frostnätterna, 11 till 15 maj. En sen nattfrost den här veckan är vanlig i Nederländerna, så tomater, zucchini och basilika står skyddat tills den är över.',
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
    fr: 'Les dernières gelées de printemps en moyenne dans ta région. Chaque date de semis de l\'app est comptée à partir d\'elles, et une moyenne n\'est pas une promesse : garde un œil sur les prévisions autour de cette date.',
    sv: 'Den genomsnittliga sista vårfrosten i din region. Varje sådatum i appen räknas från den, och ett snitt är inget löfte: håll koll på prognosen dagarna runt den.',
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
    fr: 'Les premières gelées d\'automne en moyenne dans ta région. Les périodes de récolte sont comptées à rebours à partir d\'elles, donc tout ce qui mûrit encore après cette date joue les prolongations.',
    sv: 'Den genomsnittliga första höstfrosten i din region. Skördefönstren räknas bakåt från den, så allt som fortfarande mognar efter det datumet lever på lånad tid.',
  );

  static const recap = LocalizedText(
    nl:
        'Eind december telt het seizoen op: wat je hebt geteeld, wat je hebt '
        'geoogst en wat het je heeft bespaard.',
    en:
        'At the end of December the season adds up: what you grew, what you '
        'picked, and what it saved you.',
    de: 'Ende Dezember zieht die Saison Bilanz: was du angebaut und geerntet hast und was es dir gespart hat.',
    fr: 'Fin décembre, la saison fait le bilan : ce que tu as cultivé, ce que tu as récolté et ce que ça t\'a fait économiser.',
    sv: 'I slutet av december räknas säsongen ihop: vad du odlade, vad du skördade och vad det sparade åt dig.',
  );

  static const seedOrder = LocalizedText(
    nl:
        'Januari is zaadmaand. Bestel nu, dan ligt alles klaar als de grond '
        'opwarmt.',
    en:
        'January is seed month. Order now and everything is ready when the '
        'soil warms up.',
    de: 'Januar ist Saatgut-Monat. Bestell jetzt, dann liegt alles bereit, wenn der Boden warm wird.',
    fr: 'Janvier, c\'est le mois des graines. Commande maintenant et tout sera prêt quand le sol se réchauffera.',
    sv: 'Januari är frömånad. Beställ nu så är allt klart när jorden blir varm.',
  );

  // ── the weather moved something (F4) ──────────────────────────────────────
  static const rainSkipped = LocalizedText(
    nl:
        'De regen heeft het water geven overgenomen. Overgeslagen voor je, je '
        'reeks telt gewoon door.',
    en: 'Rain did the watering. Skipped for you, and your streak still counts.',
    de: 'Der Regen hat gegossen. Für dich übersprungen, und deine Serie zählt trotzdem.',
    fr: 'La pluie a arrosé. Sauté pour toi, et ta série compte quand même.',
    sv: 'Regnet vattnade åt dig. Överhoppat, och din svit räknas ändå.',
  );

  static const heatAhead = LocalizedText(
    nl:
        'Hitte op komst. Potten drogen binnen een dag uit, dus water geven '
        'schuift naar voren.',
    en:
        'Heat on the way. Containers dry out in a day, so watering moves '
        'earlier.',
    de: 'Hitze im Anmarsch. Töpfe trocknen an einem Tag aus, darum rückt das Gießen nach vorne.',
    fr: 'Chaleur en vue. Les pots sèchent en une journée, alors l\'arrosage avance.',
    sv: 'Värme på väg. Krukor torkar ut på en dag, så vattningen flyttas tidigare.',
  );

  static const soilCold = LocalizedText(
    nl:
        'De grond is nog te koud. Zaaien wacht tot het warmer wordt, dat '
        'scheelt je een mislukte zaaibeurt.',
    en:
        'The soil is still too cold. Sowing waits until it warms up, which '
        'saves you a failed sowing.',
    de: 'Der Boden ist noch zu kalt. Gesät wird, sobald er wärmer ist, das erspart dir eine misslungene Aussaat.',
    fr: 'Le sol est encore trop froid. Le semis attend qu\'il se réchauffe, ça t\'évite un semis raté.',
    sv: 'Jorden är fortfarande för kall. Sådden väntar tills det blir varmare, så slipper du en misslyckad sådd.',
  );

  // ── the streak, which is never a stick (PRD §7.5) ─────────────────────────
  static const streakStart = LocalizedText(
    nl: 'Vink één taak af, of sla er één over met een reden. Regen telt mee.',
    en: 'Tick one task, or skip one with a reason. Rain counts.',
    de: 'Hak eine Aufgabe ab oder überspring eine mit Grund. Regen zählt.',
    fr: 'Coche une tâche, ou passes-en une avec une raison. La pluie compte.',
    sv: 'Bocka av en uppgift, eller hoppa över en med ett skäl. Regn räknas.',
  );

  static LocalizedText streakGoing(int days) => LocalizedText(
    nl: '$days ${days == 1 ? 'dag' : 'dagen'} op rij. Mooi bezig.',
    en: '$days ${days == 1 ? 'day' : 'days'} in a row. Nicely done.',
    de: '$days ${days == 1 ? 'Tag' : 'Tage'} in Folge. Gut gemacht.',
    fr: '$days ${days <= 1 ? 'jour' : 'jours'} d\'affilée. Bien joué.',
    sv: '$days ${days == 1 ? 'dag' : 'dagar'} i rad. Snyggt jobbat.',
  );

  static const streakBrokenBySeason = LocalizedText(
    nl:
        'In de winter valt er weinig te doen, dus je reeks pauzeert gewoon. '
        'Hij pakt door zodra het seizoen dat ook doet.',
    en:
        'There is little to do in winter, so your streak simply pauses. It '
        'picks up when the season does.',
    de: 'Im Winter gibt es wenig zu tun, darum pausiert deine Serie einfach. Sie geht weiter, wenn die Saison weitergeht.',
    fr: 'Il y a peu à faire en hiver, alors ta série fait simplement une pause. Elle reprend avec la saison.',
    sv: 'Det finns lite att göra på vintern, så din svit pausar bara. Den fortsätter när säsongen gör det.',
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
    fr: 'Ça ne ressemble pas à une plante. On connaît les fruits et légumes, essaie avec une feuille ou un fruit.',
    sv: 'Det där ser inte ut som en växt. Vi kan frukt och grönt, så prova ett blad eller en frukt.',
  );

  static const scanNoMatch = LocalizedText(
    nl:
        'Geen match. Probeer een scherpere foto van een blad of bloem, of zoek '
        'op naam.',
    en: 'No match. Try a closer shot of a leaf or flower, or search by name.',
    de: 'Kein Treffer. Versuch eine nähere Aufnahme von einem Blatt oder einer Blüte, oder such nach dem Namen.',
    fr: 'Pas de correspondance. Essaie une photo plus proche d\'une feuille ou d\'une fleur, ou cherche par nom.',
    sv: 'Ingen träff. Prova en närmare bild av ett blad eller en blomma, eller sök på namn.',
  );

  static const scanHealthy = LocalizedText(
    nl: 'Ziet er gezond uit van hieraf.',
    en: 'Looks healthy from here.',
    de: 'Sieht von hier gesund aus.',
    fr: 'Elle a l\'air en bonne santé d\'ici.',
    sv: 'Ser frisk ut härifrån.',
  );

  static const scanNothingRecognisable = LocalizedText(
    nl:
        'Niets herkenbaars. Blader hieronder door de veelvoorkomende '
        'problemen.',
    en: 'Nothing recognisable. Browse the common problems below instead.',
    de: 'Nichts erkennbar. Schau stattdessen unten bei den häufigen Problemen.',
    fr: 'Rien de reconnaissable. Regarde plutôt les problèmes courants ci-dessous.',
    sv: 'Inget som går att känna igen. Bläddra bland de vanliga problemen nedan i stället.',
  );

  static const scanBestGuesses = LocalizedText(
    nl:
        'Beste gokken, meest waarschijnlijke eerst. Niet deze plant? Kies een '
        'andere of zoek op naam.',
    en:
        'Best guesses, most likely first. Not this plant? Pick another or '
        'search by name.',
    de: 'Beste Vermutungen, die wahrscheinlichste zuerst. Nicht diese Pflanze? Wähl eine andere oder such nach dem Namen.',
    fr: 'Meilleures hypothèses, la plus probable d\'abord. Pas cette plante ? Choisis-en une autre ou cherche par nom.',
    sv: 'Bästa gissningar, den mest sannolika först. Inte den här växten? Välj en annan eller sök på namn.',
  );

  static const scanIsAGuess = LocalizedText(
    nl: 'Dit is een gok op basis van de foto, geen diagnose.',
    en: 'This is a guess from the photo, not a diagnosis.',
    de: 'Das ist eine Vermutung anhand des Fotos, keine Diagnose.',
    fr: 'C\'est une hypothèse d\'après la photo, pas un diagnostic.',
    sv: 'Det här är en gissning utifrån fotot, inte en diagnos.',
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
    fr: 'Les 25 problèmes les plus courants sur les balcons néerlandais, limaces, pucerons, oïdium, nécrose apicale, sont en cours d\'écriture et de vérification. Ils arrivent avec la mise à jour du contenu.',
    sv: 'De 25 vanligaste problemen på nederländska balkonger – sniglar, bladlöss, mjöldagg, pistillröta – skrivs och kontrolleras just nu. De kommer med innehållsuppdateringen.',
  );

  static const seasonLaysItselfOut = LocalizedText(
    nl: 'Zet een plant neer en het seizoen legt zichzelf hier uit.',
    en: 'Add a plant and the season lays itself out here.',
    de: 'Füg eine Pflanze hinzu, und die Saison legt sich hier von selbst aus.',
    fr: 'Ajoute une plante et la saison se dessine ici toute seule.',
    sv: 'Lägg till en växt så växer säsongen fram här.',
  );

  static const scanSignIn = LocalizedText(
    nl: 'Log eerst in bij Instellingen. Scans tellen per account.',
    en: 'Sign in first, under Settings. Scans are counted per account.',
    de: 'Melde dich zuerst unter Einstellungen an. Scans werden pro Konto gezählt.',
    fr: 'Connecte-toi d\'abord, dans les Réglages. Les scans sont comptés par compte.',
    sv: 'Logga in först, under Inställningar. Skanningar räknas per konto.',
  );

  // ── onboarding ────────────────────────────────────────────────────────────
  static const welcome = LocalizedText(
    nl: 'Hoi! Even kennismaken.',
    en: "Hi! Let's get to know each other.",
    de: 'Hallo! Lernen wir uns kennen.',
    fr: 'Salut ! Faisons connaissance.',
    sv: 'Hej! Nu lär vi känna varandra.',
  );

  static const buildingPlan = LocalizedText(
    nl: 'Ik reken je seizoen door. Even geduld.',
    en: 'Working out your season. One moment.',
    de: 'Ich rechne deine Saison aus. Einen Moment.',
    fr: 'Je calcule ta saison. Un instant.',
    sv: 'Räknar ut din säsong. Ett ögonblick.',
  );

  static const planReady = LocalizedText(
    nl: 'Je plan staat. Vanaf hier vertel ik je elke week wat er te doen is.',
    en: 'Your plan is ready. From here I tell you what to do each week.',
    de: 'Dein Plan ist fertig. Ab jetzt sage ich dir jede Woche, was zu tun ist.',
    fr: 'Ton plan est prêt. À partir de maintenant, je te dis quoi faire chaque semaine.',
    sv: 'Din plan är klar. Härifrån berättar jag vad du ska göra varje vecka.',
  );

  // ── plant insights (features/garden/insights.dart) ────────────────────────
  static LocalizedText insightHarvestPastFrost(
    String firstFrost,
  ) => LocalizedText(
    nl:
        'Het oogstvenster loopt door tot na de eerste vorst '
        '($firstFrost). Doorgaan mag voor wat als eerste rijpt: '
        'zet de pot binnen, of kies volgend jaar een snellere variëteit.',
    en:
        'The harvest window runs past the first frost '
        '($firstFrost). Grow it anyway for what ripens first, '
        'move the pot inside, or swap for a faster variety next time.',
    de:
        'Das Erntefenster reicht über den ersten Frost hinaus '
        '($firstFrost). Für das, was zuerst reif wird, lohnt es sich trotzdem: '
        'Hol den Topf rein, oder nimm nächstes Mal eine schnellere Sorte.',
    fr:
        'La période de récolte dépasse les premières gelées '
        '($firstFrost). Continue pour ce qui mûrit en premier, '
        'rentre le pot, ou choisis une variété plus rapide la prochaine fois.',
    sv:
        'Skördefönstret sträcker sig förbi första frosten ($firstFrost). '
        'Odla den ändå för det som mognar först, flytta in krukan eller byt '
        'till en snabbare sort nästa gång.',
  );

  static LocalizedText insightFirstFrostSoon(
    int days,
    String firstFrost,
    LocalizedText crop,
  ) => LocalizedText(
    nl:
        'De eerste vorst wordt over ongeveer $days dagen verwacht '
        '($firstFrost). ${crop.nl} overleeft dat niet. '
        'Pluk wat rijp is en dek af of zet binnen.',
    en:
        'First frost is expected in about $days days '
        '($firstFrost). ${crop.en} does not survive it. '
        'Pick what is ripe and cover or move it in.',
    de:
        'Der erste Frost wird in etwa $days Tagen erwartet '
        '($firstFrost). ${crop.pick('de')} übersteht ihn nicht. '
        'Ernte, was reif ist, und deck ab oder hol es rein.',
    fr:
        'Les premières gelées sont attendues dans environ $days '
        '${days <= 1 ? 'jour' : 'jours'} ($firstFrost). Cette plante n\'y résiste pas. '
        'Récolte ce qui est mûr, puis couvre-la ou rentre-la.',
    sv:
        'Första frosten väntas om ungefär $days ${days == 1 ? 'dag' : 'dagar'} '
        '($firstFrost). ${crop.pick('sv')} tål inte frost. Skörda det som är '
        'moget och täck över eller flytta in växten.',
  );

  static LocalizedText insightLastFrostAhead(
    int days,
    String lastFrost,
    LocalizedText crop,
  ) => LocalizedText(
    nl:
        'De laatste vorst is nog ~$days dagen weg ($lastFrost). '
        'Houd ${crop.nl.toLowerCase()} binnen tot na de ijsheiligen.',
    en:
        'Last frost is still ~$days days away ($lastFrost). '
        'Keep ${crop.en.toLowerCase()} inside until after IJsheiligen.',
    // German nouns keep their capital.
    de:
        'Der letzte Frost ist noch ~$days Tage entfernt ($lastFrost). '
        'Lass ${crop.pick('de')} bis nach den Eisheiligen drinnen.',
    fr:
        'Les dernières gelées sont encore à ~$days ${days <= 1 ? 'jour' : 'jours'} ($lastFrost). '
        '${crop.pick('fr')} : à garder à l\'intérieur jusqu\'après les saints de glace.',
    sv:
        'Sista frosten är fortfarande ~$days ${days == 1 ? 'dag' : 'dagar'} bort '
        '($lastFrost). Håll ${crop.pick('sv').toLowerCase()} inne tills sista frosten är över.',
  );

  static LocalizedText insightColdNight(
    int tempC,
    String date,
  ) => LocalizedText(
    nl:
        'Koude nacht op komst: $tempC°C op '
        '$date. Dek af of zet de potten binnen.',
    en:
        'Cold night ahead: $tempC°C on '
        '$date. Fleece or bring pots in.',
    de:
        'Kalte Nacht im Anmarsch: $tempC °C am '
        '$date. Deck ab oder hol die Töpfe rein.',
    fr:
        'Nuit froide en vue : $tempC °C le '
        '$date. Couvre d\'un voile ou rentre les pots.',
    sv:
        'Kall natt på väg: $tempC °C den $date. Täck med fiberduk eller ta in '
        'krukorna.',
  );

  static LocalizedText insightHeat(
    int tempC,
    String date,
    int litres,
  ) => LocalizedText(
    nl:
        '$tempC°C op '
        '$date: een pot van $litres L '
        'droogt in één dag uit. Geef water in de ochtend en zet de pot '
        'in de schaduw als dat kan.',
    en:
        '$tempC°C on '
        '$date: a $litres L pot dries out '
        'in a day. Water in the morning, shade the pot if you can.',
    de:
        '$tempC °C am '
        '$date: Ein Topf mit $litres L trocknet an einem Tag aus. Gieß '
        'morgens und stell den Topf in den Schatten, wenn es geht.',
    fr:
        '$tempC °C le '
        '$date : un pot de $litres L sèche en une journée. Arrose le '
        'matin, et mets le pot à l\'ombre si tu peux.',
    sv:
        '$tempC °C den $date: en kruka på $litres L torkar ut på en dag. Vattna '
        'på morgonen och ställ krukan i skugga om du kan.',
  );

  static LocalizedText insightRain(int mm) => LocalizedText(
    nl:
        '$mm mm regen in de komende drie dagen. Sla het '
        'water geven over en controleer de gaatjes in de pot.',
    en:
        '$mm mm of rain in the next three days. Skip '
        'watering and check the drainage holes.',
    de:
        '$mm mm Regen in den nächsten drei Tagen. Lass das '
        'Gießen aus und prüf die Abzugslöcher.',
    fr:
        '$mm mm de pluie dans les trois prochains jours. Pas besoin '
        'd\'arroser ; vérifie juste les trous de drainage.',
    sv:
        '$mm mm regn de närmaste tre dagarna. Hoppa över vattningen och kolla '
        'dräneringshålen.',
  );
}
