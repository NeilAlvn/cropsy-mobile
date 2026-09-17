/// The interface's own words, in both languages.
///
/// Content (crops, problems, guides) already carries its two sides in the data;
/// this is for the chrome around it. Same shape as the mascot deck: a constant
/// per string, Dutch first, resolved with `.of(context)`.
///
/// Not every screen is here yet. A string moves in when its screen does, so the
/// file grows as the interface is translated rather than all at once.
library;

import '../timing/types.dart';

abstract final class Str {
  // ── tabs, read by the screen reader (base 8.8) ────────────────────────────
  static const tabHome = LocalizedText(nl: 'Home', en: 'Home');
  static const tabGarden = LocalizedText(nl: 'Mijn tuin', en: 'My garden');
  static const tabSeason = LocalizedText(nl: 'Seizoenspad', en: 'Season path');
  static const tabExplore = LocalizedText(nl: 'Ontdek', en: 'Explore');
  static const tabDiagnose = LocalizedText(nl: 'Diagnose', en: 'Diagnose');

  // ── home ──────────────────────────────────────────────────────────────────
  static const greeting = LocalizedText(nl: 'Hoi', en: 'Hey there');
  static LocalizedText greetingNamed(String name) =>
      LocalizedText(nl: 'Hoi, $name', en: 'Hey, $name');
  static const greetingSub = LocalizedText(
    nl: 'Dit staat er deze week in je tuin.',
    en: 'Here is your garden this week.',
  );
  static const searchCrops = LocalizedText(
    nl: 'Zoek groenten',
    en: 'Search vegetables',
  );
  static LocalizedText todaysCare(int open) =>
      LocalizedText(nl: 'Vandaag te doen ($open)', en: "Today's care ($open)");
  static LocalizedText upcomingHarvest(int n) =>
      LocalizedText(nl: 'Binnenkort oogsten ($n)', en: 'Upcoming harvest ($n)');
  static LocalizedText whatToGrow(LocalizedText month) => LocalizedText(
        nl: 'Wat te zaaien in ${month.nl}',
        en: 'What to grow in ${month.en}',
      );
  static LocalizedText checklistFor(LocalizedText month) => LocalizedText(
        nl: 'Checklist voor ${month.nl}',
        en: 'Checklist for ${month.en}',
      );
  static const unlockLifetime = LocalizedText(
    nl: 'Lifetime, één prijs, voorgoed',
    en: 'Unlock lifetime, one price, forever',
  );
  static const startStreak = LocalizedText(
    nl: 'Begin vandaag een reeks',
    en: 'Start a streak today',
  );
  static LocalizedText streakDays(int days) => LocalizedText(
        nl: '$days ${days == 1 ? 'dag' : 'dagen'} op rij',
        en: '$days-day streak',
      );

  // ── the season path ───────────────────────────────────────────────────────
  static const season = LocalizedText(nl: 'Seizoen', en: 'Season');
  static LocalizedText yearInGarden(int year) =>
      LocalizedText(nl: '$year in jouw tuin', en: '$year in your garden');
  static const today = LocalizedText(nl: 'Vandaag', en: 'Today');
  static const tomorrow = LocalizedText(nl: 'Morgen', en: 'Tomorrow');
  static LocalizedText stepPlannedOn(LocalizedText step, String day) =>
      LocalizedText(
        nl: '${step.nl} · gepland $day',
        en: '${step.en} · planned $day',
      );
  static const nothingToDoToday = LocalizedText(
    nl: 'Niets te doen vandaag. Geniet ervan.',
    en: 'Nothing to do today. Enjoy it.',
  );
  static LocalizedText thingsToDoToday(int n) => LocalizedText(
        nl: n == 1 ? 'Eén ding te doen vandaag.' : '$n dingen te doen vandaag.',
        en: n == 1 ? '1 thing to do today.' : '$n things to do today.',
      );
  static LocalizedText removeKeepsYourHarvests(String name) => LocalizedText(
        nl: 'Dit haalt $name uit je tuin. Oogsten die je al logde blijven in '
            'je seizoensgeschiedenis staan.',
        en: 'This takes $name out of your garden. Any harvests you already '
            'logged stay in your season history.',
      );
  static const symptoms = LocalizedText(nl: 'Symptomen', en: 'Symptoms');
  static const pickSomething =
      LocalizedText(nl: 'Kies iets ', en: 'Pick something ');
  static const toGrow = LocalizedText(nl: 'om te telen', en: 'to grow');
  static const minSoilTemp =
      LocalizedText(nl: 'Min. bodemtemperatuur', en: 'Min soil temp');
  static const minPotSize = LocalizedText(nl: 'Min. potmaat', en: 'Min pot size');
  static const containerFriendly =
      LocalizedText(nl: 'Geschikt voor potten', en: 'Container-friendly');
  static const yes = LocalizedText(nl: 'Ja', en: 'Yes');
  static const balconySuitability = LocalizedText(
    nl: 'Geschikt voor NL-balkon',
    en: 'NL balcony suitability',
  );
  static const balconyGreat = LocalizedText(nl: 'Prima', en: 'Great');
  static const balconyAfterIjsheiligen = LocalizedText(
    nl: 'Goed na de ijsheiligen',
    en: 'Good after IJsheiligen',
  );
  static const balconyNeedsBed =
      LocalizedText(nl: 'Heeft een bed nodig', en: 'Needs a bed');
  static const moveBackToPlanning = LocalizedText(
    nl: 'Terug naar gepland',
    en: 'Move back to planning',
  );
  static const removeFromGarden = LocalizedText(
    nl: 'Uit de tuin halen',
    en: 'Remove from garden',
  );
  static LocalizedText removeKeepsHarvests(String name) => LocalizedText(
        nl: 'Dit haalt $name uit je tuin. Gelogde oogsten blijven in je '
            'seizoensgeschiedenis staan.',
        en: 'This takes $name out of your garden. Logged harvests stay in your '
            'season history.',
      );
  static const tapPlanToGrow = LocalizedText(
    nl: 'Tik op "Wil ik telen" bij een gewas om het hier te zetten.',
    en: 'Tap "Plan to grow" on any crop to add it here.',
  );
  static const tapGrowingIt = LocalizedText(
    nl: 'Tik op "Staat er al" bij een gewas, of start een gepland gewas.',
    en: 'Tap "Growing it" on a crop, or start a planned one.',
  );
  static const sowIndoors = LocalizedText(nl: 'Binnen zaaien', en: 'Sow indoors');
  static const plantOut = LocalizedText(nl: 'Uitplanten', en: 'Plant out');
  static const sowOutdoors = LocalizedText(nl: 'Buiten zaaien', en: 'Sow outdoors');
  static const treatmentOrganicFirst = LocalizedText(
    nl: 'Aanpak (biologisch eerst)',
    en: 'Treatment (organic first)',
  );
  static const prevention = LocalizedText(nl: 'Voorkomen', en: 'Prevention');
  static const lastFrostRow = LocalizedText(nl: 'Laatste vorst', en: 'Last frost');
  static const firstFrostRow = LocalizedText(nl: 'Eerste vorst', en: 'First frost');
  static const preferredSun = LocalizedText(nl: 'Voorkeur zon', en: 'Preferred sun');
  static const frostTender = LocalizedText(nl: 'Vorstgevoelig', en: 'Frost tender');
  static const yesWaitForLastFrost = LocalizedText(
    nl: 'Ja, wacht op de laatste vorst',
    en: 'Yes, wait for last frost',
  );
  static const no = LocalizedText(nl: 'Nee', en: 'No');

