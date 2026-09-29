# Monkey Bananas

> An absurdist idle game: a troop of monkeys builds a civilization whose only purpose is more
> bananas. Tap, recruit, automate, evolve, repeat.

**Play:** https://monkey-bananas.vercel.app (web). iOS and Android builds come from the same
Godot project.

## What it is

You tap the Big Banana, hire a troop (interns, trees, hard-hat crews, bureaucrats, catapults, a
space program, a time-traveling chimp, the Banana Moon) and Evolve when the troop is ready. Each
Evolve trades the run for Opposable Thumbs, which multiply everything forever and buy Thumb
Perks: auto-tapping, a butler that buys for you, a net for Golden Bananas, longer naps.

Along the way:
- **Milestones:** each tier doubles its output at 25, 50, 100, 200 and 300 owned.
- **Troop Morale:** 41 trophies raise production.
- **Four eras:** Jungle, Banana Village, Peel City and Banana Orbit, with the diorama and music changing as the species evolves.
- **CHIP:** a monkey news anchor who hosts the ticker and tells the story one Evolve at a time.

Every sprite, glyph, sound effect and music stem is generated from code. There are no drawn or
recorded asset files.

## Stack

Godot 4.7.2 with typed GDScript, on the Mobile renderer, portrait. The rules are a pure
simulation (`game/scripts/sim/`) covered by headless tests and a pacing bench. The toolchain
(tests, web, Android, iOS) lives in `tools/`. See [`HOW-TO-RUN.md`](HOW-TO-RUN.md).

v1.1 was a Phaser 4 web game; it is preserved at the `v1.1-phaser` tag. The engine-agnostic
specs it was built from (`design/`, `ux/`, `motion/`, `audio/`, `art/`, `pipeline/`) remain
the source of truth for v2. Why the move: [`decisions/0001`](decisions/0001-2026-09-28-godot-mobile-v2.md).
