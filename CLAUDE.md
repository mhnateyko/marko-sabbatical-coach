# Marko's Sabbatical Coach — Project Context

Single HTML file personal trainer app. No build step. No frameworks. Works offline on phone.

## File
`/Users/markohnateyko/Documents/Workouts/sabbatical_coach.html`
GitHub: `marko-sabbatical-coach` repo (target: GitHub Pages for permanent mobile URL)

## Architecture

**Single HTML file**: ~2100 lines — CSS + HTML structure + vanilla JS, Chart.js from CDN.

**Storage**: `localStorage` key `marko_sabbatical_coach` (primary). Supabase sync layer added as optional cloud backup (see Supabase section below).

**State shape**:
```js
state = {
  chatHistory: [{role:'user'|'ai', content:'...'}],   // last 40 messages
  workouts: {
    [dateKey]: {   // YYYY-MM-DD
      sets: { [exId]: [{reps, weight, rpe, done}] },
      note: '',
      completed: false,
      substitution: ''   // what user did instead
    }
  },
  overrides: { [dateKey]: schedIdx },  // user-swapped workout types
  settings: {
    sabbaticalStart: 'YYYY-MM-DD',
    userName: 'Marko',
    model: 'claude-sonnet-4-6',
    equipment: { rings, bar, pushup, bands, wheel, dumbbells },
    supabaseUrl: '',      // added by Supabase integration
    supabaseKey: ''       // added by Supabase integration
  },
  garminActivities: [...],   // live Garmin data from CSV import
  currentTab: 'history'
}
```

**API key**: stored separately as `localStorage.getItem('marko_api_key')`, never in state JSON.

## Weekly Template

| Day | Workout | schedIdx |
|-----|---------|----------|
| Mon | Upper Push | 0 |
| Tue | Zone 2 Cardio | 1 |
| Wed | Upper Pull | 2 |
| Thu | Adventure Day | 3 |
| Fri | Lower Body | 4 |
| Sat | Long Cardio | 5 |
| Sun | Rest + Recover | 6 |

`getScheduleForDate(d)` — JS `[6,0,1,2,3,4,5]` map (Sun=0 in JS → schedIdx 6=Rest).
`state.overrides[dateKey]` overrides the default for a date.

## Exercise IDs (for set logging)

**Push (schedIdx 0)**: `hs_hold`, `h_push`, `v_push`, `push_vol`, `l_sit`, `face_pull`
**Cardio (schedIdx 1)**: `z2_run`, `z2_alt`
**Pull (schedIdx 2)**: `scap`, `v_pull`, `h_pull`, `curls`, `pull_aparts`, `dislocates`
**Adventure (schedIdx 3)**: `adventure`, `mobility`
**Legs (schedIdx 4)**: `pistol`, `bss`, `nordic`, `jump_sq`, `calf`, `hip_mob`
**Long Cardio (schedIdx 5)**: `long_card`, `adv2`
**Rest (schedIdx 6)**: `rest_walk`, `mob_full`

## OG Methodology (Overcoming Gravity — Steven Low)

**6 movement patterns**: H-Push, V-Push, H-Pull, V-Pull, Core, Legs
**Session order (CNS-fresh)**: Skill → Strength → Accessory → Core → Prehab
**Progression standard**: 3×8 clean reps at current level → advance variation
**Rep ranges**: 1-5 max strength / 5-8 strength / 8-12 hypertrophy / 12-20 endurance
**Volume**: 25–50 quality reps per pattern per session, 2×/week per pattern
**Key principle**: Tendons adapt 3-10× slower than muscles — progress conservatively
**Straight-arm vs bent-arm**: Don't exhaust bent-arm before straight-arm skill work

## Marko's Progression Levels (start of sabbatical)