  static const empty = LocalizedText(nl: '', en: '');
  static const sow = LocalizedText(nl: 'Zaaien', en: 'Sow');
  static const startIndoors =
      LocalizedText(nl: 'Binnen starten', en: 'Start indoors');
  static const plantOutside =
      LocalizedText(nl: 'Buiten planten', en: 'Plant outside');
  static const easyFilter = LocalizedText(nl: 'Makkelijk', en: 'Easy');
  static const whatIsWrongHere =
      LocalizedText(nl: 'Wat klopt hier niet?', en: 'What is wrong here?');
  static const whatWouldBeBetter = LocalizedText(
    nl: 'Wat zou dit beter maken?',
    en: 'What would make this better?',
  );
  static const climateNormals = LocalizedText(
    nl: 'KNMI/Open-Meteo klimaatnormalen',
    en: 'KNMI/Open-Meteo climate normals',
  );
  static const regionalPreset = LocalizedText(
    nl: 'NL regiovoorinstelling',
    en: 'NL regional preset',
  );
  /// The crop data's own sun values, said in words.
  static LocalizedText sunNeed(String value) => switch (value) {
        'full' => const LocalizedText(nl: 'volle zon', en: 'full sun'),
        'partial' => const LocalizedText(nl: 'halfschaduw', en: 'partial'),
        'shade-tolerant' =>
          const LocalizedText(nl: 'verdraagt schaduw', en: 'shade-tolerant'),
        _ => LocalizedText(nl: value, en: value),
      };
  static LocalizedText daysToHarvest(num min, num max) => LocalizedText(
        nl: '$min-$max dagen',
        en: '$min-$max days',
      );
  static const stageSprout = LocalizedText(nl: 'Kiem', en: 'Sprout');
  static const dayOne = LocalizedText(nl: 'Dag 1', en: 'Day 1');
  static LocalizedText dayRange(num from, num to) =>
      LocalizedText(nl: 'Dag $from-$to', en: 'Day $from-$to');
  static const enoughRainBadge =
      LocalizedText(nl: 'Genoeg regen', en: 'Enough rain');
  static const heatComingBadge =
      LocalizedText(nl: 'Hitte op komst', en: 'Heat coming');
  static const soilTooColdBadge =
      LocalizedText(nl: 'Grond te koud', en: 'Soil too cold');
  static const gardenKindBalcony = LocalizedText(nl: 'Balkon', en: 'Balcony');
  static const gardenKindGarden = LocalizedText(nl: 'Tuin', en: 'Garden');
  static const gardenKindAllotment =
      LocalizedText(nl: 'Volkstuin', en: 'Allotment');
  static const contactUs = LocalizedText(nl: 'Contact', en: 'Contact us');
  static const privacy = LocalizedText(nl: 'Privacy', en: 'Privacy');
  static const terms = LocalizedText(nl: 'Voorwaarden', en: 'Terms');
  static const yourHarvests =
      LocalizedText(nl: 'Jouw oogsten', en: 'Your harvests');
  static const placeGround =
      LocalizedText(nl: 'In de volle grond', en: 'In the ground');
  static const placeRaisedBed =
      LocalizedText(nl: 'Verhoogde bak', en: 'Raised bed');
  static const placePotOutside =
      LocalizedText(nl: 'Pot buiten', en: 'Pot outside');
  static const placePotInside =
      LocalizedText(nl: 'Pot binnen', en: 'Pot inside');
  static const methodSowedIndoors =
      LocalizedText(nl: 'Binnen gezaaid', en: 'Sowed indoors');
  static const methodSowedOutside =
      LocalizedText(nl: 'Buiten gezaaid', en: 'Sowed outside');
  static const methodPlantedSeedling =
      LocalizedText(nl: 'Zaailing geplant', en: 'Planted a seedling');
  static const methodPlantedSets = LocalizedText(
    nl: 'Geplant (bollen / knollen)',
    en: 'Planted (sets / tubers)',
  );
  // ── the how-tos table ─────────────────────────────────────────────────────
  static const sowDepth = LocalizedText(nl: 'Zaaidiepte', en: 'Sow depth');
  static const germination = LocalizedText(nl: 'Kieming', en: 'Germination');
  static const plantOutAfter =
      LocalizedText(nl: 'Uitplanten na', en: 'Plant out after');
  static const spacing = LocalizedText(nl: 'Plantafstand', en: 'Spacing');
  static const perSquare =
      LocalizedText(nl: 'Per vak van 30 cm', en: 'Per 30 cm square');
  static const care = LocalizedText(nl: 'Verzorging', en: 'Care');
  static const waterSmallPot =
      LocalizedText(nl: 'Water (kleine pot)', en: 'Water (small pot)');
  static const waterInGround =
      LocalizedText(nl: 'Water (volle grond)', en: 'Water (in ground)');
  static const feed = LocalizedText(nl: 'Bijmesten', en: 'Feed');
  static const perennial = LocalizedText(nl: 'Meerjarig', en: 'Perennial');
  static const firstHarvest =
      LocalizedText(nl: 'Eerste oogst', en: 'First harvest');
  static LocalizedText aboutDays(int n) =>
      LocalizedText(nl: '~$n dagen', en: '~$n days');
  static LocalizedText daysIndoors(int n) => LocalizedText(
        nl: '~$n dagen binnen',
        en: '~$n days indoors',
      );
  static LocalizedText everyDays(int n) => LocalizedText(
        nl: n == 1 ? 'elke dag' : 'elke $n dagen',
        en: n == 1 ? 'every 1 day' : 'every $n days',
      );
  static LocalizedText everyDaysEstablished(int n) => LocalizedText(
        nl: 'elke $n dagen zodra hij aanslaat',
        en: 'every $n days once established',
      );
  static const comesBackNextYear = LocalizedText(
    nl: 'komt volgend jaar terug',
    en: 'comes back next year',
  );
  static LocalizedText daysAfterPlantOut(num min, num max) => LocalizedText(
        nl: '$min-$max dagen na het uitplanten',
        en: '$min-$max days after planting out',
      );

