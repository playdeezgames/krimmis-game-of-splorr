# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State of the repository

Pre-production. The repo contains only `README.md`; there is no code, build system, linter or test suite yet, so there are no commands to document. Update this file when the stack and build/run/test commands are chosen.

## The project

A Christmas-themed game that is never called Christmas: in-fiction it is **Krimmis** (and, by extension, Krimmis-flavoured names for its institutions, figures and rituals). Never write "Christmas" or "Xmas" in player-facing text, code identifiers or filenames; the substitution is part of the joke.

Tone is over-the-top satire of the commercialization and secularization of the holiday. Pile on every cliche (the jolly gift-giver, elves, reindeer, the nativity-adjacent story, carols, mall Santas, shopping frenzy, ugly sweaters, fruitcake, the Grinch-style redemption arc, "the true meaning of the season") and give the central story a sinister twist. The current planning goal is to pick the hook: a recognisable beat from the traditional holiday story with a dark reinterpretation. Design is otherwise open, so do not assume a genre or engine until the user decides.

Hook chosen (November 3, 2026): **the Naughty List is a kill list.** Kris Krinkle ("Saint Krimmis") is a jolly, omniscient gift-giver; the Nice List is a loyalty program and "coal" is the polite word for what happens to the Naughty. The player is a mall-elf middle manager who finds their own name on the Naughty List and has until Krimmis Eve to rank up by informing on neighbours. The economy is "the gift that keeps on taking": presents are tithes that bind the recipient to Krimmis Inc., gifts get more lavish and the debt more literal, and the Elf Workshop is a debtors' prison. Two shelved pitches (the franchised manger, the endless December 24th loop) live in the vault as future game ideas. The vault's `Games/Krimmis of SPLORR!!.md` is the design record; keep it in step with this repo.

## Relationship to the SPLORR!! vault

This is one of the user's SPLORR!! games. Shared conventions live in the sibling Obsidian vault at `/home/yermom/git/bok-of-splorr` (read `splorr/Home.md` first; its "Standing rules" section is authoritative). Points that matter here:

- Game repos follow `Tech/Release standard.md` (`ITCH_DESCRIPTION.md`, `assets/cover.png` at 630x500, `assets/screenshots/`, `devlog/YYYYMMDD/`, `tools/ship.sh` plus a `shippit.sh` wrapper).
- Most SPLORR!! games are Odin compiled to `js_wasm32` (recipe in `Tech/Odin wasm recipe.md`) and default to GitHub Pages. Whether this game uses that stack is not yet decided.
- "push" means `git push`, "ship" means itch.io. Do neither unless told. Anything an agent posts to itch.io must say it was posted by an AI agent.
- When this game gets a note in the vault (`Games/<name>.md`, linked from `Home.md`), keep it in step with this repo.
