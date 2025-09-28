# MorunoRankEnhanced for Turtle WOW

A compact Vanilla WoW 1.12.1 PvP rank estimator with a tiny on-screen UI, updated for Turtle WoW rules.

Honors the Turtle change: weekly 20% decay still applies, but your RP never drops below your current rank’s minimum (the “floor”).

New weekly view: progress bar + label show this week’s RP earned vs the total weekly RP needed to ding the next rank (including decay).

Optional helper banners for City Protector (top 8 HKs weekly) and Top-of-Race (highest weekly HKs per playable race). These are advisory and use your own cutoff inputs.

# UI Overview

Weekly RP label — shows Weekly RP: <RB>/<Needed>

RB = your bracket RP earned this week (from your current standing).

Needed = total weekly RP needed from the start of this week to reach the next rank, including the weekly decay of your starting RP.

Current rank label — shows your current rank (and notes when the floor kept you at minimum RP this week).

Total RP Calc label — shows your end-of-week total RP under Turtle rules (i.e., after decay and then clamped to your current rank’s minimum if needed).

Progress bar — tracks RB/Needed as a percentage (same numbers as the weekly label).

Note: The weekly bar is for planning. The Total RP Calc remains the “official” Turtle result (after decay + floor).

# How the math works

Let:

RA = your RP at the start of the week (derived from your rank & %).

RB = RP gained this week from your current standing (via CP→RP bracket).

RC = weekly decay = 0.2 × RA (20%).

nextMin = RP threshold for the next rank.

Total RP Calc (Turtle):

raw = RA + RB - RC
floor = min RP for your current rank
EEarns = max(raw, floor)

Weekly “Needed” (for the bar/label):

You need RB_required such that: RA + RB_required - RC >= nextMin
⇒ RB_required >= nextMin - 0.8 × RA
Needed = max(0, nextMin - 0.8 × RA)

Example

You are Rank 10 (floor 40,000). This week you earned RB = 5,674:

Decay: RC = 0.2 × 40,000 = 8,000

Weekly Needed: nextMin(11) − 0.8×RA = 45,000 − 32,000 = 13,000

UI shows Weekly RP: 5,674 / 13,000 and the bar at ~43%.

raw total = 40,000 + 5,674 − 8,000 = 37,674 → Turtle floor clamps to 40,000 (still Rank 10, 0%).

This tells you at a glance how far you are, this week, from making Rank 11.


# Slash commands

All commands start with /mre.

Core

/mre show — show the frame

/mre hide — hide the frame

/mre lock — lock the frame (no dragging)

/mre unlock — unlock the frame (hold down a modifier key and drag with left mouse)

/mre reset — reset position & settings to defaults

/mre report — print a one-line diagnostic with the current RP math

Turtle options

/mre turtle on|off — enable/disable RP floor clamping (Turtle behavior).

On (default): end-of-week RP cannot go below your current rank floor.

Off: classic behavior (for comparison/testing).

Banners

/mre banners on|off — show/hide the two helper banners (City Protector & Top-of-Race).

City Protector & Top-of-Race (advisory)

These helpers are estimates that rely on your cutoff inputs. The addon cannot read realm-wide standings/HKs.

/mre citycutoff <HK> — set your estimated HK cutoff to make City Protector (top 8 weekly).

Example: /mre citycutoff 750

/mre race <name> — set your race name (for display).

Example: /mre race orc

/mre racecutoff <HK> — set your estimated HK cutoff to be Top <race> for the week.

Example: /mre racecutoff 1200



# Tips & FAQs

Q: My total shows 0% but the weekly bar shows progress. Why?
A: You earned RP (RB), but decay (RC) this week may be larger than RB. Turtle rules clamp you back to the rank floor, so the official end-of-week total doesn’t move — but the weekly bar still shows how close you were to making it this week.

Q: Can I see the progress bar against total RP (not weekly)?
A: The bar is intentionally weekly so you can plan each reset. The Total RP Calc line continues to reflect the official Turtle outcome.

Q: City Protector / Top-of-Race seems off.
A: Those are advisory. Update your cutoffs as the realm’s activity changes.

Q: The frame text overlaps at small UI scales.
A: Increase UI scale slightly or reduce font size in the Lua (GameFontNormalSmall usage).



# Troubleshooting

If the frame doesn’t move, /mre unlock, then drag with a modifier key held down; /mre lock to fix it in place.

If you see unexpected 0/0 weekly bars, you likely already meet or exceed what’s needed this week (or starting RP is already above the next threshold). The denominator is clamped at >= 0.

After updates, /mre reset if something looks off (re-applies sane defaults).


# Credits

Core logic by Martock (Nostalrius forum).

UI & enhancements by Stretpaket.

Turtle WoW adjustments & weekly-planning view in this build by Torio