  // ── onboarding chrome ─────────────────────────────────────────────────────
  static const heroKnowWhatToDo =
      LocalizedText(nl: 'Weet wat je\n', en: 'Know what to do\n');
  static const heroThisWeek = LocalizedText(nl: 'deze week', en: 'this week');
  static const heroInYourGarden =
      LocalizedText(nl: ' moet doen in je tuin.', en: ' in your garden.');
  static const heroSubtitle = LocalizedText(
    nl: 'Plantdata en herinneringen afgestemd op het Nederlandse en Europese '
        'weer, gemaakt voor balkons en potten.',
    en: 'Planting dates and reminders tuned to Dutch and EU weather, built for '
        'balconies and containers.',
  );
  static const getStarted = LocalizedText(nl: 'Beginnen', en: 'Get started');
  static const continueLabel = LocalizedText(nl: 'Verder', en: 'Continue');
  static const datesCheckedTitle = LocalizedText(
    nl: 'Elke datum gelegd naast Nederlandse zaaikalenders',
    en: 'Every date checked against Dutch seed calendars',
  );
  static const datesCheckedBody = LocalizedText(
    nl: 'Elk gewas is gelegd naast minstens twee NL-bronnen, IVN, Tuinadvies, '
        'zaaitijden.nl en Groei & Bloei, voordat het bij jou komt. En als het '
        'leven ertussen komt, schuift het plan met je mee. Niets is ooit "te '
        'laat".',
    en: 'Each crop is cross-checked against at least two NL sources, IVN, '
        'Tuinadvies, zaaitijden.nl and Groei & Bloei, before it reaches you. '
        'And when life gets in the way, the plan moves with you. Nothing is '
        'ever "overdue".',
  );
  static const getToKnowTitle = LocalizedText(
    nl: 'Hoi! Even kennismaken',
    en: "Hi! Let's get to know each other",
  );
  static const getToKnowBody = LocalizedText(
    nl: 'Een paar korte vragen over je ruimte en wat je graag eet. Twee '
        'minuten, dan staat je plan klaar.',
    en: 'A few quick questions about your space and what you like to eat. Two '
        'minutes, then your plan is ready.',
  );
  static const pickAllThatApply =
      LocalizedText(nl: 'Kies alles wat past.', en: 'Pick all that apply.');
  static const spaceBackyard = LocalizedText(nl: 'Tuin', en: 'Garden');
  static const spaceBalcony = LocalizedText(nl: 'Balkon', en: 'Balcony');
  static const spaceIndoor = LocalizedText(nl: 'Binnen', en: 'Indoors');
  static const spaceAllotment =
      LocalizedText(nl: 'Volkstuin', en: 'Allotment');
  static const spaceOther =
      LocalizedText(nl: 'Ergens anders', en: 'Somewhere else');
  static const howDoYouGrow =
      LocalizedText(nl: 'Hoe teel je?', en: 'How do you grow?');
  static const methodGround =
      LocalizedText(nl: 'In de volle grond', en: 'In the ground');
  static const methodRaisedBeds =
      LocalizedText(nl: 'Verhoogde bakken', en: 'Raised beds');
  static const methodPotsInside =
      LocalizedText(nl: 'Potten binnen', en: 'Pots inside');
  static const methodPotsOutside =
      LocalizedText(nl: 'Potten buiten', en: 'Pots outside');
  static const howMuchSpace =
      LocalizedText(nl: 'Hoeveel ruimte?', en: 'How much space?');
  static const howMuchSpaceSub = LocalizedText(
    nl: 'Ongeveer, het bepaalt hoeveel planten passen.',
    en: 'Roughly, it sets how many plants fit.',
  );
  static const howMuchSun =
      LocalizedText(nl: 'Hoeveel zon?', en: 'How much sun?');
  static const howMuchSunSub = LocalizedText(
    nl: 'Op een heldere dag, hoe lang staat het in de volle zon?',
    en: 'On a clear day, how long is it in direct sun?',
  );
  static const sunFull =
      LocalizedText(nl: 'Volle zon (6u+)', en: 'Full sun (6h+)');
  static const sunPartial =
      LocalizedText(nl: 'Halfschaduw (3-6u)', en: 'Partial (3-6h)');
  static const sunShade =
      LocalizedText(nl: 'Schaduw (< 3u)', en: 'Shade (< 3h)');
  static const grownBefore = LocalizedText(
    nl: 'Eerder iets geteeld?',
    en: 'Grown anything before?',
  );
  static const grownBeforeSub = LocalizedText(
    nl: 'Zo stemmen we het advies af.',
    en: 'So we pitch the advice right.',
  );
  static const experienceNever = LocalizedText(nl: 'Nooit', en: 'Never');
  static const experienceSome =
      LocalizedText(nl: 'Een seizoen of twee', en: 'A season or two');
  static const experiencePlenty = LocalizedText(nl: 'Genoeg', en: 'Plenty');
  static const whatDoYouEat = LocalizedText(
    nl: 'Wat eet je graag?',
    en: 'What do you like to eat?',
  );
  static const foodVegetables = LocalizedText(nl: 'Groente', en: 'Vegetables');
  static const foodHerbs = LocalizedText(nl: 'Kruiden', en: 'Herbs');
  static const foodSalad = LocalizedText(nl: 'Slablad', en: 'Salad leaves');
  static const foodFruit = LocalizedText(nl: 'Fruit', en: 'Fruit');
  static const foodRoots = LocalizedText(nl: 'Wortelgroente', en: 'Root veg');
  static const whatMattersMost = LocalizedText(
    nl: 'Wat is het belangrijkst?',
    en: "What's most important?",
  );
  static const interestEasy =
      LocalizedText(nl: 'Makkelijk te telen', en: 'Easy to grow');
  static const interestFast =
      LocalizedText(nl: 'Snel oogsten', en: 'Fast harvest');
  static const interestYield =
      LocalizedText(nl: 'Veel opbrengst', en: 'High yield');
  static const interestKids =
      LocalizedText(nl: 'Leuk met kinderen', en: 'Fun with kids');
  static const interestCost =
      LocalizedText(nl: 'Scheelt geld', en: 'Saves money');
  static const companionsAsk = LocalizedText(
    nl: 'Interesse in buurplanten?',
    en: 'Interested in companion planting?',
  );
  static const companionsAskSub = LocalizedText(
    nl: 'We waarschuwen als twee planten elkaar niet liggen.',
    en: 'We can warn when two plants dislike each other.',
  );
  static const companionsYes =
      LocalizedText(nl: 'Ja, laat maar zien', en: 'Yes, show me');
  static const companionsNo = LocalizedText(nl: 'Nu niet', en: 'Not now');
  static const statementBehind = LocalizedText(
    nl: 'Ik loop vaak achter op klusjes in de tuin.',
    en: 'I often feel behind on garden jobs.',
  );
  static const statementForget = LocalizedText(
    nl: 'Ik vergeet water te geven tot er iets slap hangt.',
    en: 'I forget to water until something wilts.',
  );
  static const statementDates = LocalizedText(
    nl: 'Ik weet nooit wanneer het veilig is om uit te planten.',
    en: "I never know when it's safe to plant out.",
  );
  static const statementWaste = LocalizedText(
    nl: 'Ik koop zaad dat ik nooit zaai.',
    en: 'I buy seeds I never get round to sowing.',
  );
  static const buildMyPlan =
      LocalizedText(nl: 'Bouw mijn plan', en: 'Build my plan');
  static const yourLocationWord =
      LocalizedText(nl: 'jouw locatie', en: 'your location');
  static const planReady =
      LocalizedText(nl: 'Je plan staat klaar', en: 'Your plan is ready');
  static const planBuilding = LocalizedText(
    nl: 'Je teeltplan wordt gemaakt…',
    en: 'Creating your growing plan…',
  );
  static LocalizedText planFrostLine(String region, String last, String first) =>
      LocalizedText(
        nl: 'Vorstdatums voor $region: laatste $last, eerste $first',
        en: 'Frost dates for $region: last $last, first $first',
      );
  static LocalizedText planMatches(int n) => LocalizedText(
        nl: n == 1
            ? '1 gewas past deze maand in je ruimte'
            : '$n gewassen passen deze maand in je ruimte',
        en: n == 1
            ? '1 crop fits your space this month'
            : '$n crops fit your space this month',
      );
  static const planMatching = LocalizedText(
    nl: 'Gewassen zoeken die in je ruimte passen…',
    en: 'Matching crops to your space…',
  );
  static const planFirstTaskWaits = LocalizedText(
    nl: 'De eerste taak komt zodra er een venster opengaat',
    en: 'First task lands as soon as a window opens',
  );
  static LocalizedText planFirstTask(String task) => LocalizedText(
        nl: 'Eerste taak: $task',
        en: 'First task: $task',
      );
  static const planFindingFirstTask = LocalizedText(
    nl: 'Je eerste taak zoeken…',
    en: 'Finding your first task…',
  );
  static const miniPathSow =
      LocalizedText(nl: 'Sla zaaien', en: 'Sow lettuce');
  static const miniPathFrost =
      LocalizedText(nl: 'IJsheiligen', en: 'IJsheiligen');
  static const miniPathHarvest =
      LocalizedText(nl: 'Tomaat oogsten', en: 'Harvest tomato');
  static const miniPathSowDay = LocalizedText(nl: '1 apr', en: '1 Apr');
  static const miniPathFrostDay = LocalizedText(nl: '11 mei', en: '11 May');
  static const miniPathHarvestDay = LocalizedText(nl: '24 aug', en: '24 Aug');
  static const noLocationPickRegion = LocalizedText(
    nl: 'Geen locatie, vul een postcode in of kies hieronder een regio.',
    en: 'No location, enter a postcode or pick a region below.',
  );
  static const postcodeNotFoundPickRegion = LocalizedText(
    nl: 'Postcode niet gevonden (1234AB), of je bent offline. Kies hieronder '
        'een regio.',
    en: 'Postcode not found (1234AB), or you are offline. Pick a region below.',
  );
  static LocalizedText foundFrostDates(String last, String first) =>
      LocalizedText(
        nl: 'Gevonden. Laatste vorst rond $last, eerste vorst rond $first.',
        en: 'Found it. Last frost around $last, first frost around $first.',
      );
  static const whatToDo = LocalizedText(nl: 'Wat te doen ', en: 'What to do ');
  static const inYourGarden =
      LocalizedText(nl: 'in je tuin', en: 'in your garden');
  static const plotWord = LocalizedText(nl: 'tuin', en: 'plot');
  static const yourLocation =
      LocalizedText(nl: 'Jouw locatie', en: 'Your location');
  static LocalizedText noLocationMatch(String query) => LocalizedText(
        nl: 'Geen match voor "$query". Probeer een stad in de buurt, een '
            'postcode (1234AB), of kies een regio.',
        en: 'No match for "$query". Try a nearby city, a postcode (1234AB), or '
            'pick a region.',
      );
  static const useCurrentLocation = LocalizedText(
    nl: 'Gebruik mijn huidige locatie',
    en: 'Use my current location',
  );
  static const detectingLocation =
      LocalizedText(nl: 'Locatie bepalen…', en: 'Detecting your location…');
  static const renewsYearly = LocalizedText(
    nl: 'Verlengt jaarlijks. Beheren of opzeggen doe je in de App Store / Play '
        'Store.',
    en: 'Renews yearly. Manage or cancel in the App Store / Play Store.',
  );
  static const couldNotDeleteAccount = LocalizedText(
    nl: 'Account verwijderen lukte niet. Probeer het later opnieuw.',
    en: 'Could not delete the account. Try again later.',
  );
  static const scanOpensWithBeta = LocalizedText(
    nl: 'Fotoscannen komt met de beta. De probleemgids werkt nu al offline.',
    en: 'Photo scanning opens with the beta. The common-problems browser '
        'already works offline.',
  );
  static const scanQuotaReached = LocalizedText(
    nl: 'Dagelijkse scanlimiet bereikt. Morgen weer, of ontgrendel levenslang '
        'voor meer.',
    en: 'Daily scan limit reached. Tomorrow again, or unlock lifetime for '
        'more.',
  );
  static LocalizedText scanFailed(String code) => LocalizedText(
        nl: 'Scannen mislukt ($code). Probeer opnieuw.',
        en: 'Scan failed ($code). Try again.',
      );
  static const snapTipsIdentify = LocalizedText(
    nl: 'Fototips: één plant, een blad of bloem vult het beeld, daglicht.',
    en: 'Snap tips: one plant, a leaf or flower filling the frame, daylight.',
  );
  static const snapTipsDiagnose = LocalizedText(
    nl: 'Fototips: het aangetaste deel scherp en dichtbij, plus één wijdere '
        'foto als je twijfelt.',
    en: 'Snap tips: the damaged part sharp and close, plus one wider shot if '
        'unsure.',
  );
  static LocalizedText rainSkipsWatering(int mm) => LocalizedText(
        nl: 'Er viel $mm mm in de laatste drie dagen. Water geven rond vandaag '
            'wordt overgeslagen.',
        en: 'Rained $mm mm in the last three days. Waterings around today are '
            'skipped.',
      );
  static const heatAhead = LocalizedText(
    nl: 'Hitte op komst (30°C+). Potten drogen in een dag uit, dus water geven '
        'schuift naar voren.',
    en: 'Heat ahead (30°C+). Containers dry out in a day, so waterings move '
        'earlier.',
  );
  static const forecastCalm = LocalizedText(
    nl: 'Niets bijzonders in de verwachting. Het plan blijft staan.',
    en: 'Nothing dramatic in the forecast. The plan stands.',
  );
  static const youAreHere = LocalizedText(nl: 'Hier ben je', en: 'You are here');
  static LocalizedText cropsSuitMonth(int n) =>
      LocalizedText(nl: '$n gewassen passen', en: '$n crops suit it');
  static LocalizedText cropsCanGoIn(int n) => LocalizedText(
        nl: 'Er kunnen nog $n gewassen in',
        en: '$n crops can still go in',
      );
  static LocalizedText nothingPlanned(LocalizedText month) => LocalizedText(
        nl: 'Nog niets gepland voor ${month.nl}',
        en: 'Nothing planned for ${month.en}',
      );
  static LocalizedText stillSowable(LocalizedText month) => LocalizedText(
        nl: 'Nog te zaaien in ${month.nl}',
        en: 'Still sowable in ${month.en}',
      );
  static LocalizedText openAndDone(int open, int done) => LocalizedText(
        nl: '$open nu open · $done gedaan',
        en: '$open open now · $done done',
      );
  static LocalizedText doneNothingOpen(int done) => LocalizedText(
        nl: '$done gedaan · niets open vandaag',
        en: '$done done · nothing open today',
      );

