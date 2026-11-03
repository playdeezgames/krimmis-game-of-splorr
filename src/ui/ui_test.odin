#+build !js
package ui

import "core:strings"
import "core:testing"
import "krimmis:game"

center :: proc(r: Rect) -> (int, int) {
	return r.x + r.w / 2, r.y + r.h / 2
}

click_rect :: proc(s: ^State, r: Rect) {
	x, y := center(r)
	click(s, x, y)
}

button_rect :: proc(s: ^State, a: Action) -> Rect {
	bs: [MAX_BUTTONS]Button
	n := buttons(s, &bs)
	for b in bs[:n] {
		if b.action == a {
			return b.rect
		}
	}
	panic("no such button")
}

@(test)
tabs_switch_place :: proc(t: ^testing.T) {
	s := new_state(1)
	click_rect(&s, tab_rect(.Mall))
	testing.expect_value(t, s.place, Place.Mall)
	click_rect(&s, tab_rect(.Workshop))
	testing.expect_value(t, s.place, Place.Workshop)
	key(&s, .Place_2)
	testing.expect_value(t, s.place, Place.Neighbourhood)
}

@(test)
clicking_a_house_selects_that_neighbour :: proc(t: ^testing.T) {
	s := new_state(1)
	click_rect(&s, house_rect(7))
	testing.expect_value(t, s.selected, 7)
	// Houses are only live in the Neighbourhood.
	click_rect(&s, tab_rect(.Mall))
	click_rect(&s, house_rect(2))
	testing.expect_value(t, s.selected, 7)
}

@(test)
houses_do_not_overlap_the_buttons_or_tabs :: proc(t: ^testing.T) {
	for i in 0 ..< game.NEIGHBOURS {
		h := house_rect(i)
		testing.expect(t, h.x >= 0 && h.x + h.w <= SCREEN_W)
		testing.expect(t, h.y > tab_rect(.Mall).y + tab_rect(.Mall).h)
		testing.expect(t, h.y + h.h < BUTTON_Y)
	}
}

@(test)
arrow_keys_walk_the_street :: proc(t: ^testing.T) {
	s := new_state(1)
	key(&s, .Right)
	testing.expect_value(t, s.selected, 0)
	key(&s, .Right)
	testing.expect_value(t, s.selected, 1)
	key(&s, .Down)
	testing.expect_value(t, s.selected, 7)
	key(&s, .Left)
	key(&s, .Up)
	testing.expect_value(t, s.selected, 0)
	key(&s, .Left)
	testing.expect_value(t, s.selected, game.NEIGHBOURS - 1)
}

@(test)
surveil_button_spends_an_action_on_the_selection :: proc(t: ^testing.T) {
	s := new_state(1)
	click_rect(&s, house_rect(3))
	click_rect(&s, button_rect(&s, .Surveil))
	testing.expect_value(t, s.g.actions, game.ACTIONS_PER_DAY - 1)
}

@(test)
actions_need_a_selection_and_the_right_place :: proc(t: ^testing.T) {
	s := new_state(1)
	key(&s, .Surveil)
	testing.expect_value(t, s.g.actions, game.ACTIONS_PER_DAY)
	testing.expect_value(t, message(&s), "Pick a neighbour first.")
	click_rect(&s, house_rect(1))
	key(&s, .Place_1)
	key(&s, .Surveil)
	testing.expect_value(t, s.g.actions, game.ACTIONS_PER_DAY)
	testing.expect_value(t, message(&s), "That is done in the Neighbourhood.")
}

@(test)
buying_in_the_mall_then_gifting_in_the_neighbourhood :: proc(t: ^testing.T) {
	s := new_state(1)
	key(&s, .Buy) // in the Neighbourhood: refused
	testing.expect_value(t, s.g.gifts, 0)
	key(&s, .Place_1)
	click_rect(&s, button_rect(&s, .Buy))
	testing.expect_value(t, s.g.gifts, 1)
	key(&s, .Place_2)
	click_rect(&s, house_rect(4))
	key(&s, .Gift)
	testing.expect_value(t, s.g.gifts, 0)
	testing.expect_value(t, s.g.neighbours[4].debt, game.GIFT_DEBT)
	testing.expect_value(t, s.g.merit, game.GIFT_MERIT)
}

@(test)
button_enabled_flags_follow_the_rules :: proc(t: ^testing.T) {
	s := new_state(1)
	bs: [MAX_BUTTONS]Button
	n := buttons(&s, &bs)
	for b in bs[:n] {
		testing.expect_value(t, b.enabled, b.action == .End_Day) // nothing selected, no Dirt, no gifts
	}
	click_rect(&s, house_rect(0))
	s.g.dirt = 3
	s.g.gifts = 1
	n = buttons(&s, &bs)
	for b in bs[:n] {
		testing.expect(t, b.enabled)
	}
	s.g.actions = 0
	n = buttons(&s, &bs)
	for b in bs[:n] {
		testing.expect_value(t, b.enabled, b.action == .End_Day)
	}
}

