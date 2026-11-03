#+build !js
package ui

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
	testing.expect_value(t, message(&s), "No. 6 is not available.")
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
krimmis_eve_with_nothing_done_is_coal_then_enter_restarts :: proc(t: ^testing.T) {
	s := new_state(1)
	for _ in 0 ..< game.DAYS {
		key(&s, .End_Day)
	}
	testing.expect_value(t, s.mode, Mode.Over)
	key(&s, .End_Day) // ignored
	testing.expect_value(t, s.mode, Mode.Over)
	key(&s, .Confirm)
	testing.expect_value(t, s.mode, Mode.Play)
	testing.expect_value(t, s.g.day, 1)
}

@(test)
a_promotion_starts_the_next_year :: proc(t: ^testing.T) {
	s := new_state(1)
	s.g.day = game.DAYS
	s.g.merit = 90
	key(&s, .End_Day)
	testing.expect_value(t, s.mode, Mode.Play)
	testing.expect_value(t, s.g.rung, 1)
	testing.expect_value(t, s.g.day, 1)
}

@(test)
status_lines_show_the_numbers :: proc(t: ^testing.T) {
	s := new_state(1)
	buf: [80]u8
	testing.expect_value(t, status_line(&s, buf[:]), "Day 1/24  Acts 3  Merit 0  Dirt 0  Coin 30  Debt 30")
	testing.expect_value(t, standing_line(&s, buf[:]), "Standing -6, Nice line 12")
}