  // ── the path's own stops ──────────────────────────────────────────────────
  static LocalizedText sowCrop(LocalizedText crop) =>
      LocalizedText(nl: '${crop.nl} zaaien', en: 'Sow ${crop.en}');
  static LocalizedText harvestCrop(LocalizedText crop) =>
      LocalizedText(nl: '${crop.nl} oogsten', en: 'Harvest ${crop.en}');
  static LocalizedText followOn(LocalizedText crop) => LocalizedText(
        nl: 'Daarna: ${crop.nl}',
        en: 'Follow on: ${crop.en}',
      );
  /// "Tomaat bijmesten" reads right in Dutch, "Feed Tomato" in English, so the
  /// two languages put the crop on different sides of the verb.
  static LocalizedText stepOnCrop(LocalizedText step, LocalizedText crop) =>
      LocalizedText(nl: '${crop.nl} ${step.nl.toLowerCase()}', en: '${step.en} ${crop.en}');

  static const ijsheiligen = LocalizedText(nl: 'IJsheiligen', en: 'IJsheiligen');
  static const ijsheiligenSub = LocalizedText(
    nl: 'Vorstgevoelige gewassen blijven tot 15 mei binnen',
    en: 'Tender crops stay in until 15 May',
  );
  static const lastFrost = LocalizedText(
    nl: 'Laatste vorst, gemiddeld',
    en: 'Last frost, on average',
  );
  static const lastFrostSub = LocalizedText(
    nl: 'Daarna mogen vorstgevoelige gewassen naar buiten',
    en: 'After this, tender crops can go out',
  );
  static const firstFrost = LocalizedText(
    nl: 'Eerste vorst, gemiddeld',
    en: 'First frost, on average',
  );
  static const firstFrostSub = LocalizedText(
    nl: 'Haal vorstgevoelige gewassen hiervoor binnen',
    en: 'Bring tender crops in before this',
  );
  static const orderSeed = LocalizedText(nl: 'Bestel je zaad', en: 'Order your seed');
  static LocalizedText cropsOnList(int n) =>
      LocalizedText(nl: '$n gewassen op je lijst', en: '$n crops on your list');
  static const monthPhoto = LocalizedText(
    nl: 'Maak de foto van deze maand',
    en: "Snap this month's photo",
  );
  static const seasonInPictures = LocalizedText(
    nl: 'Je seizoen, in beeld',
    en: 'Your season, in pictures',
  );
  static const seasonTally = LocalizedText(nl: 'Seizoensoogst', en: 'Season tally');
  static LocalizedText tallySoFar(int euros, String kilos) => LocalizedText(
        nl: '€$euros en $kilos kg tot nu toe',
        en: '€$euros and $kilos kg so far',
      );
  static const tallyEmpty = LocalizedText(
    nl: 'Log een oogst en het telt hier op',
    en: 'Log a harvest and it adds up here',
  );
  static LocalizedText recapTitle(int year) =>
      LocalizedText(nl: 'Jouw $year, op één kaart', en: 'Your $year, in one card');
  static const recapSub = LocalizedText(
    nl: 'Wat je teelde, plukte en bespaarde',
    en: 'What you grew, picked and saved',
  );
  static LocalizedText recapPicked(int euros) =>
      LocalizedText(nl: '€$euros geplukt tot nu toe', en: '€$euros picked so far');
  static const plantsGrown = LocalizedText(nl: 'Planten geteeld', en: 'Plants grown');
  static const picked = LocalizedText(nl: 'Geoogst', en: 'Picked');
  static const saved = LocalizedText(nl: 'Bespaard', en: 'Saved');

  // ── the weather, when it moves something ──────────────────────────────────
  static const rainDidIt = LocalizedText(
    nl: 'De regen deed het water geven',
    en: 'Rain did the watering',
  );
  static const rainDidItSub = LocalizedText(
    nl: 'Overgeslagen, je reeks telt door',
    en: 'Skipped for you, the streak still counts',
  );
  static const heatComing = LocalizedText(nl: 'Hitte op komst', en: 'Heat on the way');
  static const heatComingSub = LocalizedText(
    nl: 'Eerder water geven dan gepland',
    en: 'Water earlier than planned',
  );
  static const soilCold = LocalizedText(
    nl: 'Bodem nog te koud',
    en: 'Soil still too cold',
  );
  static const soilColdSub = LocalizedText(
    nl: 'Zaaien wacht tot het warmer is',
    en: 'Sowing held until it warms',
  );


  // ── browse: Explore and Grow ──────────────────────────────────────────────
  static const explore = LocalizedText(nl: 'Ontdek', en: 'Explore');
  static const findNextCrop = LocalizedText(
    nl: 'Vind je volgende gewas',
    en: 'Find your next crop',
  );
  static const identifyFromPhoto = LocalizedText(
    nl: 'Herken een plant van een foto',
    en: 'Identify a plant from a photo',
  );
  static const grow = LocalizedText(nl: 'Kweken', en: 'Grow');
  static LocalizedText searchCropCount(int n) =>
      LocalizedText(nl: 'Zoek in $n gewassen…', en: 'Search $n crops…');
  static LocalizedText results(int n) =>
      LocalizedText(nl: '$n resultaten', en: '$n results');
  static const profile = LocalizedText(nl: 'Profiel', en: 'Profile');

  // ── crop detail ───────────────────────────────────────────────────────────
  static const planToGrow = LocalizedText(nl: 'Plan het', en: 'Plan to grow');
  static const growingIt = LocalizedText(nl: 'Ik kweek het', en: 'Growing it');
  static const goodNeighbours = LocalizedText(nl: 'Goede buren', en: 'Good neighbours');
  static const badNeighbours = LocalizedText(nl: 'Slechte buren', en: 'Bad neighbours');
  static const noCompanionData = LocalizedText(
    nl: 'Nog geen buurgegevens.',
    en: 'No companion data yet.',
  );
  static const draftMatrix = LocalizedText(
    nl: 'Concept. De gecontroleerde matrix komt met de contentupdate',
    en: 'Draft. The verified matrix lands in the content update',
  );
  static LocalizedText verifiedAgainst(int n) => LocalizedText(
        nl: 'Gecontroleerd tegen $n NL-bronnen',
        en: 'Verified against $n NL sources',
      );
  static LocalizedText basedOn(String region) =>
      LocalizedText(nl: 'Op basis van: $region', en: 'Based on: $region');
  static LocalizedText potLitres(num litres) =>
      LocalizedText(nl: '$litres L pot', en: '$litres L pot');
  static LocalizedText harvestInDays(int days) => LocalizedText(
        nl: 'Oogst over $days dagen',
        en: 'Harvest in $days days',
      );
  static const readyToHarvest = LocalizedText(
    nl: 'Klaar om te oogsten',
    en: 'Ready to harvest',
  );
  static LocalizedText harvestDays(int min, int max) => LocalizedText(
        nl: '$min–$max dagen',
        en: '$min–$max days',
      );

