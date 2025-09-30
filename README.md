# MorunoRankEnhanced for Turtle WoW (1.12.1)

A compact Vanilla **1.12.1** PvP rank estimator with a tiny on‑screen UI.  
Supports both **classic CP interpolation** and fully **in‑house ladder math** (Standing → Bracket → RP award, with decay and Turtle floor), plus a lightweight **pool size predictor**.

**Turtle rule honored:** weekly 20% decay still applies, but your RP never drops below your current rank’s minimum (the **floor**).

New weekly view: a progress bar + label shows **this week’s RP earned** vs **total RP needed this week** to ding the next rank (decay included).

Optional helper banners for City Protector (top weekly HKs) and Top‑of‑Race. These are advisory and use your own cutoff inputs.

# CP = Contribution Points.
---

## UI Overview

- **Weekly RP label**  
  Shows either:
  - `Weekly RP: <RB>/<Needed>` (CP mode), or  
  - `Weekly RP (L): <RB>/<Needed>` (Ladder mode)  
  where:
  - **RB** = weekly RP award estimate (from CP *or* from Standing/Pool).  
  - **Needed** = total RP you need **this week** to reach the next rank, including decay.

- **Current rank label**  
  Shows your current rank. When Turtle floor prevents decay from dropping you below the rank minimum, it notes that the **decay was floored**.

- **Total RP Calc label**  
  Projected **end‑of‑week total RP** under Turtle rules (i.e., after decay and then clamped to the current rank’s minimum if needed).

- **Progress bar**  
  Tracks `RB / Needed` (same numbers as the weekly label). It’s a **planning** aid for this week.

- **Method tag**  
  A small `calc: Ladder` tag appears when **ladder math** is active. It follows `/mre banners on|off` (hidden when banners are off).

- **Optional banners**  
  City Protector & Top‑of‑Race helper lines (advisory only, based on your own cutoff inputs).

---

## How the Math Works (exactly what the addon does)

Let:
- **RA** = your RP at the **start** of the week (from rank & %).
- **RC** = **weekly decay** = `0.2 × RA` (20%).
- **nextMin** = RP threshold for the **next rank**.

There are two ways to compute the weekly RP award **RB**:

### 1) CP Interpolation (Ladder OFF)
- Uses Blizzard’s weekly honor → CP and a lookup curve to estimate **RB_cp** (up to **13,000 RP** at the highest band).
- Best **during the week** because it responds to your actual honor earned so far.

### 2) Ladder Math (Ladder ON)
- Inputs: **Standing** (your weekly position) and **Pool** (your faction’s players with ≥15 HK).  
- Determines bracket **from the TOP** using standard Vanilla distribution:  
  `Br14 ≈ top 0.3%`, `Br13 ≈ 0.8%`, ..., `Br2 ≈ 84.5%`, `Br1 = the rest`.
- Award:  
  - Base RP = `0` for Br1, `400` for Br2, `(b − 2) × 1000` for Br3..Br14.  
  - Plus up to `+1000` linearly inside the bracket (1.0 at top of the bracket, 0.0 at bottom).  
  - Capped at **13,000 RP**.  
- **HK gate:** need **≥15 HK** (or **≥1 HK** if **Turtle Mode** is ON) to receive any award.

> The addon uses **RB_cp** in CP mode or **RB_ladder** in Ladder mode, based on your toggle.

### End‑of‑Week RP (Turtle)
```
raw   = RA + RB − RC
floor = min RP for your current rank
EEarns = max(raw, floor)   -- Turtle clamps you up to the floor if raw < floor
```

### Weekly “Needed” (for the bar/label)
We want RB_required so you **reach** the next rank this week:
```
RA + RB_required − RC ≥ nextMin
⇒ RB_required ≥ nextMin − 0.8 × RA
Needed = max(0, nextMin − 0.8 × RA)
```

**Example**  
Rank 10 (floor 40,000). Earned **RB = 5,674**:  
- Decay `RC = 8,000` → Needed `= 45,000 − 32,000 = 13,000`.  
- Weekly label shows `5,674 / 13,000` (~43%).  
- `raw = 37,674` → Turtle floor clamps to **40,000** (still R10, 0%).

---

## Typical Flows (what to use & when)

### During the Week (live estimate)
Use **CP mode**:
```
/mre ladder off
/mre report
```
Reflects **actual honor** so far → realistic weekly award (RB).

### After the Weekly Update (official result)
Use **Ladder mode** with real inputs:
```
/mre ladder on
/mre standing <S from Honor tab after reset>
/mre pool fromcut <bracket> <cutoffStanding>   -- best accuracy from a posted cutoff
/mre calc
```
If no cutoff is posted:
```
/mre pool predict
/mre calc
```
**Remember the HK gate:** 15 HK (1 HK if Turtle Mode ON).

