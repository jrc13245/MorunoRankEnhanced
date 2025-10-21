# MorunoRankEnhanced for Turtle WoW (1.12.1)

A compact Vanilla **1.12.1** PvP rank estimator with a tiny on-screen UI.  
Supports both **classic CP interpolation** and fully **in-house ladder math** (Standing → Bracket → RP award, with decay and Turtle floor), plus a lightweight **pool size predictor** with confidence scoring and **intelligent standing estimation**.

**Turtle rule honored:** weekly 20% decay still applies, but your RP never drops below your current rank's minimum (the **floor**).

New weekly view: a progress bar + label shows **this week's RP earned** vs **total RP needed this week** to ding the next rank (decay included).

Optional helper banners for City Protector (top weekly HKs) and Top-of-Race. These are advisory and use your own cutoff inputs.

# CP = Contribution Points.
---

## UI Overview

- **Weekly RP label**  
  Shows either:
  - `This week CP: <formatted>` displays your current week's contribution points with comma formatting for readability
  
- **Current rank label**  
  Shows your next week's projected rank with visual indicators:
  - `(↑ Rank X)` for rank up
  - `(↓ Rank X)` for rank down  
  - `(= Rank X)` for maintaining rank
  - `[floored]` tag when Turtle floor prevents decay from dropping you below rank minimum

- **Progress bar with label**  
  Shows `<RB>/<Needed> RP (%)` where:
  - **RB** = weekly RP award estimate (from CP *or* from Standing/Pool)
  - **Needed** = total RP you need **this week** to reach the next rank, including decay
  - Tracks progress toward next rank as a **planning** aid for this week

- **Method tag**  
  A small `calc: Ladder` tag appears when **ladder math** is active. When using standing estimation, shows `calc: Ladder (est standing: X)`. Follows `/mre banners on|off` (hidden when banners are off).

- **Optional banners**  
  City Protector & Top-of-Race helper lines (advisory only, based on your own cutoff inputs).

---

## How the Math Works (exactly what the addon does)

Let:
- **RA** = your RP at the **start** of the week (from rank & %).
- **RC** = **weekly decay** = `0.2 × RA` (20%).
- **nextMin** = RP threshold for the **next rank**.

There are two ways to compute the weekly RP award **RB**:

### 1) CP Interpolation (Ladder OFF)
- Uses Blizzard's weekly honor → CP and a lookup curve to estimate **RB_cp** (up to **13,000 RP** at the highest band).
- Best **during the week** because it responds to your actual honor earned so far.

