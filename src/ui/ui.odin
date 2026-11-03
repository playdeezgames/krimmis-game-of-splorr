// The menu layer: which place you are in, who is selected, what the last thing that happened was, and how
// clicks, taps and keys turn into game actions. No drawing and no browser imports, so it tests natively;
// src/web draws from this state and the layout procs here, so a button is drawn where it is hit-tested.
package ui

import "core:fmt"
import "krimmis:game"

SCREEN_W :: 320
SCREEN_H :: 240

Place :: enum {
	Mall,
	Neighbourhood,
	Workshop,
}

Mode :: enum {
	Play,
	Over, // coal: Enter starts again (the Eve screens task replaces this with proper screens)
}

Action :: enum {
	Surveil,
	Inform,
	Gift,
	Buy,
	End_Day,
}

// Keys, as numbers the page sends. Keep in step with KEYS in web/index.html.
Key :: enum {
	None,
	Place_1,
	Place_2,
	Place_3,
	Left,
	Right,
	Up,
	Down,
	Surveil,
	Inform,
	Gift,
	Buy,
	End_Day,
	Confirm,
}

MESSAGE_CAP :: 104
LOG_VISIBLE :: 4 // lines of event log on screen
LOG_WIDTH :: 52 // characters per line

Log_Line :: struct {
	text: [LOG_WIDTH]u8,
	n:    int,
}

State :: struct {
	g:        game.Game,
	seed:     u64,
	place:    Place,
	selected: int, // neighbour index, or -1
	mode:     Mode,
	message:  [MESSAGE_CAP]u8, // the latest message, whole
	msg_len:  int,
	log:      [LOG_VISIBLE]Log_Line, // the latest messages wrapped into lines, newest at the bottom
	latest:   int, // how many of the bottom lines belong to the latest message
}

new_state :: proc(seed: u64) -> State {
	s := State {
		g        = game.new_game(seed),
		seed     = seed,
		place    = .Neighbourhood,
		selected = -1,
	}
	say(&s, "Welcome to Krimmis, elf. Your name is on the List.")
	return s
}

message :: proc(s: ^State) -> string {
	return string(s.message[:s.msg_len])
}

@(private)
say :: proc(s: ^State, text: string) {
	s.msg_len = copy(s.message[:], text)
	push_log(s, string(s.message[:s.msg_len]))
}

// Adds a message to the event log, wrapping at spaces so a line is at most LOG_WIDTH characters.
@(private)
push_log :: proc(s: ^State, text: string) {
	rest := text
	s.latest = 0
	for len(rest) > 0 {
		cut := len(rest)
		if cut > LOG_WIDTH {
			cut = LOG_WIDTH
			for cut > 0 && rest[cut] != ' ' {
				cut -= 1
			}
			if cut == 0 {
				cut = LOG_WIDTH
			}
		}
		for i in 0 ..< LOG_VISIBLE - 1 {
			s.log[i] = s.log[i + 1]
		}
		line: Log_Line
		line.n = copy(line.text[:], rest[:cut])
		s.log[LOG_VISIBLE - 1] = line
		s.latest = min(s.latest + 1, LOG_VISIBLE)
		rest = rest[cut:]
		for len(rest) > 0 && rest[0] == ' ' {
			rest = rest[1:]
		}
	}
}

log_line :: proc(s: ^State, i: int) -> string {
	return string(s.log[i].text[:s.log[i].n])
}

@(private)
sayf :: proc(s: ^State, format: string, args: ..any) {
	s.msg_len = len(fmt.bprintf(s.message[:], format, ..args))
	push_log(s, string(s.message[:s.msg_len]))
}

// ---- layout -------------------------------------------------------------------------------------------

Rect :: struct {
	x, y, w, h: int,
}

Button :: struct {
	rect:    Rect,
	label:   string,
	action:  Action,
	enabled: bool,
}

MAX_BUTTONS :: 5
SCENE_TOP :: 58 // the scenes start below the HUD
HOUSE_COLUMNS :: 6

tab_rect :: proc(p: Place) -> Rect {
	return Rect{4 + int(p) * 104, 2, 100, 14}
}

house_rect :: proc(i: int) -> Rect {
	return Rect{10 + (i % HOUSE_COLUMNS) * 51, SCENE_TOP + (i / HOUSE_COLUMNS) * 60, 48, 54}
}

BUTTON_Y :: 178
BUTTON_H :: 16

in_rect :: proc(r: Rect, x, y: int) -> bool {
	return x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h
}

