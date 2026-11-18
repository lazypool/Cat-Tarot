<h1 align="center">Cat-Tarot</h1>

<p align="center">
  <img alt="Godot 4.6" src="https://img.shields.io/badge/Godot-4.6-478cbf?logo=godotengine&logoColor=white">
  <img alt="GDScript" src="https://img.shields.io/badge/GDScript-4.x-355570?logo=godotengine&logoColor=white">
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey">
  <img alt="Status" src="https://img.shields.io/badge/status-complete%20prototype-brightgreen">
  <img alt="Assets" src="https://img.shields.io/badge/assets-GitHub%20Release-blue">
</p>

<p align="center"><em>Twenty-one cards decide how much of yourself you are willing to spend.</em></p>

## Overview

![Gameplay screenshot](docs/screenshot.png)

A single-player 3D tarot roguelike built with Godot 4.6. Rules, controls and balance are in
[`docs/GAMEPLAY.md`](docs/GAMEPLAY.md).

## Requirements

- Godot **4.6** (`godot` on `PATH`)
- Python **3.8+** (asset tooling)
- `gh` CLI (only to publish assets / fetch private releases)

## Getting the assets

Raw assets (`assets/`) and the archives built from them are **not** in Git. They are published as
two equivalent archives on this repository's GitHub Release tagged `assets`
(<https://github.com/GekoLynx-Studio/Cat-Tarot/releases/tag/assets>):

- `assets.zip` — Windows: `Expand-Archive assets.zip -DestinationPath .` (or Extract All)
- `assets.tar.gz` — macOS/Linux: `tar -xzf assets.tar.gz`

Script (all OSes):

```bash
tools/fetch-assets.sh                       # macOS / Linux / Git Bash
powershell -File tools\fetch-assets.ps1     # Windows PowerShell
```

It uses a local bundle if present, otherwise downloads from the release, extracts to `assets/`, and
verifies against the committed `assets.sha256`.

## Run and Tests

Import assets once after fetching them, then run:

```bash
godot --headless --path . --import
godot --path .
```

Debug seed: `godot --path . -- --seed=1234`.

If you pull new assets or scripts and see `No loader found` / `Identifier "..." not declared`,
clear the cache and re-import: `rm -rf .godot && godot --headless --path . --import`.

Tests:

```bash
godot --headless --path . res://tests/rules_test.tscn
godot --headless --path . res://tests/ui_smoke.tscn
godot --headless --path . res://tests/interactions_test.tscn
```

## Project layout

```text
Cat-Tarot/
|-- project.godot
|-- README.md            uniform structure
|-- AGENTS.md            agent/contributor conventions (identical across games)
|-- docs/
|   |-- GAMEPLAY.md      rules, controls, balance
|   `-- screenshot.png   image shown in Overview
|-- assets/              raw assets (git-ignored; restored from the release)
|-- scenes/              main, card_3d, deck_3d, dice_3d, restart_button_3d
|-- scripts/             rules engine, UI, audio, card/dice/deck nodes
|-- tests/               rules, UI smoke, interactions
|-- tools/               asset tooling (assets.py + *.sh / *.ps1)
|-- .githooks/           pre-commit / commit-msg / pre-push
`-- .github/             CI workflow + PR template
```

## Development

- Commit messages follow **Conventional Commits** with a required scope, body and sign-off; see
  `AGENTS.md`.
- Git hooks are enabled via `core.hooksPath=.githooks`; `pre-commit` blocks a stale asset stamp and
  checks `gdformat` when installed.
- **If you change anything under `assets/`:**

```bash
tools/pack-assets.sh
tools/push-assets.sh
git add assets.sha256
git commit -m "chore(assets): update bundle"
```

Never commit `assets/`, `assets.tar.gz` or `assets.zip`. No Git LFS. Every script ships as both a
`*.sh` (Linux/macOS/Git Bash) and a `*.ps1` (Windows PowerShell) wrapper.

## Contributing

- Read `AGENTS.md` first; it is identical in every game repo of this workspace.
- Keep the PR title in Conventional Commits form and follow `.github/pull_request_template.md`.
- If your PR changes assets and you lack write access to this repo, publish the bundle to **your
  fork's** Release tagged `assets` and link it in the PR; the maintainer re-publishes it here.
- AI-assisted forks/PRs are welcome under the same conventions.