---

## Pool Predictor (in‑house, optional)

Estimate **Pool** without HonorSpy:

- **Backsolve from a known cutoff** (most accurate):
```
/mre pool fromcut 14 3     -- “Br14 cutoff = 3” ⇒ pool ≈ 3 / 0.003
```
- **BG sampler + EMA** (autonomous estimate you can tune):
```
/mre pool predict
/mre pool alpha 0.60       -- weight on this week vs history (0..1)
/mre pool coverage 8       -- how many players each unique likely "represents"
```
- **Manual override**:
```
/mre pool 1200
```

The predictor resets its weekly sampler automatically when “This Week HK” drops at reset and keeps a small pool history.

---

## Slash Commands

All commands start with **`/mre`**.

### Core
- `/mre show` — show the frame  
- `/mre hide` — hide the frame  
- `/mre lock` — lock the frame (no dragging)  
- `/mre unlock` — unlock the frame (hold a modifier + left‑drag)  
- `/mre reset` — reset position & settings to defaults  
- `/mre report` — one‑line diagnostic with current math (honor/CP path if Ladder is OFF)

### Turtle Options
- `/mre turtle on|off` — enable/disable RP **floor** clamping.  
  **On (default):** end‑of‑week RP cannot go below your **current rank floor**.  
  **Off:** classic behavior (for comparison/testing).

### Ladder Math (Standing/Pool)
- `/mre ladder on|off` — toggle Ladder math  
- `/mre standing <S>` — set your Standing (from Honor tab **after** the weekly update)  
- `/mre pool <N>` — set Pool (players with ≥15 HK for your faction that week)  
- `/mre calc` — print ladder result (pool, standing, bracket, % inside, award, `nextRP`; notes HK gate)

### Pool Predictor
- `/mre pool predict` — estimate pool via BG sampler + EMA/history  
- `/mre pool alpha <0..1>` — EMA weight (default **0.60**)  
- `/mre pool coverage <K>` — sampler expansion (default **8**)  
- `/mre pool fromcut <br> <standing>` — backsolve pool from a posted bracket cutoff  
  - Example: `/mre pool fromcut 14 3`

### Banners
- `/mre banners on|off` — show/hide **both** helper banners **and** the small **`calc: Ladder`** method tag.

### City Protector & Top‑of‑Race (advisory)
- `/mre citycutoff <HK>` — set your estimated HK cutoff for City Protector  
  - Example: `/mre citycutoff 750`
- `/mre race <name>` — set your race name (for display)  
  - Example: `/mre race orc`
- `/mre racecutoff <HK>` — set your estimated weekly HK cutoff for Top‑of‑Race  
  - Example: `/mre racecutoff 1200`

---

## Tips & FAQs

**Why does Total show 0% but the weekly bar shows progress?**  
You earned RP (**RB**), but **decay** (**RC**) exceeded it. Turtle clamps you back to the **rank floor**, so the official end‑of‑week total doesn’t move—yet the weekly bar still shows how close you were **this week**.

**Can the bar show progress against total RP instead?**  
It’s intentionally **weekly** for planning each reset. The **Total RP Calc** line reflects the official Turtle outcome after decay/floor.

**City Protector / Top‑of‑Race seems off.**  
Those are advisory. Update your cutoffs as realm activity changes.

**Why does Ladder show a small award even with huge honor?**  
Ladder cares about **Standing within Pool**, not raw honor. If many players earned similar/more honor, your standing may land mid‑bracket (e.g., Br5 → ~3–4k RP). Use **CP mode** during the week to see the honor‑driven estimate.

**HK gate?**  
You must reach the gate to get any weekly award: **15 HK** normally, **1 HK** if **Turtle Mode** is ON.

**Text overlaps at small UI scales.**  
Increase UI scale slightly or reduce font size in the Lua (uses `GameFontNormalSmall`).

---

## Troubleshooting

- Can’t move the frame? `/mre unlock`, hold a modifier (Shift/Ctrl/Alt) and **left‑drag**. `/mre lock` to fix it again.  
- Weekly bar shows `0/0`? You likely already meet what’s needed (or can’t improve this week). The denominator is clamped at ≥ 0.  
- After big updates, `/mre reset` to re‑apply sane defaults.  
- If the method tag doesn’t hide, use `/mre banners off` (the tag follows the banner toggle).

---

## Install

1. Copy the addon folder into `Interface/AddOns/MorunoRankEnhanced`.  
2. Ensure you’re running a **Vanilla 1.12.1** client (Lua 5.0 APIs).  
3. Launch the game and use `/mre` for help.

---

## Credits

Core logic by **Martock**.  
UI & enhancements by **Stretpaket**.  
Turtle WoW adjustments, ladder math, and pool predictor in this build by **Torio**.
