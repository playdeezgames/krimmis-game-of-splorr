#+build js
// The thin browser layer. The page owns requestAnimationFrame and calls the exports below.
// All the rules are in package game and all the menu logic is in package ui; this only draws and relays.
package main

import "base:runtime"
import "core:time"
import "krimmis:ui"

s: ui.State

main :: proc() {
	s = ui.new_state(u64(time.now()._nsec), .Title)
}

// Keeps odin.js from ending the program straight after main (see Tech/Odin wasm recipe).
@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	return true
}

// A click or tap, in 320 by 240 screen coordinates.
@(export)
platform_click :: proc "c" (x, y: i32) {
	context = runtime.default_context()
	ui.click(&s, int(x), int(y))
}

// A key, as a ui.Key number.
@(export)
platform_key :: proc "c" (k: i32) {
	context = runtime.default_context()
	ui.key(&s, ui.Key(k))
}

// For QA and screenshots: jump straight to a full screen (the page does this from #eve, #coal, #promotion).
// The reveal then shows a fresh game's numbers.
@(export)
platform_qa_mode :: proc "c" (m: i32) {
	context = runtime.default_context()
	s.mode = ui.Mode(m)
	if s.mode == .Promotion {
		s.g.rung = 1
	}
}

@(export)
platform_frame :: proc "c" (dt: f64) {
	context = runtime.default_context()
	draw_frame(&s)
	free_all(context.temp_allocator)
}