  // ── settings ──────────────────────────────────────────────────────────────
  static const settings = LocalizedText(nl: 'Instellingen', en: 'Settings');
  static const account = LocalizedText(nl: 'Account', en: 'Account');
  static const membership = LocalizedText(nl: 'Lidmaatschap', en: 'Membership');
  static const yourData = LocalizedText(nl: 'Jouw gegevens', en: 'Your data');
  static const appearance = LocalizedText(nl: 'Weergave', en: 'Appearance');
  static const language = LocalizedText(nl: 'Taal', en: 'Language');
  static const help = LocalizedText(nl: 'Help', en: 'Help');
  static const themeSystem = LocalizedText(nl: 'Systeem', en: 'System');
  static const themeLight = LocalizedText(nl: 'Licht', en: 'Light');
  static const themeDark = LocalizedText(nl: 'Donker', en: 'Dark');
  static const themeFollows = LocalizedText(
    nl: 'Systeem volgt je telefoon.',
    en: 'System follows your phone.',
  );
  static const langNote = LocalizedText(
    nl: 'De hele app spreekt beide talen. Een enkele teeltuitleg is er nog '
        'alleen in het Nederlands; dat staat er dan bij.',
    en: 'The whole app speaks both languages. A few growing guides are Dutch '
        'only for now, and say so where you read them.',
  );
  static const signInBlurb = LocalizedText(
    nl: 'Log in om je tuin te bewaren en te synchroniseren. Zonder account '
        'werkt alles gewoon offline door.',
    en: 'Sign in to back up and sync your garden. Everything keeps working '
        'offline without it.',
  );
  static const email = LocalizedText(nl: 'E-mail', en: 'E-mail');
  static const sendLink = LocalizedText(
    nl: 'Stuur me een inloglink',
    en: 'Send me a sign-in link',
  );
  static const checkYourMail = LocalizedText(
    nl: 'Kijk in je mail. De link logt je in.',
    en: 'Check your mail. The link signs you in.',
  );
  static const passwordOptional = LocalizedText(
    nl: 'Wachtwoord (optioneel)',
    en: 'Password (optional)',
  );
  static const signIn = LocalizedText(nl: 'Inloggen', en: 'Sign in');
  static const createAccount = LocalizedText(nl: 'Account maken', en: 'Create account');
  static const accountCreated = LocalizedText(
    nl: 'Account aangemaakt. Bevestig via de mail die we stuurden.',
    en: 'Account created. Confirm via the mail we sent.',
  );
  static const signedIn = LocalizedText(nl: 'Ingelogd', en: 'Signed in');
  static const syncNow = LocalizedText(nl: 'Sync nu', en: 'Sync now');
  static const signOut = LocalizedText(nl: 'Uitloggen', en: 'Sign out');
  static const syncing = LocalizedText(nl: 'Synchroniseren…', en: 'Syncing…');
  static const notSyncedYet = LocalizedText(
    nl: 'Nog niet gesynchroniseerd.',
    en: 'Not synced yet.',
  );
  static LocalizedText lastSync(String time) =>
      LocalizedText(nl: 'Laatste sync $time', en: 'Last sync $time');
  static const someTablesFailed = LocalizedText(
    nl: ' · een deel is mislukt',
    en: ' · some tables failed',
  );
  static const alreadyInStep = LocalizedText(
    nl: 'Alles liep al gelijk.',
    en: 'Everything was already in step.',
  );
  static const deleteAccount = LocalizedText(nl: 'Account verwijderen', en: 'Delete account');
  static const deleteAccountAsk = LocalizedText(
    nl: 'Account verwijderen?',
    en: 'Delete account?',
  );
  static const deleteAccountBody = LocalizedText(
    nl: 'Verwijdert je account en elke gesynchroniseerde tuin, plant en log. '
        'Dit kan niet ongedaan worden gemaakt.',
    en: 'Removes your account and every synced garden, plant and log. This '
        'cannot be undone.',
  );
  static const deleted = LocalizedText(
    nl: 'Account verwijderd. Je lokale gegevens blijven op deze telefoon.',
    en: 'Account deleted. Your local data stays on this phone.',
  );
  static const cancel = LocalizedText(nl: 'Annuleren', en: 'Cancel');
  static const delete = LocalizedText(nl: 'Verwijderen', en: 'Delete');
  static const exportData = LocalizedText(
    nl: 'Exporteer mijn data (JSON)',
    en: 'Export my data (JSON)',
  );
  static const exportBlurb = LocalizedText(
    nl: 'Kopieert alles naar het klembord.',
    en: 'Copies everything to the clipboard.',
  );
  static const copied = LocalizedText(
    nl: 'Gekopieerd naar het klembord.',
    en: 'Copied to clipboard.',
  );
  static const seePlans = LocalizedText(nl: 'Bekijk plannen', en: 'See plans');
  static const managePlan = LocalizedText(nl: 'Beheer plan', en: 'Manage plan');
  static const restore = LocalizedText(nl: 'Herstellen', en: 'Restore');
  static const checkedWithStore = LocalizedText(
    nl: 'Gecontroleerd bij de store.',
    en: 'Checked with the store.',
  );
  static const syncUnavailable = LocalizedText(
    nl: 'Synchroniseren zit niet in deze build.',
    en: 'Sync is not available in this build.',
  );
  static const planFree = LocalizedText(nl: 'Gratis', en: 'Free');
  static const planLifetime = LocalizedText(nl: 'Lifetime', en: 'Lifetime');
  static const planYearly = LocalizedText(nl: 'Jaarlijks', en: 'Yearly');
  static const lifetimeNothingToCancel = LocalizedText(
    nl: 'Lifetime. Niets op te zeggen.',
    en: 'Lifetime. Nothing to cancel.',
  );
  static const freeTierBlurb = LocalizedText(
    nl: '1 tuin · 6 groeiende planten · volledige tijdlijn, herinneringen en '
        'elk gewas.',
    en: '1 garden · 6 growing plants · full timeline, reminders and every crop.',
  );
  static LocalizedText cropDataVersion(String version) => LocalizedText(
        nl: 'Cropsy · gewasdata $version',
        en: 'Cropsy · crop data $version',
      );
  static LocalizedText frostDates(String region, String source) => LocalizedText(
        nl: 'Vorstdatums: $region ($source)',
        en: 'Frost dates: $region ($source)',
      );


  // ── this week ─────────────────────────────────────────────────────────────
  static const thisWeek = LocalizedText(nl: 'Deze week', en: 'This week');
  static const nothingDueThisWeek = LocalizedText(
    nl: 'Deze week staat er niets te doen',
    en: 'Nothing due this week',
  );
  static const addPlantsToSee = LocalizedText(
    nl: 'Voeg planten toe bij Kweken om te zien wat er te doen is.',
    en: 'Add plants in Grow to see what to do.',
  );

  // ── harvest ───────────────────────────────────────────────────────────────
  static const harvest = LocalizedText(nl: 'Oogst', en: 'Harvest');
  static const thisSeason = LocalizedText(nl: 'DIT SEIZOEN', en: 'THIS SEASON');
  static const nothingYet = LocalizedText(nl: 'Nog niets', en: 'Nothing yet');
  static LocalizedText savedAtPrices(String euros) => LocalizedText(
        nl: '≈ €$euros bespaard tegen NL supermarktprijzen',
        en: '≈ €$euros saved at NL supermarket prices',
      );
  static LocalizedText unpricedCount(int n) => LocalizedText(
        nl: n == 1 ? '1 zonder prijs' : '$n zonder prijs',
        en: n == 1 ? '1 unpriced' : '$n unpriced',
      );
  static LocalizedText harvestsLogged(int n) => LocalizedText(
        nl: n == 1 ? '1 oogst gelogd' : '$n oogsten gelogd',
        en: n == 1 ? '1 harvest logged' : '$n harvests logged',
      );
  static const planFreePrice = LocalizedText(nl: '€0', en: '€0');
  static const planLifetimePrice =
      LocalizedText(nl: '€49,99 eenmalig', en: '€49.99 once');
  static const planYearlyPrice =
      LocalizedText(nl: '€19,99 / jaar', en: '€19.99 / year');
  static const planFreeBlurb = LocalizedText(
    nl: '1 tuin · 6 planten in de grond · volledige tijdlijn, herinneringen en '
        'alle gewassen · 20 fotos · 2 streakbevriezingen per maand',
    en: '1 garden · 6 growing plants · full timeline, reminders and every crop '
        '· 20 photos · 2 streak freezes a month',
  );
  static const planLifetimeBlurb = LocalizedText(
    nl: 'Onbeperkt tuinen en planten · plannerraster · diagnose · onbeperkt '
        "fotos en bevriezingen · export",
    en: 'Unlimited gardens and plants · planner grid · diagnose · unlimited '
        'photos and freezes · export',
  );
  static const planYearlyBlurb = LocalizedText(
    nl: 'Alles uit Levenslang, als abonnement. Zeg elk moment op in de App '
        'Store.',
    en: 'Everything in Lifetime, as a subscription. Cancel in the App Store '
        'any time.',
  );
  static const noPriceForUnit = LocalizedText(
    nl: 'Nog geen prijs voor deze eenheid',
    en: 'No price for this unit yet',
  );

  // ── diagnose ──────────────────────────────────────────────────────────────
  static const diagnose = LocalizedText(nl: 'Diagnose', en: 'Diagnose');
  static const autoDiagnose = LocalizedText(
    nl: 'Diagnose van een foto',
    en: 'Auto diagnose from a photo',
  );
  static const autoDiagnoseSub = LocalizedText(
    nl: 'Altijd een gok, nooit een oordeel. Premium.',
    en: 'Always a guess, never a verdict. Premium.',
  );
  static const commonProblems = LocalizedText(
    nl: 'Veelvoorkomende problemen',
    en: 'Common problems',
  );
  static const byPlantPart = LocalizedText(nl: 'Per plantdeel', en: 'By plant part');
  static const all = LocalizedText(nl: 'Alles', en: 'All');
  static const nothingForThatPart = LocalizedText(
    nl: 'Hier staat nog niets voor dat deel.',
    en: 'Nothing listed for that part yet.',
  );
  static const partWhole = LocalizedText(nl: 'Hele plant', en: 'Whole plant');
  static const partLeaves = LocalizedText(nl: 'Blad', en: 'Leaves');
  static const partStems = LocalizedText(nl: 'Stengels', en: 'Stems');
  static const partFlowers = LocalizedText(nl: 'Bloemen', en: 'Flowers');
  static const partFruits = LocalizedText(nl: 'Vruchten', en: 'Fruits');
  static const partRoots = LocalizedText(nl: 'Wortels', en: 'Roots');