// The buttons on screen for the current place, with whether each would do anything right now.
buttons :: proc(s: ^State, out: ^[MAX_BUTTONS]Button) -> int {
	n := 0
	add :: proc(out: ^[MAX_BUTTONS]Button, n: ^int, x: int, w: int, label: string, a: Action, enabled: bool) {
		out[n^] = Button{Rect{x, BUTTON_Y, w, BUTTON_H}, label, a, enabled}
		n^ += 1
	}
	g := &s.g
	playing := s.mode == .Play
	target := playing && s.place == .Neighbourhood && target_ok(g, s.selected)
	switch s.place {
	case .Neighbourhood:
		add(out, &n, 4, 64, "Surveil", .Surveil, target && g.actions > 0)
		add(out, &n, 72, 64, "Inform", .Inform, target && g.actions > 0 && g.dirt >= game.INFORM_COST_LOW)
		add(out, &n, 140, 64, "Gift", .Gift, target && g.actions > 0 && g.gifts > 0)
	case .Mall:
		add(out, &n, 4, 100, "Buy a gift", .Buy, playing && g.coin >= game.store_price(g.day))
	case .Workshop:
	}
	add(out, &n, 236, 80, "End day", .End_Day, playing)
	return n
}

@(private)
target_ok :: proc(g: ^game.Game, i: int) -> bool {
	return i >= 0 && i < game.NEIGHBOURS && g.neighbours[i].alive && !g.neighbours[i].naughty
}

// ---- input --------------------------------------------------------------------------------------------

// A click or tap at a point on the 320 by 240 screen.
click :: proc(s: ^State, x, y: int) {
	if s.mode == .Over {
		restart(s)
		return
	}
	for p in Place {
		if in_rect(tab_rect(p), x, y) {
			s.place = p
			return
		}
	}
	if s.place == .Neighbourhood {
		for i in 0 ..< game.NEIGHBOURS {
			if in_rect(house_rect(i), x, y) {
				select(s, i)
				return
			}
		}
	}
	bs: [MAX_BUTTONS]Button
	count := buttons(s, &bs)
	for b in bs[:count] {
		if in_rect(b.rect, x, y) {
			perform(s, b.action)
			return
		}
	}
}

key :: proc(s: ^State, k: Key) {
	if s.mode == .Over {
		if k == .Confirm {
			restart(s)
		}
		return
	}
	switch k {
	case .None:
	case .Place_1:
		s.place = .Mall
	case .Place_2:
		s.place = .Neighbourhood
	case .Place_3:
		s.place = .Workshop
	case .Left:
		move_selection(s, -1)
	case .Right:
		move_selection(s, 1)
	case .Up:
		move_selection(s, -HOUSE_COLUMNS)
	case .Down:
		move_selection(s, HOUSE_COLUMNS)
	case .Surveil:
		perform(s, .Surveil)
	case .Inform:
		perform(s, .Inform)
	case .Gift:
		perform(s, .Gift)
	case .Buy:
		perform(s, .Buy)
	case .End_Day, .Confirm:
		if k == .End_Day {
			perform(s, .End_Day)
		}
	}
}

@(private)
restart :: proc(s: ^State) {
	s^ = new_state(s.seed + 1)
}

@(private)
select :: proc(s: ^State, i: int) {
	s.selected = i
	n := s.g.neighbours[i]
	switch {
	case !n.alive:
		sayf(s, "%s is gone. The Coal Collection was thorough.", name(i))
	case n.naughty:
		sayf(s, "%s is Naughty. The Coal Collection is coming.", name(i))
	case:
		sayf(s, "%s. Owes %d. Suspicion %d of %d.", name(i), n.debt, n.suspicion, game.NOTICE_LIMIT)
	}
}

@(private)
move_selection :: proc(s: ^State, delta: int) {
	if s.place != .Neighbourhood {
		return
	}
	start := s.selected if s.selected >= 0 else (0 if delta > 0 else game.NEIGHBOURS - 1)
	if s.selected < 0 {
		select(s, start)
		return
	}
	next := start + delta
	if next < 0 || next >= game.NEIGHBOURS {
		next = (next + game.NEIGHBOURS) % game.NEIGHBOURS
	}
	select(s, next)
}

// Names are placeholders until the roster task gives each house a person.
name :: proc(i: int) -> string {
	@(static) bufs: [game.NEIGHBOURS][8]u8
	return fmt.bprintf(bufs[i][:], "No. %d", i + 1)
}

perform :: proc(s: ^State, a: Action) {
	g := &s.g
	switch a {
	case .Surveil, .Inform, .Gift:
		if s.place != .Neighbourhood {
			say(s, "That is done in the Neighbourhood.")
			return
		}
		if s.selected < 0 {
			say(s, "Pick a neighbour first.")
			return
		}
		e: game.Event
		switch a {
		case .Surveil:
			e = game.surveil(g, s.selected)
		case .Inform:
			e = game.inform(g, s.selected)
		case .Gift:
			e = game.gift(g, s.selected)
		case .Buy, .End_Day:
		}
		describe(s, e)
	case .Buy:
		if s.place != .Mall {
			say(s, "The Company Store is in the Mall.")
			return
		}
		describe(s, game.buy_gift(g))
	case .End_Day:
		end_the_day(s)
	}
}

