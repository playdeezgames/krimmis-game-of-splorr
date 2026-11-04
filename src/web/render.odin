#+build js
// Draws the menu layer: sprites from the Anvil sheet (src/web/sprites.odin) and boxes for buildings, with
// the Urizen sheet kept for tile dressing. Everything is positioned with the layout procs in package ui, so what is drawn is
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

draw_frame :: proc(s: ^ui.State) {
	switch s.mode {
	case .Title:
		draw_title()
	case .Eve:
		draw_eve(s)
	case .Coal:
		draw_coal(s)
	case .Promotion:
		draw_promotion(s)
	case .Play:
		draw_play(s)
	}
}

draw_play :: proc(s: ^ui.State) {
	clear_screen(BLACK)
	draw_tabs(s)
	draw_hud(s)
	switch s.place {
	case .Mall:
		draw_mall(s)
	case .Neighbourhood:
		draw_neighbourhood(s)
	case .Workshop:
		draw_workshop(s)
	}
	draw_buttons(s)
	draw_log(s)
}

// ---- full screens ----

// A garland of alternating red and green stars along a row.
draw_garland :: proc(y: int) {
	for i in 0 ..< SCREEN_W / (GLYPH_W * 2) {
		draw_text("*", i * GLYPH_W * 2 + 3, y, RED if i % 2 == 0 else GREEN)
	}
}

draw_title :: proc() {
	clear_screen(BLACK)
	draw_garland(8)
	draw_garland(224)
	draw_text_big_centred("KRIMMIS", 34, RED, 5)
	draw_text_centred("The Season of Giving (Giving Up)", 82, GOLD)
	put_sprite(.Player, 112, 96, GREEN, 2)
	put_sprite(.Krimmis, 184, 96, RED, 2)
	draw_text_centred("Welcome to the Mall, elf. It's your first day", 126, WHITE)
	draw_text_centred("as Assistant to the Regional Manager of Joy.", 136, WHITE)
	draw_text_centred("Kris Krinkle is watching. Kris Krinkle", 152, GREY)
	draw_text_centred("is always watching. Your name is on the List.", 162, GREY)
	draw_text_centred("Click or press Enter to clock in", 188, GOLD)
	draw_text_centred("1-3 places  arrows pick  S I G B E act", 206, DIM)
}

draw_eve :: proc(s: ^ui.State) {
	e := s.eve
	clear_screen(0x000010)
	draw_garland(8)
	draw_text_big_centred("KRIMMIS EVE", 24, GOLD, 3)
	draw_text_centred("Kris Krinkle has checked the List. Twice.", 60, WHITE)
	buf: [64]u8
	draw_text_centred(fmt.bprintf(buf[:], "Year %d of service", e.year), 82, GREY)
	draw_text_centred(fmt.bprintf(buf[:], "Your Standing . . . . %d", e.standing), 104, WHITE)
	draw_text_centred(fmt.bprintf(buf[:], "The Nice line . . . . %.0f", e.line), 116, WHITE)
	draw_text_centred(fmt.bprintf(buf[:], "Owed to Krimmis Inc.  %d", e.debt), 128, GOLD)
	draw_text_centred(fmt.bprintf(buf[:], "Neighbours remaining  %d of %d", e.alive, game.NEIGHBOURS), 140, GREY)
	put_sprite(.Krimmis, (SCREEN_W - 36) / 2, 150, RED, 3)
	draw_text_centred("He is ready to read the verdict.", 188, WHITE)
	draw_text_centred("Click or press Enter", 204, GOLD)
	draw_garland(224)
}

draw_coal :: proc(s: ^ui.State) {
	clear_screen(0x180000)
	draw_garland(8)
	draw_text_big_centred("COAL", 28, RED, 6)
	draw_text_centred("You have been moved to the Naughty column.", 84, WHITE)
	draw_text_centred("The Coal Collection will see you now.", 98, WHITE)
	put_sprite(.Coal_Collection, (SCREEN_W - 36) / 2, 108, 0x909090, 3)
	draw_text_centred("Your Debt is forgiven (by the Coal Collection).", 146, GREY)
	draw_text_centred("Merry Krimmis from all of us at Krimmis Inc.", 166, GOLD)
	draw_text_centred("Click or press Enter to clock in again", 196, WHITE)
	draw_garland(224)
}

