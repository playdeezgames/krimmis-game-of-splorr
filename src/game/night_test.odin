#+build !js
package game

import "core:testing"

@(test)
ending_a_day_moves_on_and_refills_actions :: proc(t: ^testing.T) {
	g := new_game(1)
	g.actions = 0
	end_day(&g)
	testing.expect_value(t, g.day, 2)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
}

@(test)
favour_is_a_quarter_rounded_up_and_you_keep_half :: proc(t: ^testing.T) {
	g := new_game(1)
	g.neighbours[0].obliged = 8
	g.neighbours[1].obliged = 1
	g.neighbours[2].obliged = 17
	start := g.coin
	r := end_day(&g)
	testing.expect_value(t, g.neighbours[0].obliged, 6) // paid 2, you kept 1
	testing.expect_value(t, g.neighbours[1].obliged, 0) // paid 1, you kept 0
	testing.expect_value(t, g.neighbours[2].obliged, 12) // paid 5, you kept 2
	testing.expect_value(t, r.returners, 3)
	testing.expect_value(t, r.favour_coin, 3)
	testing.expect_value(t, g.coin, start + 3 - 2) // the card minimum on a Debt of 30 is 2
}

@(test)
removed_neighbours_pay_nothing :: proc(t: ^testing.T) {
	g := new_game(1)
	g.neighbours[0].obliged = 8
	g.neighbours[0].alive = false
	r := end_day(&g)
	testing.expect_value(t, r.returners, 0)
	testing.expect_value(t, g.neighbours[0].obliged, 8)
}

@(test)
coal_comes_on_even_nights_only_and_takes_one_naughty :: proc(t: ^testing.T) {
	g := new_game(5)
	g.neighbours[3].naughty = true
	g.neighbours[7].naughty = true
	r := end_day(&g) // night of day 1: odd, nobody comes
	testing.expect_value(t, r.removed, -1)
	testing.expect_value(t, alive_count(&g), 12)
	r = end_day(&g) // night of day 2
	testing.expect(t, r.removed == 3 || r.removed == 7)
	testing.expect_value(t, alive_count(&g), 11)
	testing.expect(t, !g.neighbours[r.removed].alive)
}

@(test)
the_coal_collection_only_calls_every_second_night :: proc(t: ^testing.T) {
	g := new_game(5)
	r := end_day(&g)
	testing.expect_value(t, r.removed, -1)
	testing.expect(t, !r.knocked)
	testing.expect_value(t, alive_count(&g), 12)
}

@(test)
on_pace_with_nobody_naughty_the_street_names_a_neighbour :: proc(t: ^testing.T) {
	g := new_game(5)
	g.merit = 100
	end_day(&g)
	r := end_day(&g)
	testing.expect(t, r.named && !r.knocked)
	testing.expect(t, r.removed >= 0 && !g.neighbours[r.removed].alive)
	testing.expect_value(t, alive_count(&g), 11)
	testing.expect_value(t, g.knocks, 0)
}

// Runs to the second night with Standing behind the line, over seeds, until the street names you.
@(private = "file")
first_knock :: proc() -> (Game, Night_Report) {
	for seed in u64(1) ..< 1000 {
		g := new_game(seed)
		end_day(&g)
		if r := end_day(&g); r.knocked {
			return g, r
		}
	}
	panic("no knock found")
}

@(test)
behind_the_line_the_street_sometimes_names_you :: proc(t: ^testing.T) {
	knocks, named := 0, 0
	for seed in u64(1) ..= 2000 {
		g := new_game(seed)
		end_day(&g)
		r := end_day(&g)
		knocks += 1 if r.knocked else 0
		named += 1 if r.named else 0
	}
	testing.expect_value(t, knocks + named, 2000)
	testing.expect(t, abs(f64(knocks) / 2000 - QUOTA_YOU_CHANCE) < 0.03)
}

@(test)
a_knock_is_a_warning_and_lost_merit :: proc(t: ^testing.T) {
	g, r := first_knock()
	testing.expect_value(t, r.removed, -1)
	testing.expect_value(t, alive_count(&g), 12)
	testing.expect_value(t, g.knocks, 1)
	testing.expect_value(t, g.warnings, 1)
	testing.expect_value(t, g.merit, -KNOCK_PENALTY)
	testing.expect(t, !r.coal)
}

@(test)
the_last_knock_is_coal_and_ends_the_calendar :: proc(t: ^testing.T) {
	g, _ := first_knock()
	g.knocks = KNOCK_LIMIT - 1
	g.day = 4 // another quota night
	for &n in g.neighbours {
		n.alive = false // nobody else to name
	}
	debt := g.debt
	r := end_day(&g)
	testing.expect(t, r.knocked && r.coal)
	testing.expect_value(t, g.outcome, Outcome.Coal)
	testing.expect_value(t, g.debt, debt) // nothing after the knock ran
	testing.expect(t, end_day(&g).refused)
	testing.expect_value(t, resolve_eve(&g), Outcome.Coal)
}

