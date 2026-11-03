#+build js
// Draws the menu layer. Placeholder art: Urizen tiles for people and boxes for buildings, until the
// Anvil sheet lands. Everything is positioned with the layout procs in package ui, so what is drawn is
// what is clickable.
package main

import "core:fmt"
import "krimmis:game"
import "krimmis:ui"

BLACK :: 0x000000
WHITE :: 0xffffff
GREY :: 0x808080
DIM :: 0x404040
RED :: 0xe04040
GREEN :: 0x60c060
GOLD :: 0xe0c040
CYAN :: 0x60c0e0

PERSON_TILE_COL :: 104 // Urizen: a plain human figure
PERSON_TILE_ROW :: 0

draw_frame :: proc(s: ^ui.State) {
	clear_screen(BLACK)
	draw_tabs(s)
	buf: [96]u8
	draw_text(ui.status_line(s, buf[:]), 4, 20, WHITE)
	draw_text(ui.standing_line(s, buf[:]), 4, 30, GOLD)
	switch s.place {
	case .Mall:
		draw_mall(s)
	case .Neighbourhood:
		draw_neighbourhood(s)
	case .Workshop:
		draw_workshop(s)
	}
	draw_buttons(s)
	draw_message(s)
	if s.mode == .Over {
		fill_rect(40, 90, 240, 50, 0x200000)
		draw_text_centred("C O A L", 98, RED)
		draw_text_centred("The List has spoken. Press Enter.", 116, WHITE)
	}
}

draw_box :: proc(r: ui.Rect, rgb: i32) {
	fill_rect(i32(r.x), i32(r.y), i32(r.w), 1, rgb)
	fill_rect(i32(r.x), i32(r.y + r.h - 1), i32(r.w), 1, rgb)
	fill_rect(i32(r.x), i32(r.y), 1, i32(r.h), rgb)
	fill_rect(i32(r.x + r.w - 1), i32(r.y), 1, i32(r.h), rgb)
}

draw_tabs :: proc(s: ^ui.State) {
	labels := [ui.Place]string {
		.Mall          = "1 Mall",
		.Neighbourhood = "2 Neighbourhood",
		.Workshop      = "3 Workshop",
	}
	for p in ui.Place {
		r := ui.tab_rect(p)
		on := p == s.place
		if on {
			fill_rect(i32(r.x), i32(r.y), i32(r.w), i32(r.h), 0x303030)
		}
		draw_box(r, WHITE if on else DIM)
		draw_text(labels[p], r.x + (r.w - len(labels[p]) * GLYPH_W) / 2, r.y + 3, WHITE if on else GREY)
	}
}

draw_mall :: proc(s: ^ui.State) {
	g := &s.g
	// Storefronts.
	for i in 0 ..< 4 {
		r := ui.Rect{10 + i * 76, 50, 68, 44}
		draw_box(r, DIM)
		fill_rect(i32(r.x + 1), i32(r.y + 1), i32(r.w - 2), 8, 0x602020 if i % 2 == 0 else 0x206020)
	}
	draw_text("Deck Halls", 14, 66, GREY)
	draw_text("Sweaters", 90, 66, GREY)
	draw_text("Fruitcake", 166, 66, GREY)
	draw_text("Tinsel Dept", 242, 66, GREY)
	// The Company Store counter.
	counter := ui.Rect{10, 104, 150, 62}
	draw_box(counter, GOLD)
	draw_text("COMPANY STORE", counter.x + 8, counter.y + 6, GOLD)
	buf: [48]u8
	draw_text(fmt.bprintf(buf[:], "Gift price  %d Coin", game.store_price(g.day)), counter.x + 8, counter.y + 22, WHITE)
	draw_text(fmt.bprintf(buf[:], "In stock    %d", g.gifts), counter.x + 8, counter.y + 34, WHITE)
	draw_text("Billed to future you", counter.x + 8, counter.y + 48, DIM)
	// The mall Santa.
	put_tile(PERSON_TILE_COL, PERSON_TILE_ROW, 220, 126, RED)
	draw_text("Mall Santa", 190, 146, RED)
	draw_text("(queue: 340 children)", 168, 156, DIM)
}