@(test)
ending_the_day_advances_the_calendar :: proc(t: ^testing.T) {
	s := new_state(1)
	click_rect(&s, button_rect(&s, .End_Day))
	testing.expect_value(t, s.g.day, 2)
	testing.expect_value(t, s.g.actions, game.ACTIONS_PER_DAY)
}

@(test)
a_naughty_neighbour_is_selectable_but_not_actionable :: proc(t: ^testing.T) {
	s := new_state(1)
	s.g.neighbours[5].naughty = true
	click_rect(&s, house_rect(5))
	key(&s, .Surveil)
	testing.expect_value(t, s.g.actions, game.ACTIONS_PER_DAY)
	testing.expect_value(t, message(&s), "Ellen is not available.")
}

@(test)
removal_clears_the_selection :: proc(t: ^testing.T) {
	s := new_state(1)
	s.g.neighbours[2].naughty = true
	click_rect(&s, house_rect(2))
	key(&s, .End_Day) // night of day 1: odd, nobody comes
	testing.expect_value(t, s.selected, 2)
	key(&s, .End_Day) // night of day 2: the Coal Collection takes the only Naughty
	testing.expect_value(t, s.selected, -1)
}

@(test)
krimmis_eve_with_nothing_done_reveals_then_coal_then_title :: proc(t: ^testing.T) {
	s := new_state(1)
	for _ in 0 ..< game.DAYS {
		key(&s, .End_Day)
	}
	testing.expect_value(t, s.mode, Mode.Eve)
	testing.expect_value(t, s.verdict, game.Outcome.Coal)
	testing.expect_value(t, s.eve.year, 1)
	testing.expect_value(t, s.eve.standing, game.standing(&s.g))
	key(&s, .End_Day) // ignored on a full screen
	testing.expect_value(t, s.mode, Mode.Eve)
	key(&s, .Confirm)
	testing.expect_value(t, s.mode, Mode.Coal)
	key(&s, .Confirm)
	testing.expect_value(t, s.mode, Mode.Title)
	testing.expect_value(t, s.g.day, 1)
	key(&s, .Confirm)
	testing.expect_value(t, s.mode, Mode.Play)
}

@(test)
a_promotion_shows_the_reveal_then_the_promotion_then_the_new_year :: proc(t: ^testing.T) {
	s := new_state(1)
	s.g.day = game.DAYS
	s.g.merit = 90
	key(&s, .End_Day)
	testing.expect_value(t, s.mode, Mode.Eve)
	testing.expect_value(t, s.verdict, game.Outcome.Promoted)
	// The reveal keeps last year's numbers even though the game has already moved on.
	testing.expect_value(t, s.eve.merit, 90)
	testing.expect_value(t, s.eve.year, 1)
	testing.expect_value(t, s.g.rung, 1)
	testing.expect_value(t, s.g.merit, 0)
	key(&s, .Confirm)
	testing.expect_value(t, s.mode, Mode.Promotion)
	key(&s, .Confirm)
	testing.expect_value(t, s.mode, Mode.Play)
	testing.expect_value(t, s.g.day, 1)
}

@(test)
the_title_waits_for_a_click_or_enter :: proc(t: ^testing.T) {
	s := new_state(1, .Title)
	key(&s, .Surveil)
	key(&s, .Place_1)
	testing.expect_value(t, s.mode, Mode.Title)
	click(&s, 10, 10)
	testing.expect_value(t, s.mode, Mode.Play)
	s = new_state(1, .Title)
	key(&s, .Confirm)
	testing.expect_value(t, s.mode, Mode.Play)
}

@(test)
status_lines_show_the_numbers :: proc(t: ^testing.T) {
	s := new_state(1)
	buf: [80]u8
	testing.expect_value(t, status_line(&s, buf[:]), "Acts 3  Merit 0  Dirt 0  Coin 30  Debt 30  Warn 0")
	testing.expect_value(t, standing_text(&s, buf[:]), "-6/51")
	s.g.rung = 1
	testing.expect_value(t, standing_text(&s, buf[:]), "Y2 -6/52")
}

