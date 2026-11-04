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

// What is on screen. Title, Eve, Coal and Promotion are full screens that Enter (or a click) moves past:
// Title to Play; Eve (the reveal) to Coal or Promotion; Coal back to Title; Promotion on to the new year.
Mode :: enum {
	Title,
	Play,
	Eve,
	Coal,
	Promotion,
}

// What the Eve screen reveals, captured before the new year (if any) resets the game.
Eve_Report :: struct {
	standing: int,
	line:     f64,
	debt:     int,
	merit:    int,
	alive:    int, // neighbours still standing
	year:     int, // the year just played, from 1
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

// Sounds the page plays, as numbers. Keep in step with SOUNDS in web/index.html (same order); each is a wav
// in assets/sfx. Title_Loop is music: the page plays it while the title screen is up, so it is never queued.
Sound :: enum {
	None,
	Click,
	Surveil_Hit,
	Surveil_Miss,
	Report_Stamp,
	Report_Backfire,
	Gift_Wrap,
	Gift_Delivered,
	Tithe_Tick,
	Merit_Up,
	Debt_Up,
	Warning,
	Day_End,
	Coal_Arrives,
	Neighbour_Removed,
	Eve_Fanfare,
	Coal_Sting,
	Title_Loop,
}

SOUND_QUEUE :: 8

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
	eve:      Eve_Report,
	verdict:  game.Outcome, // Coal or Promoted, shown after the reveal
	sounds:   [SOUND_QUEUE]Sound, // sounds waiting for the page, oldest first
	sound_n:  int,
}

new_state :: proc(seed: u64, mode := Mode.Play) -> State {
	s := State {
		g        = game.new_game(seed),
		seed     = seed,
		place    = .Neighbourhood,
		selected = -1,
		mode     = mode,
	}
	say(&s, "Welcome to Krimmis, elf. Your name is on the List.")
	return s
}

// Queues a sound for the page (dropped if the queue is full).
@(private)
play :: proc(s: ^State, snd: Sound) {
	if s.sound_n < SOUND_QUEUE {
		s.sounds[s.sound_n] = snd
		s.sound_n += 1
	}
}