draw_neighbourhood :: proc(s: ^ui.State) {
	g := &s.g
	for i in 0 ..< game.NEIGHBOURS {
		n := g.neighbours[i]
		r := ui.house_rect(i)
		body := ui.Rect{r.x + 2, r.y + 14, r.w - 4, r.h - 28}
		roof := ui.Rect{r.x, r.y + 4, r.w, 10}
		if !n.alive {
			draw_box(body, 0x202020)
			draw_text("gone", r.x + 12, r.y + 24, DIM)
		} else {
			colour: i32 = WHITE
			if n.naughty {
				colour = RED
			}
			fill_rect(i32(roof.x), i32(roof.y), i32(roof.w), i32(roof.h), 0x303060 if !n.naughty else 0x602020)
			draw_box(body, GREY)
			put_tile(PERSON_TILE_COL, PERSON_TILE_ROW, r.x + (r.w - TILE) / 2, r.y + 20, colour)
			if n.debt > 0 {
				buf: [8]u8
				draw_text(fmt.bprintf(buf[:], "d%d", n.debt), r.x + 4, r.y + 32, GOLD)
			}
			for k in 0 ..< n.suspicion {
				fill_rect(i32(r.x + r.w - 8 - k * 5), i32(r.y + 32), 3, 3, CYAN)
			}
		}
		draw_text(ui.name(i), r.x + 4, r.y + r.h - 9, GREY)
		if i == s.selected {
			draw_box(r, GOLD)
		}
	}
}

draw_workshop :: proc(s: ^ui.State) {
	g := &s.g
	desk := ui.Rect{10, 50, 300, 116}
	draw_box(desk, GREY)
	draw_text("THE LEDGER", desk.x + 8, desk.y + 8, GOLD)
	buf: [64]u8
	draw_text(fmt.bprintf(buf[:], "You owe Krimmis Inc.        %d", g.debt), desk.x + 8, desk.y + 26, WHITE)
	draw_text(fmt.bprintf(buf[:], "Interest, each night        %.1f%%", 100 * (game.OWN_INTEREST + game.RUNG_INTEREST * f64(g.rung))), desk.x + 8, desk.y + 38, WHITE)
	draw_text(fmt.bprintf(buf[:], "Gifts wrapped, in stock     %d", g.gifts), desk.x + 8, desk.y + 50, WHITE)
	draw_text(fmt.bprintf(buf[:], "Warnings on file            %d", g.warnings), desk.x + 8, desk.y + 62, WHITE)
	draw_text(fmt.bprintf(buf[:], "Neighbours left             %d of %d", game.alive_count(g), game.NEIGHBOURS), desk.x + 8, desk.y + 74, WHITE)
	if g.rung > 0 {
		draw_text(fmt.bprintf(buf[:], "Head Elf, year %d", g.rung + 1), desk.x + 8, desk.y + 92, GREEN)
	}
	draw_text("The Coal Collection calls every second night.", desk.x + 8, desk.y + 104, DIM)
}

draw_buttons :: proc(s: ^ui.State) {
	bs: [ui.MAX_BUTTONS]ui.Button
	n := ui.buttons(s, &bs)
	for b in bs[:n] {
		colour: i32 = WHITE if b.enabled else DIM
		draw_box(b.rect, colour)
		draw_text(b.label, b.rect.x + (b.rect.w - len(b.label) * GLYPH_W) / 2, b.rect.y + 4, colour)
	}
}

// Up to two lines of 52 characters, split at a space.
draw_message :: proc(s: ^ui.State) {
	text := ui.message(s)
	LINE :: 52
	if len(text) <= LINE {
		draw_text(text, 4, 206, WHITE)
		return
	}
	cut := LINE
	for cut > 0 && text[cut] != ' ' {
		cut -= 1
	}
	if cut == 0 {
		cut = LINE
	}
	draw_text(text[:cut], 4, 206, WHITE)
	draw_text(text[cut:] if text[cut] != ' ' else text[cut + 1:], 4, 218, WHITE)
}