  // ── the garden tab ────────────────────────────────────────────────────────
  static const myGarden = LocalizedText(nl: 'Mijn tuin', en: 'My garden');
  static const planning = LocalizedText(nl: 'Gepland', en: 'Planning');
  static const growing = LocalizedText(nl: 'Groeit', en: 'Growing');
  // Short enough to sit in a four-way segmented control.
  static const reminders = LocalizedText(nl: 'Meldingen', en: 'Reminders');
  static const start = LocalizedText(nl: 'Starten', en: 'Start');
  static const remove = LocalizedText(nl: 'Verwijderen', en: 'Remove');
  static LocalizedText removeAsk(String name) =>
      LocalizedText(nl: '$name verwijderen?', en: 'Remove $name?');
  static LocalizedText removedFromGarden(String name) => LocalizedText(
        nl: '$name is uit je tuin gehaald',
        en: '$name removed from your garden',
      );
  static const editGarden = LocalizedText(nl: 'Tuin bewerken', en: 'Edit garden');
  static const gardenName = LocalizedText(nl: 'Naam van de tuin', en: 'Garden name');
  static const growingSituation = LocalizedText(
    nl: 'Waar tuinier je?',
    en: 'Growing situation',
  );
  static LocalizedText sunHours(int hours) => LocalizedText(
        nl: 'Uren zon per dag: ${hours}u',
        en: 'Hours of sun a day: ${hours}h',
      );
  static const saveChanges = LocalizedText(nl: 'Opslaan', en: 'Save changes');
  static const nothingPlannedYet = LocalizedText(
    nl: 'Nog niets gepland',
    en: 'Nothing planned yet',
  );
  static const nothingGrowingYet = LocalizedText(
    nl: 'Nog niets aan het groeien',
    en: 'Nothing growing yet',
  );
  static const balcony = LocalizedText(nl: 'Balkon', en: 'Balcony');
  static const gardenKind = LocalizedText(nl: 'Tuin', en: 'Garden');
  static const allotment = LocalizedText(nl: 'Volkstuin', en: 'Allotment');

  // ── a plant ───────────────────────────────────────────────────────────────
  static const growingGuide = LocalizedText(nl: 'Teeltgids →', en: 'Growing guide →');
  static const growthLog = LocalizedText(nl: 'Groeilog', en: 'Growth log');
  static const logHarvest = LocalizedText(nl: 'Oogst loggen', en: 'Log harvest');
  static const harvestLogged = LocalizedText(nl: 'Oogst gelogd', en: 'Harvest logged');
  static LocalizedText movedToPlanning(String crop) => LocalizedText(
        nl: '$crop staat weer bij Gepland',
        en: '$crop moved to planning',
      );
  static const noEntriesYet = LocalizedText(
    nl: 'Nog geen notities. Voeg er een toe om de tijdlijn te starten.',
    en: 'No entries yet. Add one to start the timeline.',
  );
  static const howMuch = LocalizedText(nl: 'Hoeveel?', en: 'How much?');
  static const howMuchHint = LocalizedText(nl: 'bijv. 6 of 0,4', en: 'e.g. 6 or 0.4');
  static const pieces = LocalizedText(nl: 'stuks', en: 'pieces');
  static const saveHarvest = LocalizedText(nl: 'Oogst opslaan', en: 'Save harvest');
  static const editPlant = LocalizedText(nl: 'Plant bewerken', en: 'Edit plant');
  static const potSizeLitres = LocalizedText(
    nl: 'Potmaat (liter)',
    en: 'Pot size (litres)',
  );
  static const leaveBlankInGround = LocalizedText(
    nl: 'leeg laten voor in de volle grond',
    en: 'leave blank for in-ground',
  );
  static const planted = LocalizedText(nl: 'Geplant', en: 'Planted');
  static const growthStage = LocalizedText(nl: 'Groeifase', en: 'Growth stage');
  static const yourPath = LocalizedText(nl: 'Jouw pad', en: 'Your path');
  static const journal = LocalizedText(nl: 'Logboek', en: 'Journal');
  static const yourSeason = LocalizedText(nl: 'Jouw seizoen', en: 'Your season');
  static const bedFreesUp = LocalizedText(nl: 'Plek komt vrij', en: 'Bed frees up');
  static const about = LocalizedText(nl: 'Over', en: 'About');
  static const yourCrops = LocalizedText(nl: 'Jouw gewassen', en: 'Your crops');
  static const plannedSection = LocalizedText(nl: 'Gepland', en: 'Planned');
  static const types = LocalizedText(nl: 'Rassen', en: 'Types');

  /// A crop page's sections: the jump chip and the heading say the same thing.
  static LocalizedText cropSection(String id) => switch (id) {
        'Calendar' => const LocalizedText(nl: 'Kalender', en: 'Calendar'),
        'Timeline' => const LocalizedText(nl: 'Tijdlijn', en: 'Timeline'),
        'Difficulty' => const LocalizedText(nl: 'Moeilijkheid', en: 'Difficulty'),
        'Location' => const LocalizedText(nl: 'Standplaats', en: 'Location'),
        'Soil' => const LocalizedText(nl: 'Grond', en: 'Soil'),
        'How-tos' => const LocalizedText(nl: 'Zo doe je het', en: 'How-tos'),
        'Neighbours' => const LocalizedText(nl: 'Buren', en: 'Neighbours'),
        'Benefits' => const LocalizedText(nl: 'Waarom telen', en: 'Benefits'),
        'FAQ' => const LocalizedText(nl: 'Vragen', en: 'FAQ'),
        _ => LocalizedText(nl: id, en: id),
      };
  static const plantingCalendar = LocalizedText(
    nl: 'Zaaikalender',
    en: 'Planting calendar',
  );
  static const growthTimeline = LocalizedText(
    nl: 'Groeitijdlijn',
    en: 'Growth timeline',
  );
  static const suitableLocation = LocalizedText(
    nl: 'Geschikte standplaats',
    en: 'Suitable location',
  );
  static const soilPrep = LocalizedText(nl: 'Grond voorbereiden', en: 'Soil prep');
  static const whyGrowIt = LocalizedText(nl: 'Waarom telen', en: 'Why grow it');
  static const comingSoil = LocalizedText(
    nl: 'Grond voorbereiden',
    en: 'Soil preparation',
  );
  static const comingHowTos = LocalizedText(
    nl: 'Stap voor stap per fase',
    en: 'Step-by-step how-tos per stage',
  );
  static const comingFaq = LocalizedText(
    nl: 'Vragen, nagekeken door telers',
    en: 'Grower-reviewed FAQ',
  );
  static const comingBenefits = LocalizedText(
    nl: 'Voeding en gezondheid (NEVO)',
    en: 'Nutrition and benefits (NEVO)',
  );
  static LocalizedText contentComing(LocalizedText what) => LocalizedText(
        nl: '${what.nl}: wordt geschreven en nagekeken voor Nederlandse tuinen. '
            'Komt in de contentupdate.',
        en: '${what.en}: being written and checked for Dutch gardens. '
            'Coming in the content update.',
      );
  /// Said above a guide we only have in one language yet.
  static LocalizedText guideOnlyIn(String lang) => switch (lang) {
        'nl' => const LocalizedText(
            nl: 'Deze uitleg is er nu alleen in het Nederlands.',
            en: 'This guide is in Dutch for now.',
          ),
        _ => const LocalizedText(
            nl: 'Deze uitleg is er nu alleen in het Engels.',
            en: 'This guide is in English for now.',
          ),
      };
  static LocalizedText atSupplier(String supplier) =>
      LocalizedText(nl: 'bij $supplier', en: 'at $supplier');
  static const oftenOn = LocalizedText(nl: 'Vaak bij', en: 'Often on');
  static const insightsForYou = LocalizedText(
    nl: 'Wat nu belangrijk is',
    en: 'Insights for you',
  );
  static LocalizedText plantedOn(String day) =>
      LocalizedText(nl: 'geplant $day', en: 'planted $day');
  static const countsTowardsTally = LocalizedText(
    nl: 'Telt mee voor je seizoensoogst.',
    en: 'Counts towards your season tally.',
  );
  static const noShopPrice = LocalizedText(
    nl: 'Voor dit gewas is nog geen winkelprijs bekend, dus het telt mee voor '
        'de opbrengst maar niet voor het bespaarde bedrag.',
    en: 'This crop has no shop price yet, so it counts towards the yield but '
        'not towards money saved.',
  );
  static LocalizedText pricedPerUnit(LocalizedText unit) => LocalizedText(
        nl: 'Je telling rekent dit gewas per ${unit.nl}, dus dit telt mee voor '
            'de opbrengst maar niet voor het bespaarde bedrag.',
        en: 'Your tally prices this crop per ${unit.en}, so this adds to the '
            'yield but not to money saved.',
      );
  static const unitKg = LocalizedText(nl: 'kg', en: 'kg');