### 2) Ladder Math (Ladder ON)
- Inputs: **Standing** (your weekly position) and **Pool** (your faction's players with ≥15 HK).  
- **Standing Estimation**: When enabled (default ON), automatically adjusts your standing based on this week's CP vs pool average:
  - Early week (<1000 CP): uses last week's standing
  - Mid-week: estimates improvement/decline based on relative performance
  - Adjusts by ±15-40% based on CP performance vs pool average
- Determines bracket **from the TOP** using standard Vanilla distribution:  
  `Br14 ≈ top 0.3%`, `Br13 ≈ 0.8%`, ..., `Br2 ≈ 84.5%`, `Br1 = the rest`.
- Award:  
  - Base RP = `0` for Br1, `400` for Br2, `(b - 2) × 1000` for Br3..Br14.  
  - Plus up to `+1000` linearly inside the bracket (1.0 at top of the bracket, 0.0 at bottom).  
  - Capped at **13,000 RP**.  
- **HK gate:** need **≥15 HK** (or **≥1 HK** if **Turtle Mode** is ON) to receive any award.

> The addon uses **RB_cp** in CP mode or **RB_ladder** in Ladder mode, based on your toggle.

### End-of-Week RP (Turtle)
```
raw   = RA + RB - RC
floor = min RP for your current rank
EEarns = max(raw, floor)   -- Turtle clamps you up to the floor if raw < floor
```

### Weekly "Needed" (for the bar/label)
We want RB_required so you **reach** the next rank this week:
```
RA + RB_required - RC ≥ nextMin
⇒ RB_required ≥ nextMin - 0.8 × RA
Needed = max(0, nextMin - 0.8 × RA)
```

**Example**  
Rank 10 (floor 40,000). Earned **RB = 5,674**:  
- Decay `RC = 8,000` → Needed `= 45,000 - 32,000 = 13,000`.  
- Weekly label shows `5,674 / 13,000` (~43%).  
- `raw = 37,674` → Turtle floor clamps to **40,000** (still R10, 0%).

---

## Typical Flows (what to use & when)

### During the Week (live estimate)
Use **CP mode** for real-time tracking:
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
**With Standing Estimation (recommended):**
```
/mre estimate on   -- enables automatic standing adjustment (ON by default)
```
The addon will intelligently adjust your standing based on this week's performance.

**Remember the HK gate:** 15 HK (1 HK if Turtle Mode ON).

---

## Pool Predictor (in-house, optional)

Estimate **Pool** without HonorSpy, with **confidence scoring** for accuracy assessment:

### Confidence Levels
- **High (70-100%)**: 50+ unique names, 10+ BGs, 4+ week history
- **Medium (40-69%)**: 15+ unique names, 5+ BGs, 2+ week history  
- **Low (0-39%)**: Limited data, use predictions cautiously

### Prediction Methods

- **Backsolve from a known cutoff** (most accurate):
```
/mre pool fromcut 14 3     -- "Br14 cutoff = 3" ⇒ pool ≈ 3 / 0.003
```
- **BG sampler + EMA** (autonomous estimate you can tune):
```
/mre pool predict          -- manual prediction
/mre autopredict on        -- auto-predict after each BG (DEFAULT: ON)
/mre pool alpha 0.5        -- weight on this week vs history (0..1, default 0.5)
/mre pool coverage 12      -- how many players each unique likely "represents" (default 12)
/mre pool status           -- view confidence and statistics
```
- **Manual override**:
```
/mre pool 1200
```

The predictor:
- Automatically samples BG scoreboards for faction members
- Resets its weekly sampler when "This Week HK" drops at reset
- Maintains pool history for improved accuracy
- Adjusts confidence based on data quality
- Auto-adjusts alpha weighting based on confidence

---

## Standing Estimation

**NEW**: Intelligent standing estimation automatically adjusts your rank calculations based on this week's performance:

```
/mre estimate on|off       -- toggle estimation (DEFAULT: ON)
/mre standing status       -- view current/estimated standing with analysis
```

### How It Works
- Uses your **base standing** from last week (`/mre standing <S>`)
- Compares your **this week's CP** to the pool average
- Adjusts standing estimate based on relative performance:
  - **>1.5x pool avg**: -30% standing (major improvement)
  - **>1.2x pool avg**: -15% standing (moderate improvement)
  - **<0.5x pool avg**: +40% standing (significant decline)
  - **<0.8x pool avg**: +15% standing (slight decline)
- Early week (<1000 CP): uses base standing
- Mid/late week: provides intelligent estimate

### Scenario Planning
View best/worst case predictions:
```
/mre scenarios
```
Shows three scenarios based on your estimated standing:
- **Improve 15%**: If you perform better than estimated
- **Maintain**: Current trajectory  
- **Worsen 15%**: If you perform worse than estimated

Each scenario shows: standing → bracket → RP award → resulting rank

---

## Slash Commands

All commands start with **`/mre`**.

### Core
- `/mre show` (or `/mre s`) — show the frame  
- `/mre hide` (or `/mre h`) — hide the frame  
- `/mre lock` (or `/mre l`) — lock the frame (no dragging)  
- `/mre unlock` (or `/mre u`) — unlock the frame (hold a modifier + left-drag)  
- `/mre reset` — reset position & settings to defaults  
- `/mre report` (or `/mre r`) — one-line diagnostic with current math

### Turtle Options
- `/mre turtle on|off` — enable/disable RP **floor** clamping.  
  **On (default):** end-of-week RP cannot go below your **current rank floor**, 1 HK minimum  
  **Off:** classic behavior, 15 HK minimum (for comparison/testing)

### Ladder Math (Standing/Pool)
- `/mre ladder on|off` — toggle Ladder math  
- `/mre standing <S>` — set your Standing (from Honor tab **after** the weekly update)  
- `/mre standing status` — view current base standing and estimated standing with analysis
- `/mre calc` — print ladder result (pool, standing, bracket, % inside, award, `nextRP`; notes HK gate)

### Standing Estimation
- `/mre estimate on|off` — toggle intelligent standing estimation (DEFAULT: ON)
- `/mre scenarios` — show best/maintain/worst case rank predictions (requires ladder mode)

### Pool Predictor
- `/mre pool <N>` — manually set pool size
- `/mre pool predict` — estimate pool via BG sampler + EMA/history  
- `/mre pool status` — view confidence score, unique names, BGs, and statistics
- `/mre autopredict on|off` — toggle auto-prediction after BGs (DEFAULT: ON)
- `/mre pool alpha <0..1>` — EMA weight (default **0.5**)  
- `/mre pool coverage <K>` — sampler expansion (default **12**)  
- `/mre pool fromcut <br> <standing>` — backsolve pool from a posted bracket cutoff  
  - Example: `/mre pool fromcut 14 3`

### Banners
- `/mre banners on|off` — show/hide **both** helper banners **and** the small **`calc: Ladder`** method tag.

### City Protector & Top-of-Race (advisory)
- `/mre citycutoff <HK>` — set your estimated HK cutoff for City Protector  
  - Example: `/mre citycutoff 750`
- `/mre race <name>` — set your race name (for display)  
  - Example: `/mre race orc`
- `/mre racecutoff <HK>` — set your estimated weekly HK cutoff for Top-of-Race  
  - Example: `/mre racecutoff 1200`

---

## Tips & FAQs

**Why does Total show 0% but the weekly bar shows progress?**  
You earned RP (**RB**), but **decay** (**RC**) exceeded it. Turtle clamps you back to the **rank floor**, so the official end-of-week total doesn't move—yet the weekly bar still shows how close you were **this week**.

**Can the bar show progress against total RP instead?**  
It's intentionally **weekly** for planning each reset. The rank label and percentage reflect the official Turtle outcome after decay/floor.

**How accurate is standing estimation?**  
Estimation provides a reasonable mid-week projection but cannot account for:
- Players who haven't queued yet this week
- End-of-week honor pushes by other players
- Exact pool size fluctuations
Use it as a planning tool, not a guarantee. Check `/mre standing status` for transparency.

**Pool prediction confidence is Low - should I trust it?**  
Low confidence (<40%) means limited data. Predictions will be less accurate. To improve:
- Run more BGs to sample more players
- Use `/mre pool fromcut` with posted cutoffs when available
- Let the addon build history over multiple weeks

**City Protector / Top-of-Race seems off.**  
Those are advisory. Update your cutoffs as realm activity changes.

**Why does Ladder show a small award even with huge honor?**  
Ladder cares about **Standing within Pool**, not raw honor. If many players earned similar/more honor, your standing may land mid-bracket (e.g., Br5 → ~3-4k RP). Use **CP mode** during the week to see the honor-driven estimate.

**HK gate?**  
You must reach the gate to get any weekly award: **15 HK** normally, **1 HK** if **Turtle Mode** is ON.

**Text overlaps at small UI scales.**  
Increase UI scale slightly or reduce font size in the Lua (uses `GameFontNormalSmall`).

**Scenarios show confusing results.**  
Scenarios are calculated from your **estimated** standing (if enabled), not your base standing. Check `/mre standing status` to see both values.

---

## Troubleshooting

- Can't move the frame? `/mre unlock`, hold a modifier (Shift/Ctrl/Alt) and **left-drag**. `/mre lock` to fix it again.  
- Weekly bar shows `0/0`? You likely already meet what's needed (or can't improve this week). The denominator is clamped at ≥ 0.  
- After big updates, `/mre reset` to re-apply sane defaults.  
- If the method tag doesn't hide, use `/mre banners off` (the tag follows the banner toggle).
- Standing estimation seems wrong? Check `/mre standing status` to see the calculation. You can disable it with `/mre estimate off`.
- Pool prediction unstable? Check `/mre pool status` for confidence. Run more BGs or use `/mre pool fromcut` with known cutoffs.

---

## Install

1. Copy the addon folder into `Interface/AddOns/MorunoRankEnhanced`.  
2. Ensure you're running a **Vanilla 1.12.1** client (Lua 5.0 APIs).  
3. Launch the game and use `/mre` for help.

---

## Default Settings

On first load, the addon uses these defaults:
- **Turtle Mode**: ON (RP floor + 1 HK gate)
- **Auto-predict**: ON (pool prediction after each BG)
- **Standing Estimation**: ON (intelligent standing adjustment)
- **Banners**: OFF (City/Race helpers and method tag hidden)
- **Ladder Mode**: OFF (uses CP interpolation)
- **Pool**: 800 (default starting value)
- **Pool Alpha**: 0.5 (balanced between current and historical data)
- **Pool Coverage**: 12 (each unique name represents ~12 players)

---

## Credits

Core logic by **Martock**.  
UI & enhancements by **Stretpaket**.  
Turtle WoW adjustments, ladder math, pool predictor, standing estimation, and confidence scoring by **Torio**.
