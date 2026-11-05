# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Odin at `/home/yermom/.local/bin/odin` (override with `ODIN=`). Run from anywhere:

```bash
tools/test.sh                     # native tests of src/game and src/ui
tools/build.sh                    # js_wasm32 build into build/web (OPT=size for the small build)
python3 -m http.server -d build/web 8000   # the wasm must be served over http, not file://
tools/pages.sh                    # test + size build copied into docs/ for GitHub Pages; never commits or pushes
tools/balance_sim.py              # python3; Monte Carlo of the economy (numbers tuned there, recorded in the vault note)
```

Run a single test with `odin test src/game -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_NAMES=game.new_game_starts_on_day_one`. Port 8765 is often taken by another SPLORR!! game's server; check the page title.

## Architecture

Four layers, as in JetLag and the other SPLORR!! web games:

- `src/game` (package `game`): all rules, **no browser imports**, so it builds and tests natively. Test files carry `#+build !js`.
- `src/ui` (package `ui`): the menu layer, also pure and natively tested: current place, selection, the last message, the button and house layout (`buttons`, `house_rect`, `tab_rect`), and `click`/`key` turning input into game actions. A button is drawn where it is hit-tested because both use these layout procs. Player-facing wording for events lives here.\n- `src/web` (package `main`, `#+build js`): the thin wasm layer. It exports `proc "c"` functions (`platform_click`, `platform_key`, `platform_frame`) and a `step` that only keeps `odin.js` alive, and `render.odin` draws the ui state with the shim in `draw.odin`. Packages are imported as `krimmis:game` and `krimmis:ui` (build passes `-collection:krimmis=src`).
- `web/index.html`: owns the canvas, input and (later) sound; it calls the exports through `memory.exports`. It carries the release-standard footer (itch.io and more-games back links, AI disclosure). Keep the `KEY` table in the page in step with `ui.Key`, and the `#title/#play/#eve/#coal/#promotion/#briefing` QA list with `ui.Mode` order (Briefing, the how-to-play screen after the title, is last so the others keep their numbers; its text is `ui.BRIEFING`, and `ui.place_hint` is said on arriving in a place) (open `index.html?x=1#coal` with a fresh `?x=` to jump to a full screen). Tiles are tinted with multiply (white figures on an opaque ground), the font with source-in.