@(test)
standing_bar_follows_standing_and_the_pace :: proc(t: ^testing.T) {
	s := new_state(1)
	b := standing_bar(&s)
	testing.expect_value(t, b.fill, 0.0) // negative Standing clamps to empty
	testing.expect(t, !b.ahead)
	testing.expect(t, b.mark > 0 && b.mark < 0.3) // day 1 line is 11.7 of 50.8
	s.g.merit = 30
	s.g.debt = 0
	b = standing_bar(&s)
	testing.expect(t, abs(b.fill - 30.0 / 50.8) < 0.001)
	testing.expect(t, b.ahead)
	s.g.merit = 200
	testing.expect_value(t, standing_bar(&s).fill, 1.0)
	s.g.day = game.DAYS
	testing.expect_value(t, standing_bar(&s).mark, 1.0)
}

@(test)
calendar_doors_open_as_days_pass :: proc(t: ^testing.T) {
	s := new_state(1)
	testing.expect_value(t, door(&s, 1), Door.Today)
	testing.expect_value(t, door(&s, 2), Door.Closed)
	key(&s, .End_Day)
	key(&s, .End_Day)
	testing.expect_value(t, door(&s, 1), Door.Opened)
	testing.expect_value(t, door(&s, 2), Door.Opened)
	testing.expect_value(t, door(&s, 3), Door.Today)
	testing.expect_value(t, door(&s, game.DAYS), Door.Closed)
}

@(test)
event_log_keeps_the_latest_lines_and_wraps :: proc(t: ^testing.T) {
	s := new_state(1)
	testing.expect_value(t, s.latest, 1)
	click_rect(&s, house_rect(3))
	key(&s, .Surveil)
	testing.expect(t, strings.has_suffix(message(&s), log_line(&s, LOG_VISIBLE - 1))) // a long line wraps
	testing.expect(t, log_line(&s, LOG_VISIBLE - 2) != "") // the select message sits above it
	// A long message wraps onto two lines and both are the latest.
	s.g.neighbours[3].naughty = true
	s.g.neighbours[3].alive = false
	key(&s, .End_Day)
	key(&s, .End_Day) // night 2, with a long Coal Collection message at the end of the year below
	for i in 0 ..< LOG_VISIBLE {
		testing.expect(t, len(log_line(&s, i)) <= LOG_WIDTH)
	}
	s.g.day = game.DAYS
	s.g.merit = 90
	key(&s, .End_Day) // Krimmis Eve: a long line
	testing.expect(t, s.latest >= 1)
	testing.expect_value(t, log_line(&s, LOG_VISIBLE - 1) != "", true)
}

@(test)
long_messages_wrap_at_spaces_into_latest_lines :: proc(t: ^testing.T) {
	s := new_state(1)
	push_log(&s, "The Coal Collection took No. 4. Krimmis Eve. Standing short. Coal.")
	testing.expect_value(t, s.latest, 2)
	testing.expect_value(t, log_line(&s, LOG_VISIBLE - 2), "The Coal Collection took No. 4. Krimmis Eve.")
	testing.expect_value(t, log_line(&s, LOG_VISIBLE - 1), "Standing short. Coal.")
}

@(test)
selecting_a_house_describes_its_neighbour :: proc(t: ^testing.T) {
	s := new_state(1)
	click_rect(&s, house_rect(0))
	testing.expect_value(t, message(&s), "Karen Pemberton-Wise, the Karen. Owes 0. Suspicion 0/3. Likes gift receipts, just in case.")
	click_rect(&s, house_rect(1))
	testing.expect_value(t, message(&s), "Maureen Holloway, the choir mum. Owes 0. Suspicion 0/5. Likes sheet music and lozenges.")
}

@(test)
houses_are_labelled_with_their_neighbours :: proc(t: ^testing.T) {
	testing.expect_value(t, name(0), "Karen")
	testing.expect_value(t, name(11), "Skylar")
}

@(test)
a_successful_report_uses_the_neighbours_own_line :: proc(t: ^testing.T) {
	for seed in u64(1) ..< 200 {
		s := new_state(seed)
		s.g.dirt = 5
		click_rect(&s, house_rect(2))
		key(&s, .Inform)
		if s.g.neighbours[2].naughty {
			testing.expect_value(t, message(&s), "Gary is Naughty. His inflatable snowman is already deflating in sympathy. +6 Merit.")
			return
		}
	}
	testing.fail_now(t, "no seed informed successfully")
}

@(test)
the_coal_collections_visit_reads_the_removed_neighbours_line :: proc(t: ^testing.T) {
	s := new_state(1)
	s.g.neighbours[0].naughty = true
	key(&s, .End_Day)
	key(&s, .End_Day) // night of day 2
	testing.expect(t, strings.contains(message(&s), "Karen asked the Coal Collection for their supervisor."))
	testing.expect(t, strings.contains(message(&s), "Tithes +"))
}
