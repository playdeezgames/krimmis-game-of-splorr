#+build js
// The thin browser layer. The page owns requestAnimationFrame and calls the exports below.
// Everything with rules in it is in package game.
package main

import "base:runtime"
import "krimmis:game"

g: game.Game

main :: proc() {
	g = game.new_game()
}

// Keeps odin.js from ending the program straight after main (see Tech/Odin wasm recipe).
@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	return true
}

@(export)
platform_day :: proc "c" () -> i32 {
	return i32(g.day)
}

@(export)
platform_end_day :: proc "c" () -> bool {
	context = runtime.default_context()
	return game.end_day(&g)
}
