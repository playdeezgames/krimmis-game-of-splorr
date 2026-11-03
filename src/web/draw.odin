#+build js
// The drawing calls the page implements on a 320 by 240 canvas. Colours are 0xRRGGBB, or NO_TINT to draw
// a tile as it is on the sheet. Text is DINOBYTE (6 by 8 cells, code page 437), tinted at draw time.
package main

foreign import host "env"
@(default_calling_convention = "contextless")
foreign host {
	clear_screen :: proc(rgb: i32) ---
	fill_rect :: proc(x, y, w, h: i32, rgb: i32) ---
	draw_tile :: proc(col, row, x, y: i32, rgb: i32) ---
	draw_glyphs :: proc(text: [^]u8, n: i32, x, y: i32, rgb: i32) ---
	draw_glyphs_scaled :: proc(text: [^]u8, n: i32, x, y: i32, rgb: i32, scale: i32) ---
}

NO_TINT :: -1
SCREEN_W :: 320
SCREEN_H :: 240
TILE :: 12 // Urizen tiles, drawn 1 to 1
GLYPH_W :: 6
GLYPH_H :: 8

draw_text :: proc(s: string, x, y: int, rgb: i32) {
	if len(s) == 0 {
		return
	}
	draw_glyphs(raw_data(s), i32(len(s)), i32(x), i32(y), rgb)
}

// Centres a line of text on the screen.
draw_text_centred :: proc(s: string, y: int, rgb: i32) {
	draw_text(s, (SCREEN_W - len(s) * GLYPH_W) / 2, y, rgb)
}

put_tile :: proc(col, row, x, y: int, rgb: i32) {
	draw_tile(i32(col), i32(row), i32(x), i32(y), rgb)
}

// Big text for titles: whole-number scale, so the pixels stay square.
draw_text_big :: proc(s: string, x, y: int, rgb: i32, scale: int) {
	if len(s) == 0 {
		return
	}
	draw_glyphs_scaled(raw_data(s), i32(len(s)), i32(x), i32(y), rgb, i32(scale))
}

draw_text_big_centred :: proc(s: string, y: int, rgb: i32, scale: int) {
	draw_text_big(s, (SCREEN_W - len(s) * GLYPH_W * scale) / 2, y, rgb, scale)
}