draw_promotion :: proc(s: ^ui.State) {
	clear_screen(0x001000)
	draw_garland(8)
	draw_text_big_centred("PROMOTED", 24, GOLD, 4)
	draw_text_centred("HEAD ELF", 64, GREEN)
	put_sprite(.Head_Elf, 96, 58, GREEN, 2)
	put_sprite(.Head_Elf, 200, 58, GREEN, 2)
	draw_text_centred("Congratulations. You are Nice. This is your reward:", 88, WHITE)
	draw_text_centred("Kris Krinkle hands you next year's List.", 108, WHITE)
	draw_text_centred("It is longer. Everyone you left on the Nice", 122, GREY)
	draw_text_centred("List is next year's customer. So are you.", 132, GREY)
	buf: [64]u8
	draw_text_centred(fmt.bprintf(buf[:], "Year %d begins. Same Debt, higher quota.", s.g.rung + 1), 150, GOLD)
	draw_text_centred("Your credit limit has been raised!", 162, GREY)
	draw_text_centred("New families have moved in. Please welcome them.", 174, GREY)
	draw_text_centred("Click or press Enter to accept", 196, WHITE)
	draw_garland(224)
}

// Numbers, the 24-door advent calendar and the Standing bar, in three rows under the tabs.
draw_hud :: proc(s: ^ui.State) {
	buf: [64]u8
	draw_text(ui.status_line(s, buf[:]), 4, 20, WHITE)

	// Calendar: 24 doors, 12 px of number in a 13 px pitch.
	for n in 1 ..= game.DAYS {
		x := 4 + (n - 1) * 13
		label: [3]u8
		text := fmt.bprintf(label[:], "%d", n)
		switch ui.door(s, n) {
		case .Opened:
			draw_text(text, x + (12 - len(text) * GLYPH_W) / 2 + 1, 31, 0x303030)
		case .Today:
			fill_rect(i32(x), 29, 12, 11, GOLD)
			draw_text(text, x + (12 - len(text) * GLYPH_W) / 2 + 1, 31, BLACK)
		case .Closed:
			draw_text(text, x + (12 - len(text) * GLYPH_W) / 2 + 1, 31, GREY)
		}
	}

	// Standing bar: filled to your Standing, the tick is today's Nice line.
	bar := ui.standing_bar(s)
	frame := ui.Rect{4, 43, 220, 9}
	draw_box(frame, DIM)
	fill_rect(i32(frame.x + 1), i32(frame.y + 1), i32(f64(frame.w - 2) * bar.fill), i32(frame.h - 2), GREEN if bar.ahead else RED)
	tick := frame.x + 1 + int(f64(frame.w - 2) * bar.mark)
	fill_rect(i32(tick), i32(frame.y - 2), 1, i32(frame.h + 4), GOLD)
	draw_text(ui.standing_text(s, buf[:]), frame.x + frame.w + 6, frame.y + 1, GREEN if bar.ahead else RED)
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
		r := ui.Rect{10 + i * 76, ui.SCENE_TOP, 68, 44}
		draw_box(r, DIM)
		put_sprite(.Storefront, r.x + (r.w - TILE) / 2, r.y + 28, GREY)
		fill_rect(i32(r.x + 1), i32(r.y + 1), i32(r.w - 2), 8, 0x602020 if i % 2 == 0 else 0x206020)
	}
	draw_text("Deck Halls", 14, ui.SCENE_TOP + 16, GREY)
	draw_text("Sweaters", 90, ui.SCENE_TOP + 16, GREY)
	draw_text("Fruitcake", 166, ui.SCENE_TOP + 16, GREY)
	draw_text("Tinsel Dept", 242, ui.SCENE_TOP + 16, GREY)
	// The Company Store counter.
	counter := ui.Rect{10, ui.SCENE_TOP + 52, 150, 62}
	draw_box(counter, GOLD)
	draw_text("COMPANY STORE", counter.x + 8, counter.y + 6, GOLD)
	buf: [48]u8
	draw_text(fmt.bprintf(buf[:], "Price  %d, on card", game.store_price(g.day)), counter.x + 8, counter.y + 22, WHITE)
	draw_text(fmt.bprintf(buf[:], "In stock    %d", g.gifts), counter.x + 8, counter.y + 34, WHITE)
	draw_text(fmt.bprintf(buf[:], "Card  %d of %d", g.debt, game.card_limit(g)), counter.x + 8, counter.y + 48, DIM)
	put_sprite(.Store_Counter, counter.x + counter.w - 16, counter.y + 24, GOLD)
	put_sprite(.Gift if g.gifts == 0 else .Gift_Wrapped, counter.x + counter.w - 16, counter.y + 40, WHITE)
	// The mall Santa.
	put_sprite(.Throne, 226, ui.SCENE_TOP + 52, RED, 3)
	put_sprite(.Krimmis, 226, ui.SCENE_TOP + 52, WHITE, 3)
	put_sprite(.Fountain, 176, ui.SCENE_TOP + 60, CYAN, 2)
	draw_text("Mall Santa", 190, ui.SCENE_TOP + 94, RED)
	draw_text("(queue: 340 children)", 168, ui.SCENE_TOP + 104, DIM)
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
			put_sprite(.Removed, r.x + (r.w - TILE) / 2, r.y + 18, DIM)
			draw_text("gone", r.x + 12, r.y + 32, DIM)
		} else {
			colour: i32 = WHITE
			if n.naughty {
				colour = RED
			}
			fill_rect(i32(roof.x), i32(roof.y), i32(roof.w), i32(roof.h), 0x303060 if !n.naughty else 0x602020)
			draw_box(body, GREY)
			put_sprite(neighbour_sprite(n.role, n.naughty), r.x + (r.w - TILE) / 2, r.y + 20, colour)
			if n.obliged > 0 {
				buf: [8]u8
				draw_text(fmt.bprintf(buf[:], "+%d", n.obliged), r.x + 4, r.y + 32, GOLD)
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
	desk := ui.Rect{10, ui.SCENE_TOP, 300, 112}
	draw_box(desk, GREY)
	draw_text("THE LEDGER", desk.x + 8, desk.y + 8, GOLD)
	buf: [64]u8
	draw_text(fmt.bprintf(buf[:], "You owe Krimmis Inc.   %d of %d", g.debt, game.card_limit(g)), desk.x + 8, desk.y + 26, WHITE)
	draw_text(fmt.bprintf(buf[:], "Interest, each night        %.1f%%", 100 * (game.OWN_INTEREST + game.RUNG_INTEREST * f64(g.rung))), desk.x + 8, desk.y + 38, WHITE)
	draw_text(fmt.bprintf(buf[:], "Gifts wrapped, in stock     %d", g.gifts), desk.x + 8, desk.y + 50, WHITE)
	draw_text(fmt.bprintf(buf[:], "Warnings on file            %d", g.warnings), desk.x + 8, desk.y + 62, WHITE)
	draw_text(fmt.bprintf(buf[:], "Neighbours left             %d of %d", game.alive_count(g), game.NEIGHBOURS), desk.x + 8, desk.y + 74, WHITE)
	if g.rung > 0 {
		draw_text(fmt.bprintf(buf[:], "Head Elf, year %d", g.rung + 1), desk.x + 8, desk.y + 88, GREEN)
	}
	draw_text("The Coal Collection calls every second night.", desk.x + 8, desk.y + 100, DIM)
	put_sprite(.Head_Elf if g.rung > 0 else .Player, desk.x + desk.w - 70, desk.y + 8, GREEN, 2)
	put_sprite(.Management, desk.x + desk.w - 40, desk.y + 8, GOLD, 2)
	put_sprite(.Ledger_Desk, desk.x + desk.w - 70, desk.y + 44, WHITE, 2)
	put_sprite(.Workbench, desk.x + desk.w - 40, desk.y + 44, GREY, 2)
	put_sprite(.Conveyor, desk.x + desk.w - 40, desk.y + 74, GREY)
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

// The event log: the last few lines, the latest message bright and older ones dimmed.
draw_log :: proc(s: ^ui.State) {
	for i in 0 ..< ui.LOG_VISIBLE {
		line := ui.log_line(s, i)
		fresh := i >= ui.LOG_VISIBLE - s.latest
		draw_text(line, 4, 200 + i * 10, WHITE if fresh else DIM)
	}
}