  // ── the growth log ────────────────────────────────────────────────────────
  static LocalizedText howIsItDoing(LocalizedText crop) => LocalizedText(
        nl: 'Hoe gaat het met je ${crop.nl}?',
        en: 'How is your ${crop.en} doing?',
      );
  static LocalizedText photosCount(int n) =>
      LocalizedText(nl: "Foto's ($n/9)", en: 'Photos ($n/9)');
  static const noteOptional = LocalizedText(
    nl: 'Notitie (optioneel)',
    en: 'Note (optional)',
  );
  static const noteHint = LocalizedText(
    nl: 'Eerste bloemen, luis op de toppen…',
    en: 'First flowers, aphids on the tips…',
  );
  static const saveLog = LocalizedText(nl: 'Log opslaan', en: 'Save log');
  static const moodBad = LocalizedText(nl: 'Slecht', en: 'Bad');
  static const moodOkay = LocalizedText(nl: 'Gaat wel', en: 'Okay');
  static const moodGood = LocalizedText(nl: 'Goed', en: 'Good');
  static const moodExcellent = LocalizedText(nl: 'Uitstekend', en: 'Excellent');
  static const stageStarting = LocalizedText(nl: 'Gestart', en: 'Starting');
  static const stageSeedling = LocalizedText(nl: 'Zaailing', en: 'Seedling');
  static const stageVegetative = LocalizedText(nl: 'Groeiend', en: 'Vegetative');
  static const stageFlowering = LocalizedText(nl: 'Bloeiend', en: 'Flowering');
  static const stageHarvesting = LocalizedText(nl: 'Oogsten', en: 'Harvesting');
  static const stageHarvested = LocalizedText(nl: 'Geoogst', en: 'Harvested');

  // ── adding a plant ────────────────────────────────────────────────────────
  static const setPlantDetails = LocalizedText(
    nl: 'Plantgegevens',
    en: 'Set plant details',
  );
  static const plantDetailsSub = LocalizedText(
    nl: 'Hiermee bepalen we de oogsttiming en de herinneringen.',
    en: 'Your input sets the harvest timing and care reminders.',
  );
  static const plantingDate = LocalizedText(nl: 'Plantdatum', en: 'Planting date');
  static const howDidItStart = LocalizedText(
    nl: 'Hoe is het begonnen?',
    en: 'How did it start?',
  );
  static const whereDoesItLive = LocalizedText(
    nl: 'Waar staat het?',
    en: 'Where does it live?',
  );
  static LocalizedText atLeastLitres(int litres) => LocalizedText(
        nl: 'Minstens $litres L voor dit gewas',
        en: 'At least $litres L for this crop',
      );
  static const varietyOptional = LocalizedText(
    nl: 'Ras (optioneel)',
    en: 'Variety (optional)',
  );
  static const varietyHint = LocalizedText(nl: 'bijv. Moneymaker', en: 'e.g. Moneymaker');

  // ── logging a node ────────────────────────────────────────────────────────
  static const didItToday = LocalizedText(nl: 'Vandaag gedaan', en: 'Did it today');
  static const didItOn = LocalizedText(nl: 'Ik deed dit op…', en: 'I did this on…');
  static const skipThisOne = LocalizedText(nl: 'Sla deze over', en: 'Skip this one');
  static const gotIt = LocalizedText(nl: 'Duidelijk', en: 'Got it');
  static const now = LocalizedText(nl: 'Nu', en: 'Now');
  static const skipped = LocalizedText(nl: 'Overgeslagen', en: 'Skipped');
  static LocalizedText doneOn(String day) =>
      LocalizedText(nl: 'Gedaan $day', en: 'Done $day');
  static LocalizedText movedFrom(String day, LocalizedText reason) => LocalizedText(
        nl: 'Verzet vanaf $day · ${reason.nl}',
        en: 'Moved from $day · ${reason.en}',
      );

  // ── the planner ───────────────────────────────────────────────────────────
  static const gardenPlanner = LocalizedText(nl: 'Tuinplanner', en: 'Garden planner');
  static const plannerBlurb = LocalizedText(
    nl: 'Leg je bed uit in vakjes van 30 cm.',
    en: 'Lay out your bed in 30 cm squares.',
  );
  static const save = LocalizedText(nl: 'Opslaan', en: 'Save');
  static const layoutSaved = LocalizedText(nl: 'Indeling opgeslagen', en: 'Layout saved');
  static const pickACrop = LocalizedText(
    nl: 'Kies hieronder een gewas en tik dan op de vakjes.',
    en: 'Pick a crop below, then tap cells.',
  );
  static LocalizedText painting(LocalizedText crop) => LocalizedText(
        nl: '${crop.nl} plaatsen. Tik een gevuld vakje om het leeg te maken.',
        en: 'Painting ${crop.en}. Tap a filled cell to clear it.',
      );
  static const redCells = LocalizedText(
    nl: 'Rode vakjes staan naast een gewas dat ze niet liggen.',
    en: 'Red cells sit next to a crop they dislike.',
  );
  static const planIt = LocalizedText(nl: 'Plan het', en: 'Plan it');
  static LocalizedText addedToPlanning(String crop) => LocalizedText(
        nl: '$crop staat bij Gepland',
        en: '$crop added to Planning',
      );

  // ── profile ───────────────────────────────────────────────────────────────
  static const dayStreak = LocalizedText(nl: 'Dagen op rij', en: 'Day streak');
  static const growingNow = LocalizedText(nl: 'Groeit nu', en: 'Growing now');
  static const harvested = LocalizedText(nl: 'Geoogst', en: 'Harvested');
  static const yourGarden = LocalizedText(nl: 'Jouw tuin', en: 'Your garden');
  static const region = LocalizedText(nl: 'Regio', en: 'Region');
  static const settingsAndSync = LocalizedText(
    nl: 'Instellingen en sync',
    en: 'Settings and sync',
  );
  static const signInToSync = LocalizedText(
    nl: 'Log in om te synchroniseren',
    en: 'Sign in to sync',
  );
  static const yourName = LocalizedText(nl: 'Je naam', en: 'Your name');
  static const gardener = LocalizedText(nl: 'Tuinier', en: 'Gardener');
  static const onThisDeviceOnly = LocalizedText(
    nl: 'Alleen op deze telefoon',
    en: 'On this device only',
  );

  // ── scanning ──────────────────────────────────────────────────────────────
  static const identifyAPlant = LocalizedText(
    nl: 'Herken een plant',
    en: 'Identify a plant',
  );
  static const diagnoseAPlant = LocalizedText(
    nl: 'Stel een diagnose',
    en: 'Diagnose a plant',
  );
  static const whatIsIt = LocalizedText(nl: 'Wat is dit?', en: 'What is it?');
  static const isItOk = LocalizedText(nl: 'Is het gezond?', en: 'Is it OK?');
  static const takePhoto = LocalizedText(nl: 'Foto maken', en: 'Take photo');
  static const fromPhotos = LocalizedText(nl: "Uit foto's", en: 'From photos');
  static const noConnectionScan = LocalizedText(
    nl: 'Geen verbinding. Scannen heeft internet nodig; de rest werkt offline.',
    en: 'No connection. Scans need the network; everything else works offline.',
  );
  static const notOneOfOurCrops = LocalizedText(
    nl: 'Nog niet een van onze gewassen',
    en: 'Not one of our crops yet',
  );
  static const noGuideYet = LocalizedText(
    nl: 'Hier is nog geen gids voor',
    en: 'No guide for this one yet',
  );
  static LocalizedText scansUsed(int used, int limit) => LocalizedText(
        nl: '$used van $limit scans vandaag gebruikt',
        en: '$used of $limit scans used today',
      );

  // ── the paywall ───────────────────────────────────────────────────────────
  static const payOnce = LocalizedText(
    nl: 'Betaal één keer voor meer ruimte. Geen proefperiode, geen kaart, geen '
        'verrassing bij verlenging.',
    en: 'Pay once for more room. No trial, no card, no auto-renew surprise.',
  );
  static const oneMoment = LocalizedText(nl: 'Momentje…', en: 'One moment…');
  static const keepItFree = LocalizedText(nl: 'Hou het gratis', en: 'Keep it free');
  static LocalizedText continueWith(String plan) =>
      LocalizedText(nl: 'Verder met $plan', en: 'Continue with $plan');
  static const purchasesOpenLater = LocalizedText(
    nl: 'Kopen kan vanaf de beta. Er wordt nu niets afgeschreven.',
    en: 'Purchases open with the beta. Nothing is charged yet.',
  );
  static const restorePurchases = LocalizedText(
    nl: 'Aankopen herstellen',
    en: 'Restore purchases',
  );
  static const lifetimeNothingEver = LocalizedText(
    nl: 'Lifetime: nooit iets op te zeggen.',
    en: 'Lifetime: nothing to cancel, ever.',
  );

