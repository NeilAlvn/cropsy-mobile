# Conversion overhaul — handover (2026-10-12)

Branch `conversion` in `cropsy-mobile` (on top of `six-languages`), branch
`conversion` in the website repo, branch `conv-copy` in `cropsy-mobile` for
store listing copy. Nothing is pushed or merged.

## What changed in the app

- **Pricing model**: yearly €39.99 with a 7-day free trial (lead plan), monthly
  €7.99, lifetime €99.99. Free tier: 1 garden, 3 growing plants at a time
  (planning list unlimited), this week + next week of the season, reminders,
  all crop content.
- **Paywall** (`lib/features/paywall/paywall_screen.dart`): yearly preselected,
  trial timeline (today / reminder day 5 / charged day 7), benefits built from
  the person's own answers and crops, close X fades in after 2 s, "continue with
  free" link, exit offer on first onboarding dismiss, `PaywallTrigger` per entry
  point. Offering metadata `dismissible: false` turns the onboarding paywall
  hard (A/B via RevenueCat Experiments, no build needed).
- **Onboarding**: priorities as chips, new "Does this sound like you?" page
  (3 statements), crops beyond the free 3 wait as planning plants, plan payoff
  shows a blurred full-season teaser, then a reminders priming page ("we'll
  remind you before any trial ends"), then the paywall. Three starters
  preselected so the plant-limit paywall only follows the person's own picks.
  Trust line no longer says "Dutch seed calendars" in every language.
- **Gating**: 3 growing plants, season rows from today + 14 days blurred behind
  an unlock bar, weekly trial card on Home (max once per 7 days), triggers on
  planner, diagnose, plant limit.
- **Lifecycle notifications** (`lib/notifications/lifecycle.dart`): trial day 3
  value nudge, day 5 "trial ends in 2 days" reminder, free-only seasonal nudges
  1 Oct ("plan next season") and 15 Feb ("season starts"); tapping opens the
  paywall. Care reminders now only cancel their own ids (0–99).
- **Analytics** (PostHog, after consent, enums/counts only): `paywall_shown`,
  `paywall_plan_selected`, `paywall_purchase_started`,
  `paywall_purchase_completed`, `paywall_dismissed`, `exit_offer_shown`,
  `exit_offer_accepted`, `onboarding_step_viewed`, `onboarding_pains`,
  `notif_priming_shown`, `notif_priming_result`, `onboarding_completed`.

## Luuk: store and RevenueCat setup

App Store Connect (subscription group with `cropsy_yearly`):
1. `cropsy_yearly`: price €29.99 → **€39.99**; add introductory offer
   **Free, 1 week**, all territories.
2. New auto-renewable `cropsy_monthly`, **€7.99**, same group.
3. New auto-renewable `cropsy_yearly_exit`, €39.99, same group, introductory
   offer **Pay up front €24.99 for 1 year**. (Its own product because
   `cropsy_yearly`'s one intro offer is the trial.)
4. `cropsy_lifetime`: €49.99 → **€99.99**.
5. Review screenshot per new product (the paywall) and review notes.
6. Check PT and SE price points by hand after the auto-conversion.

Play Console:
1. `cropsy_yearly` base plan `annual`: €39.99; add offer with free phase
   **P1W**, eligibility new customers, mark as default offer.
2. New subscription `cropsy_monthly` (base plan monthly, €7.99).
3. New subscription `cropsy_yearly_exit` with a discounted first-year phase
   €24.99, then €39.99.
4. `cropsy_lifetime` → €99.99.

RevenueCat:
1. Attach `cropsy_monthly` and `cropsy_yearly_exit` to entitlement `premium`.
2. Offering `default` (current): `$rc_annual` = cropsy_yearly,
   `$rc_monthly` = cropsy_monthly, `$rc_lifetime` = cropsy_lifetime.
3. Offering `exit_offer`: `$rc_annual` = cropsy_yearly_exit.
4. For the hard-paywall test: duplicate `default` as `default_hard` with
   metadata `{"dismissible": false}` and run an Experiment default vs
   default_hard. Start it before February so a winner exists for March–May.
5. Product ids must contain `month` / `lifetime` for the app's plan mapping;
   everything else counts as yearly.

## Luuk: other steps

- Website branch `conversion`: review the terms text (trial, cancel 24 h before,
  auto-renew) — written from store behaviour, not lawyer-checked. Deploy with
  the six-languages site.
- Store listing copy (`tool/store/metadata/*.md` on `conv-copy`): paste into
  ASC/Play. No `nl.md` exists; update the Dutch listing in ASC by hand.
- PRD §0/§5/§9 (honest pricing, no trial, lifetime-first) are superseded by
  this; amend the PRD in `cropsy/docs/PRD.md` when the decision is final.
- UK DMCC rules (from January 2027): renewal reminders and a 14-day cooling-off
  after a trial converts. The day-5 reminder covers the first part.

## Seen in the simulator QA (2026-10-12), not fixed

The build has the live RevenueCat iOS key, so the paywall showed today's real
offering (yearly without trial, lifetime, no monthly): no trial timeline until
the store setup above is done. Home card and season lock only promise a free
week when the store actually offers one (`trialDaysOffered`).

Open, outside this branch's scope:
- Crop names in de/fr/sv/pt fall back to English (snapshot has en/nl only).
- German users see Dutch regions and a Dutch postcode hint ("1012AB").
- Plan payoff in October shows "Plant out Tomato, 12 Oct" — check timing engine.
- Frost dates render "04-15"; German short dates "12 Okt." vs "12. Okt.".
- Paywall: store price string and computed per-month line can differ in number
  format.
- Crops page: free-limit note sits below the fold.
- Season path rows lose crop labels when scrolled sideways.
- Switching to dark mode on the Season tab keeps a light sky until restart.
- Small-screen (iPhone SE) pass not done.

Screenshots: `tool/shots/conversion/` (gitignored).