Built so far (`parity_test.odin` plays the sim's four bot policies against the real rules and fails if win rates drift from `tools/balance_sim.py`; after any rules or tuning change, change the sim to match and update its reference numbers): the calendar, the state (resources, 12 neighbours), a seeded xoshiro RNG (`rng.odin`, so runs are reproducible per seed) and `tuning.odin`, the single block of balance constants that mirrors `tools/balance_sim.py` (change both together). The 12 neighbours' names, traits and lines are in `roster.odin` (the vault note has the same text; never use the forbidden word or brand names there); nosy/oblivious traits set how many misses a neighbour takes to report you, a backfired Report leaves a grudge, and `night.odin` rolls one random event a night (audit, tip-off, Santa sighting; never on Eve). When the Coal Collection calls and nobody is Naughty, the quota is filled anyway: the street names you (if you are behind the line, `QUOTA_YOU_CHANCE`) or a clean neighbour; the `KNOCK_LIMIT`th knock in a year is coal on the spot (`Night_Report.coal`, `ui.State.knocked_out`). The ui says every number the night moved, and the Eve and coal screens hold input for `ui.HOLD_SECONDS` (`ui.tick` from `platform_frame`). Player actions are in `actions.odin` (each returns an `Event` for the UI and sound; refusals cost nothing). The night reckoning (`night.odin`, `end_day` returns a `Night_Report`; the night of day 24 runs and sets `eve_reached`) matches the order in `tools/balance_sim.py`. `eve.odin` resolves Krimmis Eve (`resolve_eve`: coal ends the run, promotion restarts the loop one rung up with the Debt carried over); rung scaling numbers live in `tuning.odin` and the sim. Build the next tasks from Coxswain, in the order the vault note's core loop gives.

## The project

A Christmas-themed game that is never called Christmas: in-fiction it is **Krimmis** (and, by extension, Krimmis-flavoured names for its institutions, figures and rituals). Never write "Christmas" or "Xmas" in player-facing text, code identifiers or filenames; the substitution is part of the joke.

Tone is over-the-top satire of the commercialization and secularization of the holiday. Pile on every cliche (the jolly gift-giver, elves, reindeer, the nativity-adjacent story, carols, mall Santas, shopping frenzy, ugly sweaters, fruitcake, the Grinch-style redemption arc, "the true meaning of the season") and give the central story a sinister twist.

Stack (November 3, 2026): Odin compiled to `js_wasm32`, assets made with the Anvil (`mcp__anvil-prod__*` tools), tasks tracked in Coxswain (project `krimmis`; pass an `agent` name on task changes). Follow the vault's `Tech/Release standard.md`: GitHub Pages first, no itch.io material until the user decides. **The core game loop is approved; build only the tasks Coxswain unblocks** (loop approved November 3, 2026, Coxswain task 379; spec in the vault game note).

Hook chosen (November 3, 2026): **the Naughty List is a kill list.** Kris Krinkle ("Saint Krimmis") is a jolly, omniscient gift-giver; the Nice List is a loyalty program and "coal" is the polite word for what happens to the Naughty. The player is a mall-elf middle manager who finds their own name on the Naughty List and has until Krimmis Eve to rank up by informing on neighbours. The economy is "the gift that keeps on taking": presents are bought on the Company Store card (your own Debt, up to a card limit) and oblige the recipient, who returns the favour in Coin each night while Krimmis Inc. takes half, gifts get more lavish and the debt more literal, and the Elf Workshop is a debtors' prison. Two shelved pitches (the franchised manger, the endless December 24th loop) live in the vault as future game ideas. The vault's `Games/Krimmis of SPLORR!!.md` is the design record; keep it in step with this repo.

## Relationship to the SPLORR!! vault

This is one of the user's SPLORR!! games. Shared conventions live in the sibling Obsidian vault at `/home/yermom/git/bok-of-splorr` (read `splorr/Home.md` first; its "Standing rules" section is authoritative). Points that matter here:

- Game repos follow `Tech/Release standard.md` (`ITCH_DESCRIPTION.md`, `assets/cover.png` at 630x500, `assets/screenshots/`, `devlog/YYYYMMDD/`, `tools/ship.sh` plus a `shippit.sh` wrapper).
- Most SPLORR!! games are Odin compiled to `js_wasm32` (recipe in `Tech/Odin wasm recipe.md`) and default to GitHub Pages. Whether this game uses that stack is not yet decided.
- "push" means `git push`, "ship" means itch.io. Do neither unless told. Anything an agent posts to itch.io must say it was posted by an AI agent.
- When this game gets a note in the vault (`Games/<name>.md`, linked from `Home.md`), keep it in step with this repo.

Sprites: `assets/krimmis.world.json` is the Anvil world (tileset `krimmis`, 56 12 px images, palette 0 black, 1 white); `python3 tools/sheet.py` turns it into `assets/krimmis.png` (Urizen layout, 14 tiles a row) and `assets/krimmis.index` (name col row). `src/web/sprites.odin` is generated by the same script (the `Sprite` enum in world order; `neighbour_sprite` relies on each neighbour being followed by its `_naughty`). One shared `removed` tile serves all twelve neighbours; Naughty variants are `<name>_naughty`. Licences are in `assets/LICENSES.md`.

Sounds: the 17 sounds are PLAY text inside the same Anvil world; wavs in `assets/sfx/` are exports (`sound_export`), and `tools/build.sh` copies them to `build/web/sfx/`. The ui layer queues a `ui.Sound` per event (`next_sound`; refusals play the low blip), `platform_sound` hands them to the page one at a time and `platform_mode` lets it loop the title tune; keep `SOUNDS` in `web/index.html` in step with the `ui.Sound` order. The audio context starts on the first click or key (browser rule), so the very first title screen is silent; `M` mutes.