  // ── where you grow ────────────────────────────────────────────────────────
  static const whereDoYouGrow = LocalizedText(
    nl: 'Waar tuinier je?',
    en: 'Where do you grow?',
  );
  static const townOrPostcode = LocalizedText(
    nl: 'Plaats, regio of postcode',
    en: 'Town, region or postcode',
  );
  static LocalizedText usePostcode(String code) =>
      LocalizedText(nl: 'Gebruik postcode $code', en: 'Use postcode $code');
  static const looksUpFrost = LocalizedText(
    nl: 'Zoekt de vorstdatums voor dat gebied op.',
    en: 'Looks up the frost dates for that cell.',
  );
  static const snapToRegion = LocalizedText(
    nl: 'Kies de dichtstbijzijnde teeltregio',
    en: 'Snap to the nearest growing region',
  );
  static const noLocation = LocalizedText(
    nl: 'Geen locatie gevonden. Kies een regio of vul een postcode in.',
    en: 'Could not get a location. Pick a region or enter a postcode.',
  );
  static const postcodeNotFound = LocalizedText(
    nl: 'Postcode niet gevonden (verwacht 1234AB), of je bent offline.',
    en: 'Postcode not found (expected 1234AB), or you are offline.',
  );
  static const useMyLocation = LocalizedText(
    nl: 'Gebruik mijn locatie',
    en: 'Use my location',
  );
  static const lookingUp = LocalizedText(nl: 'Zoeken…', en: 'Looking up…');
  static const postcodeHint = LocalizedText(
    nl: 'Postcode, bijv. 1012AB',
    en: 'Postcode, e.g. 1012AB',
  );
  static const lookUp = LocalizedText(nl: 'Zoek op', en: 'Look up');
  static const orPickRegion = LocalizedText(
    nl: 'Of kies een regio',
    en: 'Or pick a region',
  );

  // ── feedback on content ───────────────────────────────────────────────────
  static const isThisUseful = LocalizedText(
    nl: 'Heb je hier iets aan?',
    en: 'Is this information useful?',
  );
  static const reportError = LocalizedText(nl: 'Fout melden', en: 'Report error');
  static const whatIsWrong = LocalizedText(nl: 'Wat klopt er niet?', en: 'What is wrong?');
  static const whatIsWrongHint = LocalizedText(
    nl: 'bijv. het zaaivenster is te vroeg voor Groningen',
    en: 'e.g. sowing window is too early for Groningen',
  );
  static const send = LocalizedText(nl: 'Versturen', en: 'Send');
  static const thanksChecked = LocalizedText(
    nl: 'Dank je. We kijken elke melding binnen een week na.',
    en: 'Thanks. We check every report within a week.',
  );
  static const thanksFeedback = LocalizedText(
    nl: 'Dank voor je feedback.',
    en: 'Thanks for the feedback.',
  );
  static const thanksNoted = LocalizedText(nl: 'Dank, genoteerd.', en: 'Thanks, noted.');
  static const likeThis = LocalizedText(nl: 'Hier heb ik wat aan', en: 'I like this');
  static const errorInContent = LocalizedText(
    nl: 'Fout in de inhoud',
    en: 'Error in content',
  );
  static const suggestion = LocalizedText(nl: 'Suggestie', en: 'Suggestion');

  static const overallDifficulty = LocalizedText(
    nl: 'Moeilijkheid',
    en: 'Overall difficulty',
  );
  static const draftBadge = LocalizedText(nl: 'Concept', en: 'Draft');
  static const draftBadgeLong = LocalizedText(
    nl: 'Concept, nog niet gecontroleerd',
    en: 'Draft, not verified yet',
  );


  // ── onboarding ────────────────────────────────────────────────────────────
  static const skip = LocalizedText(nl: 'Overslaan', en: 'Skip');
  static const alreadyHaveAccount = LocalizedText(
    nl: 'Heb je al een account? Inloggen',
    en: 'Already have an account? Sign in',
  );
  static const seasonAsOnePath = LocalizedText(
    nl: 'Je seizoen, als één pad',
    en: 'Your season, as one path',
  );
  static const seasonAsOnePathBody = LocalizedText(
    nl: 'Zaaien, verpotten, oogsten, de vorstdatums die dat bepalen, en de '
        'maanden waarin nog niets gepland staat. Vink een stap af en alles '
        'daarna schuift met je mee.',
    en: 'Sowing, potting on, harvest, the frost dates that govern them, and '
        'the months when nothing is planned yet. Tick a step off and '
        'everything after it moves with you.',
  );
  static const frostBackbone = LocalizedText(
    nl: 'Bepaalt je vorstdatums, de basis onder elke plantdatum. Afgerond op '
        '~10 km, nooit gevolgd.',
    en: 'Sets your frost dates, the backbone of every planting date. Rounded '
        'to ~10 km, never tracked.',
  );
  static const doYouRelate = LocalizedText(nl: 'Herken je dit?', en: 'Do you relate?');
  static const doYouRelateSub = LocalizedText(
    nl: 'Tik aan wat op jou slaat. Sla de rest over.',
    en: 'Tap what sounds like you. Skip the rest.',
  );
  static const whatWillYouGrow = LocalizedText(
    nl: 'Wat ga je kweken?',
    en: 'What will you grow?',
  );
  static const pickAFewToStart = LocalizedText(
    nl: 'Kies er een paar om te beginnen. Later bijzetten kan altijd.',
    en: 'Pick a few to start. Add more anytime.',
  );
  static const remindBlurb = LocalizedText(
    nl: 'Een zetje op de dag zelf? Eén herinnering per ochtend, alleen als er '
        'iets te doen is, en stil als het geregend heeft.',
    en: 'Want a nudge on the day? One reminder a morning, only when there is '
        'something to do, and it stays quiet when it rained.',
  );
  static const remindMe = LocalizedText(nl: 'Herinner me', en: 'Remind me');
  static const maybeLater = LocalizedText(nl: 'Misschien later', en: 'Maybe later');

  // ── the paywall's headline ────────────────────────────────────────────────
  static const oneFreeGarden = LocalizedText(
    nl: 'Eén gratis tuin,\nvoor altijd.',
    en: 'One free garden,\nfree forever.',
  );

  // ── odds and ends ─────────────────────────────────────────────────────────
  static const whatToGrowShort = LocalizedText(
    nl: 'Wat te zaaien in…',
    en: 'What to grow in…',
  );
  static const whichPlant = LocalizedText(nl: 'Welke plant?', en: 'Which plant?');
  static LocalizedText plantIn(String months) =>
      LocalizedText(nl: 'Planten in: $months', en: 'Plant in: $months');
  static LocalizedText sources(String list) =>
      LocalizedText(nl: 'Bronnen: $list', en: 'Sources: $list');
  static LocalizedText frostRelative(String anchor, String region) => LocalizedText(
        nl: 'Deze data zijn vorst-relatief (gekoppeld aan $anchor voor $region), '
            'dus ze schuiven mee met je regio in plaats van met een vaste kalender.',
        en: 'These dates are frost-relative (anchored to $anchor for $region), '
            'so they shift with your region, not a fixed calendar.',
      );
  static LocalizedText firstHarvestAround(String region, String date) => LocalizedText(
        nl: 'In $region ligt je eerste oogst rond $date, berekend uit de '
            'vorstdatums van de regio.',
        en: 'At $region, your first harvest lands around $date, computed from '
            "the region's frost dates.",
      );

  // ── months, for every sentence that names one ─────────────────────────────
  static const months = <LocalizedText>[
    LocalizedText(nl: 'januari', en: 'January'),
    LocalizedText(nl: 'februari', en: 'February'),
    LocalizedText(nl: 'maart', en: 'March'),
    LocalizedText(nl: 'april', en: 'April'),
    LocalizedText(nl: 'mei', en: 'May'),
    LocalizedText(nl: 'juni', en: 'June'),
    LocalizedText(nl: 'juli', en: 'July'),
    LocalizedText(nl: 'augustus', en: 'August'),
    LocalizedText(nl: 'september', en: 'September'),
    LocalizedText(nl: 'oktober', en: 'October'),
    LocalizedText(nl: 'november', en: 'November'),
    LocalizedText(nl: 'december', en: 'December'),
  ];

  /// The month's name, capitalised for a heading. Dutch writes months in lower
  /// case inside a sentence, so the capital belongs to the caller.
  static LocalizedText month(int month1to12) => months[month1to12 - 1];

  static LocalizedText monthTitle(int month1to12) {
    final m = months[month1to12 - 1];
    String up(String s) => s[0].toUpperCase() + s.substring(1);
    return LocalizedText(nl: up(m.nl), en: m.en);
  }

  /// Three letters, for a marker on the path.
  static LocalizedText monthShort(int month1to12) {
    final m = months[month1to12 - 1];
    return LocalizedText(
      nl: m.nl.substring(0, 3).toUpperCase(),
      en: m.en.substring(0, 3).toUpperCase(),
    );
  }
}
