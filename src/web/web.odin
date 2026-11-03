#+build js
// The thin browser layer. The page owns requestAnimationFrame and calls the exports below.
// Everything with rules in it is in package game.
package main

import "base:runtime"
import "core:fmt"
import "core:time"
import "krimmis:game"

g: game.Game

main :: proc() {
	g = game.new_game(u64(time.now()._nsec))
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
	return !game.end_day(&g).refused
}

// Placeholder screen that proves the shim: title, calendar, one Urizen tile. Replaced by the scenes task.
@(export)
platform_frame :: proc "c" (dt: f64) {
	context = runtime.default_context()
	clear_screen(0x000000)
	draw_text_centred("K R I M M I S", 90, 0xffffff)
	buf: [32]u8
	line := fmt.bprintf(buf[:], "Day %d of %d", g.day, game.DAYS)
	draw_text_centred(line, 110, 0xc0c0c0)
	draw_tile(104, 0, (SCREEN_W - TILE) / 2, 130, NO_TINT)
	draw_text_centred("tap to end the day", 160, 0x808080)
}