@(private)
describe :: proc(s: ^State, e: game.Event) {
	who := name(e.target) if e.target >= 0 else ""
	#partial switch e.kind {
	case .No_Actions:
		say(s, "No actions left today. End the day.")
	case .Bad_Target:
		sayf(s, "%s is not available.", who)
	case .Not_Enough_Dirt:
		sayf(s, "A Report needs %d Dirt. Surveil first.", game.INFORM_COST_LOW)
	case .Not_Enough_Coin:
		say(s, "Not enough Coin. The Store does not do pity.")
	case .No_Gifts:
		say(s, "No gifts in stock. Buy one at the Mall.")
	case .Surveil_Hit:
		sayf(s, "Went through %s's bins. +%d Dirt.", who, e.amount)
	case .Surveil_Miss:
		sayf(s, "%s saw you. Suspicion rises.", who)
	case .Noticed:
		sayf(s, "%s reported you! A Warning. %d Merit.", who, e.amount)
	case .Inform_Success:
		sayf(s, "Report filed. %s is Naughty. +%d Merit.", who, e.amount)
	case .Inform_Backfire:
		sayf(s, "Report laughed at. %d Merit.", e.amount)
	case .Gift_Bought:
		sayf(s, "Gift bought. -%d Coin. Wrap it, tag it, bill it.", e.amount)
	case .Gift_Delivered:
		sayf(s, "%s now owes %d more. +%d Merit.", who, e.amount, game.GIFT_MERIT)
	}
}

@(private)
end_the_day :: proc(s: ^State) {
	g := &s.g
	r := game.end_day(g)
	if r.refused {
		return
	}
	if s.selected >= 0 && !g.neighbours[s.selected].alive {
		s.selected = -1
	}
	taken := ""
	if r.removed >= 0 {
		taken = fmt.tprintf(" The Coal Collection took %s.", name(r.removed))
	}
	if !r.eve {
		sayf(s, "Night. Tithes +%d Coin.%s", r.tithe_coin, taken)
		return
	}
	switch game.resolve_eve(g) {
	case .Coal:
		s.mode = .Over
		sayf(s, "Krimmis Eve.%s Standing short. Coal. Press Enter.", taken)
	case .Promoted:
		s.selected = -1
		sayf(s, "Krimmis Eve.%s Promoted to Head Elf! A new List.", taken)
	case .Playing:
	}
}

// ---- text the page draws -------------------------------------------------------------------------------

// One line of numbers for the first HUD row.
status_line :: proc(s: ^State, buf: []u8) -> string {
	g := &s.g
	return fmt.bprintf(buf, "Acts %d  Merit %d  Dirt %d  Coin %d  Debt %d  Warn %d", g.actions, g.merit, g.dirt, g.coin, g.debt, g.warnings)
}

// The text beside the Standing bar: Standing over the Eve line, with the year once you are Head Elf.
standing_text :: proc(s: ^State, buf: []u8) -> string {
	g := &s.g
	eve := game.nice_line(game.DAYS, g.rung)
	if g.rung > 0 {
		return fmt.bprintf(buf, "Y%d %d/%.0f", g.rung + 1, game.standing(g), eve)
	}
	return fmt.bprintf(buf, "%d/%.0f", game.standing(g), eve)
}

Bar :: struct {
	fill:  f64, // your Standing as a share of the Eve line, 0 to 1
	mark:  f64, // where today's Nice line sits on the same scale, 0 to 1
	ahead: bool, // Standing is at or above today's line
}

// The Standing bar. It runs from 0 to the Eve line; the mark is today's line, the pace you must keep.
standing_bar :: proc(s: ^State) -> Bar {
	g := &s.g
	eve := game.nice_line(game.DAYS, g.rung)
	today := game.nice_line(g.day, g.rung)
	st := f64(game.standing(g))
	return Bar{fill = clamp(st / eve, 0, 1), mark = clamp(today / eve, 0, 1), ahead = st >= today}
}

Door :: enum {
	Opened, // a day gone
	Today,
	Closed, // a day to come
}

// The advent calendar: door 1 to DAYS.
door :: proc(s: ^State, number: int) -> Door {
	switch {
	case number < s.g.day:
		return .Opened
	case number == s.g.day:
		return .Today
	}
	return .Closed
}