| Pattern | Starting Level | Target (Wk9+) |
|---------|---------------|----------------|
| H-Push | Ring push-ups | Ring dips |
| V-Push | Elevated pike push-up | Wall HSPU |
| H-Pull | Horizontal ring row | Archer row |
| V-Pull | Pull-up 5×5 | L-sit pull-up / archer |
| Core | Hollow body hold | L-sit on bars |
| Legs | Bulgarian split squat → box pistol | Full pistol squat |
| Hamstring | Nordic curl negatives 3×3-5 | Full nordic curl |

## Marko's Fitness Baseline (Oct 2024 – Apr 2026)

- **Peak lifts**: Bench 165 lbs, Squat 195 lbs, Leg Press 450 lbs, OHP 110 lbs (machine)
- **Pull-ups**: 5×5 bodyweight — strong vertical pull base
- **Running**: 3–5 mi base at ~9:10/mile, threshold at ~8:36/mile
- **Goal**: Maintain strength + "boundless energy" for physical adventures (hike, bike, swim, climb)
- **Equipment**: yoga mat, elevated surfaces + gymnastics rings, pull-up bar, push-up bars, bands

## AI Coach (Tool Use)

The AI coach uses Claude's tool use to actually modify the plan. Four tools:

1. **`update_schedule`** — Override one day's workout type (`date`, `schedIdx`, `note`)
2. **`log_workout`** — Log note/substitution/completion for a day
3. **`reschedule_week`** — Restructure multiple days at once (`changes[]`, `reason`)
4. **`get_progression_status`** — Read recent sets for a pattern from state

When Claude calls a tool, the app: executes it locally → updates state → saves → re-renders → shows action summary in chat → continues to final text response.

## Supabase Integration

Tables (run SQL in Supabase SQL editor):
```sql
create table workouts (
  id uuid default gen_random_uuid() primary key,
  user_id text not null default 'marko',
  date_key text not null,
  sets jsonb default '{}',
  note text default '',
  completed boolean default false,
  substitution text default '',
  updated_at timestamptz default now(),
  unique(user_id, date_key)
);

create table app_state (
  id uuid default gen_random_uuid() primary key,
  user_id text not null default 'marko',
  key text not null,
  value jsonb,
  unique(user_id, key)
);

-- Enable RLS but allow all for now (single-user app)
alter table workouts enable row level security;
alter table app_state enable row level security;
create policy "allow_all" on workouts for all using (true);
create policy "allow_all" on app_state for all using (true);
```

Strategy: localStorage is primary (works offline). Supabase syncs on every save when credentials are set. On load, fetches Supabase state and merges (Supabase wins for workouts, localStorage wins for settings).

User needs to: (1) create free project at supabase.com, (2) run the SQL above, (3) paste Project URL + anon key into Settings tab.

## Garmin Import

Drag-and-drop CSV from connect.garmin.com → Activities → Export to CSV.
Parsed into `state.garminActivities[]` and synced to Supabase `app_state` key `garmin_activities`.
Falls back to `WORKOUT_DATA.garmin_activities` (hardcoded) if no imported data.

## Key Functions

- `loadState()` / `saveState()` — localStorage r/w (+ Supabase sync)
- `getScheduleForDate(d)` — returns SABBATICAL_SCHEDULE entry for a date
- `renderCalendar()` — renders 3-week grid
- `renderTracker(dk)` — renders per-set workout tracker for a date
- `sendMessage()` — AI chat with tool use loop
- `executeTool(name, input)` — executes AI tool calls against state
- `buildActivityTable()` — renders Garmin history table
- `parseGarminCSV(text)` — parses Garmin CSV export

## Dev Workflow

```bash
# Serve locally (accessible on same WiFi network)
./serve.sh

# Always check git status before edits
git status

# After any change: read file, edit, commit
git add sabbatical_coach.html
git commit -m "feat: ..."
git push  # → GitHub Pages auto-deploys
```

## Tech Constraints (DO NOT violate)
- Single HTML file — no build step, no bundler, no npm install
- Vanilla JS only — must work offline on phone
- Chart.js from CDN only
- All JS libs via CDN `<script>` tags only
