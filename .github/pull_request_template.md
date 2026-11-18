## Summary

<!-- What changed and why. Keep the PR title in Conventional Commits form, e.g. feat(cards): add shuffle. -->

## Checklist

- [ ] PR title uses Conventional Commits (`feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`)
- [ ] If `assets/` changed: ran `tools/pack-assets.sh`, then `tools/push-assets.sh`, and committed the updated `assets.sha256`
- [ ] If opened from a fork without write access: published the bundle to **your fork's** Release tagged `assets` and linked it in the Summary (the maintainer re-publishes it to this repo's Release)
- [ ] `python tools/assets.py check` passes locally (or `tools/check-assets` on Windows)
- [ ] `assets.sha256` is committed; `assets/`, `assets.tar.gz`, `assets.zip` are **not** committed
- [ ] GDScript is formatted (`gdformat scripts tests`) and `gdlint scripts tests` is clean
- [ ] README keeps the fixed H2 structure and documents asset download / extract / install
- [ ] README title is centered with >= 4 badges, an italic one-line hook, and a screenshot in Overview
- [ ] Gameplay (rules, controls, balance) is in `docs/GAMEPLAY.md`, **not** the README
- [ ] `AGENTS.md` is unchanged (it is identical in every game repo)
- [ ] Tested on: <Linux | macOS | Windows>

## Notes for reviewers

<!-- Anything that needs a second look. -->
