# Gameplay — Cat-Tarot

> Rules, controls, walkthroughs and balance. Kept out of the README on purpose.

# Cat-Tarot

A single-player semi-top-down 3D tarot roguelike for Godot 4.x. One run is a
linear sequence of 21 card choices. The UI is bilingual (简体中文 / English; the
language is set in `Loc`, with no in-game toggle) and uses the supplied cute font
`乐米栀夏浅风体`.

The current rule set is the four-stat "Cat's Scales" version. There are no acts,
no Will/HP/Intuition/Debt resources, no debt settlement, and no active mark
buttons.

## Run

Assets are not stored in git (see [Getting the assets](#getting-the-assets)). After cloning,
restore them once:

```bash
tools/fetch-assets.sh          # macOS / Linux / Git Bash
powershell -File tools\fetch-assets.ps1   # Windows PowerShell
```

Then, from this folder:

```bash
godot --path .
```

From the workspace root:

```bash
godot --path games/Cat-Tarot
```

Debug seed:

```bash
godot --path . -- --seed=1234
```

The tabletop restart button starts a new random run. `R` restarts with the
command-line seed.

## Four stats

All four stats start at **4**. The safe range is **1-9**. If any stat becomes
`<= 0` or `>= 10`, the run ends immediately.

- 热情 / Passion (fire icon)
- 直觉 / Intuition (eye icon)
- 好奇 / Curiosity (star icon)
- 安逸 / Comfort (leaf icon)

The top bar contains only the cat avatar and the four stats, each with a value
and a small bar. Values near a boundary are highlighted. There is no progress
counter, phase label, or language toggle. Negative stat deltas are displayed as `- 1`
(minus-one delta) and are never clamped to a minimum of 1.

Die-face costs:

| Face | Gain | Loss |
|:---:|------|------|
| 1 | Passion | Intuition |
| 2 | Intuition | Passion |
| 3 | Curiosity | Comfort |
| 4 | Comfort | Curiosity |
| 5 | Passion | Comfort |
| 6 | Curiosity | Intuition |

## Controls

- Three cards are always on the table. Click any non-empty card to select it.
  The selection is never locked; click another card at any time before
  accepting/refusing.
- Click the 3D die in the bottom-right to roll. There is no roll button and no
  need to select a card first. Each face has its own tradeoff: one stat `+1` and
  one stat `-1`. The current face's two colored stat icons (`+ 1` / `- 1`) are
  rendered as a large flat label on the table directly centered above the die,
  as part of it. The die result applies to every field card at once.
- Every field card is always UPRIGHT or REVERSED, including cards that are not
  selected. There is no unrolled state. A card's pip table maps the current die
  face to its orientation; both sets cover 1-6 and never overlap (checked by
  tests).
- Reversed cards are shown upside down. There are no orientation, die-number, or
  pip-number labels on the cards.
- The action pair is part of the selected card: 3D tick/cross icons and their
  effect previews sit just below the card surface and move with it. Hovering
  tints the tick green or the cross red, with no hover text. The effect text is
  slightly larger than the mark description, uses colored stat icons, and writes
  signed values with a space (`+ 1` / `- 1`).
- The tick applies the selected card's accept row, then checks death and gains
  the mark. The cross applies its refuse row, checks death, and gives no mark.
- Marks are shown as a large, upright 3D card fan along the bottom edge. The
  cards fan naturally, with staggered heights and staggered depth on the z axis,
  and cast no shadows, so they can overlap cleanly without crossing through one
  another or creating dark seams. Marks are never shown in a sidebar, have no
  mouse tooltip, and there is no in-game log. Hovering a hand card shows its
  effect text at the top, just like a table card.
- Each table card writes its mark effect at the top of the card, with stat words
  replaced by their colored icons and signed values spaced as `+ 1` / `- 1`;
  hand cards stay clean until hovered.

## Linear 21-choice flow

The opening deal puts 3 cards on the table one at a time; the deck has 18 cards.
The World does not enter the deck. The die starts on a random face, so the
opening cards already show the orientations for that face.

1. Click the die whenever you want; all field cards update to that die face.
2. Select any non-empty field card.
3. Accept or refuse. Effects apply immediately; check death after every stat
   change.
4. The chosen card animates out first. An accepted card with a free hand slot
   flies into the hand after the existing hand cards first shift to open its
   slot. If the hand is full, the accepted card stays completely still in its
   original slot while the whole hand lifts slightly; after the chosen hand card
   drops, the remaining hand cards shift to open the new slot, then the waiting
   card flies in. A card from the left table slot enters from the left, a right
   card from the right, and a middle card from the middle. Refused cards leave
   the screen. After that, the replacement card travels from the deck into the
   vacated slot with the current die face. All moves use slow sine easing.
5. `choicesCompleted` increases. After 21 choices, the World appears and the run
   ends directly (no final Judgement check or payment).

### Death

If any stat reaches `<= 0` or `>= 10`, the run ends immediately. There is no
inheritance, no stat reset, and no mark loss. No end panel appears; the restart
button on the table lights up with a pulsing halo instead.

The d6/pip rolls are seeded. The final-trial missing-mark rule is intentionally
skipped in this build.

### Marks and triggers

Marks are held in the large, upright 3D card fan at the bottom edge (maximum 5). The fan opens upward: the top arc is wider and the bottom is narrower.
Table cards show their mark effect text at the top; hand cards show it only on
hover. When the hand is full, accepting a card makes the player click an existing
hand card to replace it directly; there is no discard option and no replacement
modal. The new mark's `when_accept`/`when_refuse` effects do not trigger on the
acquisition choice; its `on_acquire` effects do. Existing marks' accept/refuse
effects trigger in acquisition order. Every 3 completed choices, every `every_3`
mark effect triggers in acquisition order.

The full 21-card / 42-orientation data is in `scripts/card_database.gd`. It
contains:

- per-card upright and reversed pip sets;
- accept and refuse stat deltas;
- structured mark effects: `timing`, optional `condition`, `action`, `limit`;
- localized effect text.

Supported structured timings: `on_acquire`, `when_accept`, `when_refuse`,
`every_3`, `once_per_run`, `final`. The `final` timing is stored but not executed
because the current build ends at the World without the final trial.

The engine interprets these structures in `GameManager`; it never evaluates
natural-language text. All current effects resolve deterministically, without a
stat-choice modal. Tower upright centers all stats at 5; Tower reversed shifts
the highest stat `-2` and the lowest stat `+2`.
- Judgement final: stored but skipped (World ends the run).
- The Sun's all-stat changes use `apply_stat_delta` for every stat.

### Emperor

The Emperor mark is a special once-per-run interception: when a stat change would
make any stat `<= 0` or `>= 10`, it is clamped to 1 or 9. A reversed Emperor then
also applies Intuition -1. The interception does not apply to the final check
because the final trial is currently skipped.

## Final World

After 21 choices, The World card is drawn from the deck with the normal draw and
entry animation; once it leaves the pile, the draw pile disappears. The run then
ends directly. This is an intentional simplification: the final interpretation /
Judgement check / missing mark payment is not executed in this build. No end
panel appears; the tabletop restart button lights up with a pulsing halo.

## Assets and icons

- Card art is under `assets/cards/` as 1024px-wide WebP, with original supplied
  file names preserved. The original 1664x2880 PNGs are archived outside git in
  the `assets-source-v1` GitHub Release.
- Icons are from the supplied `no-padding` pack in `assets/icons/`.
- The UI and 3D label typography use a tiered handwriting stack managed by
  `scripts/ui_fonts.gd`: `assets/fonts/yozai_latin_symbols.ttf` (Tier 1 Latin,
  digits, `-`, `→`, math symbols; SIL OFL 1.1 subset),
  `assets/fonts/lemi_zhixia_qianfeng.ttf` (Tier 2 primary Chinese characters and
  punctuation), and `assets/fonts/yozai_regular.ttf` (Tier 3 full Yozai CJK and
  symbol fallback, SIL OFL 1.1).
- The 3D die is exported from the supplied `DiceLowPoly.blend` to
  `assets/models/dice_low_poly.glb`.
- Card and dice sounds are under `assets/audio/sfx/`, converted from the supplied
  tabletop sound pack to 16-bit PCM so Godot can import them.
- The looping background track is `assets/audio/music/tarot_ambience.ogg`, an
  original ambient piece composed for this project.
- Source/license notes are in `assets/LICENSES.md`.

### Getting the assets

Raw assets are not in git. Two equivalent archives live on the
[`assets` release](https://github.com/GekoLynx-Studio/Cat-Tarot/releases/tag/assets):

- `assets.zip` — Windows: `Expand-Archive assets.zip -DestinationPath .` (or Extract All)
- `assets.tar.gz` — macOS/Linux: `tar -xzf assets.tar.gz`

Script (all OSes; needs Python 3.8+, uses `gh` for private repos):

```bash
tools/fetch-assets.sh                       # macOS / Linux / Git Bash
powershell -File tools\fetch-assets.ps1     # Windows PowerShell
```

It uses a local `assets.tar.gz`/`assets.zip` if present, otherwise downloads from
the release, extracts to `assets/`, and verifies against the committed
`assets.sha256`.

### Asset workflow

No Git LFS. `assets/`, `assets.tar.gz` and `assets.zip` are git-ignored; only the
tiny `assets.sha256` is committed.

- After changing anything under `assets/`: run `tools/pack-assets.sh`, then
  `tools/push-assets.sh`, then commit the updated `assets.sha256`.
- The `pre-commit` hook blocks a commit when `assets/` no longer matches the stamp.
- Keep each resource and its `.import` file coherent, and run
  `godot --headless --path . --import` before committing so import metadata is
  normalized.
- Rename or move assets inside the Godot editor, never from the file manager.

Stat icon mapping: fire = Passion, eye = Intuition, star = Curiosity, leaf =
Comfort. Effects use signed numbers; positive and negative deltas use green/red
values, while the stat icon keeps the stat color.

## Audio

`Audio` (autoload in `scripts/audio_manager.gd`) creates dedicated `Music` and
`SFX` buses at runtime. Card draws, flips, taps, discards, hand placement, die
rolls, and the World reveal each use a tabletop sound effect with slight random
pitch variation. The 64-second ambient loop fades in when a run
starts and restarts with every new run. `Audio.play_sfx(key, volume_db, pitch)`
is the only call sites need; unknown keys are ignored so a missing asset cannot
break gameplay.

## Project structure

```text
Cat-Tarot/
|-- project.godot
|-- README.md
|-- .gitattributes            line-ending rules (no LFS)
|-- assets/
|   |-- cards/                 optimized WebP card art
|   |-- icons/                 supplied no-padding icons
|   |-- fonts/                 tiered Lemi + Yozai handwriting fonts and OFL license
|   |-- models/                GLB die + original blend source
|   |-- audio/
|   |   |-- sfx/               card, deck, and dice WAV effects
|   |   `-- music/             looping ambient background track
|   `-- LICENSES.md
|-- scenes/
|   |-- main.tscn              table, camera, die, draw pile, UI layer
|   |-- card_3d.tscn           flat card + 3D effect/action overlays
|   |-- dice_3d.tscn           low-poly 3D die
|   |-- restart_button_3d.tscn tabletop restart button + halo
|   `-- deck_3d.tscn           22-card draw pile and flip source
|-- scripts/
|   |-- card_database.gd       structured 21-card data
|   |-- game_manager.gd        four-stat linear rules engine
|   |-- loc.gd                 bilingual UI text
|   |-- card_3d.gd             texture, hover, selection, reversal, effect/action overlays
|   |-- dice_3d.gd             d6 face and tumble animation
|   |-- deck_3d.gd             stacking, height, and drawn-card positions
|   |-- ui_fonts.gd            tiered font fallback stack and typographic scale
|   |-- ui_manager.gd          cat avatar + four-stat HUD
|   |-- restart_button_3d.gd   tabletop restart button and game-over halo
|   |-- audio_manager.gd       Music/SFX buses, one-shot pool, looping BGM
|   `-- main.gd                3D field/hand cards, die clicks, world card
`-- tests/
    |-- test_rules.gd
    |-- test_ui_smoke.gd
    |-- test_interactions.gd
    |-- rules_test.tscn
    |-- ui_smoke.tscn
    `-- interactions_test.tscn
```

## Tests

```bash
godot --headless --path . --import
godot --headless --path . res://tests/rules_test.tscn
godot --headless --path . res://tests/ui_smoke.tscn
godot --headless --path . res://tests/interactions_test.tscn
```

Test coverage includes:

- initial four stats, opening field, deck, World exclusion;
- pip integrity: every card's upright + reversed sets cover 1-6 and are disjoint;
- die rolls with no selection, whole-field orientation updates, rerolls, and the
  per-face `+1` / `-1` roll tradeoff;
- switching selections without clearing results;
- accept/refuse immediate effects and no mark on refuse;
- mark on-acquire effects (including Tower's automatic extreme shift);
- every-3 mark triggers;
- direct death with no inheritance;
- Emperor interception (upright and reversed);
- full-hand replacement chosen directly from the 3D hand;
- structured effect data checks and stat icons in card effect text;
- the full 21-choice split flow, unique cards, empty deck/field, World draw
  animation, hidden draw pile, and World end;
- card-attached 3D action icons and effects, sequential exit/entry animations,
  hand hover effects, and the 3D mark hand;
- all card/dice sounds and the looping background track loading at startup;
- the tabletop restart button, the death/world-end halo, and the World card
  clearing on a new run.

## Known simplifications

- The World ends the run directly; the final Judgement/interpretation and
  missing-mark payment are not implemented in this build.
- A card's highest/lowest condition uses fixed stat order for ties.
- Strength reversed's once-per-run low-stat boost targets the lowest stat with the
  same fixed tie order.
- No save/load or export preset is included.
- The card art keeps its printed English titles; localized names are used in the
  remaining UI text.
- Source card filenames are preserved as supplied, including spaces.