@(test)
knocks_reset_with_the_new_year :: proc(t: ^testing.T) {
	g := new_game(1)
	g.knocks = 2
	g.day = DAYS
	g.merit = 1000
	end_day(&g)
	testing.expect_value(t, resolve_eve(&g), Outcome.Promoted)
	testing.expect_value(t, g.knocks, 0)
}

@(test)
coal_never_takes_the_already_removed :: proc(t: ^testing.T) {
	g := new_game(9)
	g.neighbours[4].naughty = true
	g.neighbours[4].alive = false
	g.day = 2
	r := end_day(&g)
	testing.expect_value(t, r.removed, -1)
}

@(test)
own_debt_takes_the_card_minimum_then_interest :: proc(t: ^testing.T) {
	g := new_game(1)
	g.coin = 10
	g.debt = 100
	r := end_day(&g)
	testing.expect_value(t, r.own_paid, 5) // a twentieth of 100
	testing.expect_value(t, r.own_missed, 0)
	testing.expect_value(t, g.coin, 5)
	testing.expect_value(t, g.debt, 97) // (100 - 5) * 1.03 = 97.85, truncated
	testing.expect_value(t, r.interest, 2)
}

@(test)
a_missed_payment_is_added_to_the_debt :: proc(t: ^testing.T) {
	g := new_game(1)
	g.coin = 0
	g.debt = 100
	r := end_day(&g)
	testing.expect_value(t, r.own_paid, 0)
	testing.expect_value(t, r.own_missed, 5)
	testing.expect_value(t, g.debt, 108) // (100 + 5) * 1.03 = 108.15, truncated
	testing.expect_value(t, g.coin, 0)
}

// A game whose next night's first draw (the event roll, on an odd day with no Naughty) lands in [lo, hi).
@(private = "file")
game_with_event_roll :: proc(lo, hi: f64) -> Game {
	for seed in u64(1) ..< 100000 {
		probe := rng_seed(seed)
		x := rng_float(&probe)
		if x >= lo && x < hi {
			return new_game(seed)
		}
	}
	panic("no seed found")
}

@(test)
an_audit_rewards_a_pace_and_punishes_a_slump :: proc(t: ^testing.T) {
	g := game_with_event_roll(0, AUDIT_CHANCE)
	g.merit = 100
	r := end_day(&g)
	testing.expect_value(t, r.event, Night_Event.Audit_Pass)
	testing.expect_value(t, g.merit, 100 + AUDIT_PASS)
	g = game_with_event_roll(0, AUDIT_CHANCE)
	r = end_day(&g)
	testing.expect_value(t, r.event, Night_Event.Audit_Fail)
	testing.expect_value(t, g.merit, AUDIT_FAIL)
}

@(test)
a_tip_off_gives_dirt :: proc(t: ^testing.T) {
	g := game_with_event_roll(AUDIT_CHANCE, AUDIT_CHANCE + TIP_CHANCE)
	r := end_day(&g)
	testing.expect_value(t, r.event, Night_Event.Tip_Off)
	testing.expect_value(t, g.dirt, TIP_DIRT)
}

@(test)
a_santa_sighting_costs_tomorrows_first_action_only :: proc(t: ^testing.T) {
	g := game_with_event_roll(AUDIT_CHANCE + TIP_CHANCE, AUDIT_CHANCE + TIP_CHANCE + SANTA_CHANCE)
	r := end_day(&g)
	testing.expect_value(t, r.event, Night_Event.Santa)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY - 1)
	// The day after that is back to normal (unless Santa is seen again).
	g.rng = rng_seed(0) // any quiet roll will do; check the flag was spent
	testing.expect(t, !g.santa_watching)
}

@(test)
a_quiet_night_has_no_event :: proc(t: ^testing.T) {
	g := game_with_event_roll(AUDIT_CHANCE + TIP_CHANCE + SANTA_CHANCE, 1)
	r := end_day(&g)
	testing.expect_value(t, r.event, Night_Event.None)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
}

@(test)
nights_have_the_rolled_event_share :: proc(t: ^testing.T) {
	counts: [Night_Event]int
	for seed in u64(1) ..= 3000 {
		g := new_game(seed)
		counts[end_day(&g).event] += 1
	}
	share :: proc(n: int) -> f64 {return f64(n) / 3000}
	testing.expect(t, abs(share(counts[.Audit_Pass] + counts[.Audit_Fail]) - AUDIT_CHANCE) < 0.025)
	testing.expect(t, abs(share(counts[.Tip_Off]) - TIP_CHANCE) < 0.025)
	testing.expect(t, abs(share(counts[.Santa]) - SANTA_CHANCE) < 0.025)
}

@(test)
there_is_no_event_on_krimmis_eve :: proc(t: ^testing.T) {
	for seed in u64(1) ..= 500 {
		g := new_game(seed)
		g.day = DAYS
		testing.expect_value(t, end_day(&g).event, Night_Event.None)
	}
}