// The page takes the oldest waiting sound, or .None.
next_sound :: proc(s: ^State) -> Sound {
	if s.sound_n == 0 {
		return .None
	}
	snd := s.sounds[0]
	for i in 1 ..< s.sound_n {
		s.sounds[i - 1] = s.sounds[i]
	}
	s.sound_n -= 1
	return snd
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
		add(out, &n, 4, 100, "Buy a gift", .Buy, playing && g.debt + game.store_price(g.day) <= game.card_limit(g))
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
	if s.mode != .Play {
		advance(s)
		return
	}
	for p in Place {
		if in_rect(tab_rect(p), x, y) {
			s.place = p
			play(s, .Click)
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
	if s.mode != .Play {
		if k == .Confirm {
			advance(s)
		}
		return
	}
	#partial switch k {
	case .Place_1, .Place_2, .Place_3:
		play(s, .Click)
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

// Moves past a full screen.
@(private)
advance :: proc(s: ^State) {
	switch s.mode {
	case .Title, .Promotion:
		s.mode = .Play
		play(s, .Click)
	case .Eve:
		s.mode = .Coal if s.verdict == .Coal else .Promotion
		play(s, .Coal_Sting if s.verdict == .Coal else .Eve_Fanfare)
	case .Coal:
		s^ = new_state(s.seed + 1, .Title) // a fresh run, a fresh seed
	case .Play:
	}
}

@(private)
select :: proc(s: ^State, i: int) {
	play(s, .Click)
	s.selected = i
	n := s.g.neighbours[i]
	switch {
	case !n.alive:
		sayf(s, "%s is gone. The Coal Collection was thorough.", name(i))
	case n.naughty:
		sayf(s, "%s is Naughty. The Coal Collection is coming.", name(i))
	case:
		r := game.ROSTER[n.role]
		sayf(s, "%s, %s. Owes you %d. Suspicion %d/%d. Likes %s.", r.full, r.label, n.obliged, n.suspicion, game.notice_limit(&s.g, i), r.taste)
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

// The short name of the neighbour in house i: what the house label and the messages call them.
name :: proc(i: int) -> string {
	return game.ROSTER[i].short // a house keeps its role even when a new family moves in
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
	case .No_Actions, .Bad_Target, .Not_Enough_Dirt, .Card_Declined, .No_Gifts:
		play(s, .Surveil_Miss) // a refusal: the low blip
	case .Surveil_Hit:
		play(s, .Surveil_Hit)
	case .Surveil_Miss:
		play(s, .Surveil_Miss)
	case .Noticed:
		play(s, .Warning)
	case .Inform_Success:
		play(s, .Report_Stamp)
		play(s, .Merit_Up)
	case .Inform_Backfire:
		play(s, .Report_Backfire)
	case .Gift_Bought:
		play(s, .Gift_Wrap)
	case .Gift_Delivered:
		play(s, .Gift_Delivered)
		play(s, .Merit_Up)
	}
	#partial switch e.kind {
	case .No_Actions:
		say(s, "No actions left today. End the day.")
	case .Bad_Target:
		sayf(s, "%s is not available.", who)
	case .Not_Enough_Dirt:
		sayf(s, "A Report needs %d Dirt. Surveil first.", game.INFORM_COST_LOW)
	case .Card_Declined:
		say(s, "Card declined. The Store has noticed your balance.")
	case .No_Gifts:
		say(s, "No gifts in stock. Buy one at the Mall.")
	case .Surveil_Hit:
		sayf(s, "%s +%d Dirt.", game.ROSTER[s.g.neighbours[e.target].role].surveil, e.amount)
	case .Surveil_Miss:
		sayf(s, "%s saw you. Suspicion rises.", who)
	case .Noticed:
		sayf(s, "%s reported you! A Warning. %d Merit.", who, e.amount)
	case .Inform_Success:
		sayf(s, "%s +%d Merit.", game.ROSTER[s.g.neighbours[e.target].role].report, e.amount)
	case .Inform_Backfire:
		sayf(s, "Report laughed at. %d Merit.", e.amount)
	case .Gift_Bought:
		sayf(s, "Gift bought on the card. +%d Debt. Billed to future you.", e.amount)
	case .Gift_Delivered:
		sayf(s, "%s is touched, and feels obliged. +%d Merit.", who, game.GIFT_MERIT)
	}
}

// What happened in the night, as at most two messages: a random event, then the Coal Collection's visit
// (or a plain night) with the favours returned.
@(private)
night_messages :: proc(s: ^State, r: game.Night_Report) {
	event := ""
	switch r.event {
	case .None:
	case .Audit_Pass:
		event = fmt.tprintf("Surprise audit! Management is pleased. +%d Merit.", r.event_amount)
	case .Audit_Fail:
		event = fmt.tprintf("Surprise audit! Management finds you wanting. %d Merit.", r.event_amount)
	case .Tip_Off:
		event = fmt.tprintf("A neighbour slips you a note under the door. +%d Dirt.", r.event_amount)
	case .Santa:
		event = "Kris Krinkle was seen on the street. Fewer actions tomorrow."
	}
	switch {
	case r.removed >= 0 && event != "":
		say(s, event)
		sayf(s, "%s Favours +%d.", game.ROSTER[r.removed].removed, r.favour_coin)
	case r.removed >= 0:
		sayf(s, "%s Favours +%d.", game.ROSTER[r.removed].removed, r.favour_coin)
	case event != "":
		sayf(s, "%s Favours +%d.", event, r.favour_coin)
	case:
		sayf(s, "Night. Favours returned +%d Coin.", r.favour_coin)
	}
}

@(private)
end_the_day :: proc(s: ^State) {
	g := &s.g
	r := game.end_day(g)
	if r.refused {
		return
	}
	play(s, .Day_End)
	if r.favour_coin > 0 {
		play(s, .Tithe_Tick)
	}
	if r.removed >= 0 {
		play(s, .Coal_Arrives)
		play(s, .Neighbour_Removed)
	}
	if r.own_missed > 0 {
		play(s, .Debt_Up)
	}
	#partial switch r.event {
	case .Audit_Pass, .Tip_Off:
		play(s, .Merit_Up)
	case .Audit_Fail:
		play(s, .Warning)
	}
	if s.selected >= 0 && !g.neighbours[s.selected].alive {
		s.selected = -1
	}
	if !r.eve {
		night_messages(s, r)
		return
	}
	taken := ""
	if r.removed >= 0 {
		taken = fmt.tprintf(" %s was taken.", name(r.removed))
	}
	// Capture the reveal before a promotion resets the game for the new year.
	s.eve = Eve_Report {
		standing = game.standing(g),
		line     = game.nice_line(game.DAYS, g.rung),
		debt     = g.debt,
		merit    = g.merit,
		alive    = game.alive_count(g),
		year     = g.rung + 1,
	}
	s.verdict = game.resolve_eve(g)
	s.selected = -1
	s.mode = .Eve
	sayf(s, "Krimmis Eve.%s Kris Krinkle checks the List.", taken)
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
