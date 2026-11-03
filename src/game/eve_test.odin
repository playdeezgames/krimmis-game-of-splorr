#+build !js
package game

import "core:testing"

// A game at the end of Krimmis Eve with a chosen Standing.
@(private = "file")
at_eve :: proc(merit, debt: int) -> Game {
	g := new_game(1)
	g.day = DAYS
	g.merit = merit
	g.debt = debt
	g.eve_reached = true
	return g
}

@(test)
nothing_is_decided_before_eve :: proc(t: ^testing.T) {
	g := new_game(1)
	testing.expect_value(t, resolve_eve(&g), Outcome.Playing)
	testing.expect_value(t, g.day, 1)
}

@(test)
below_the_line_is_coal_and_stays_coal :: proc(t: ^testing.T) {
	g := at_eve(40, 0) // 40 against 50.8
	testing.expect_value(t, resolve_eve(&g), Outcome.Coal)
	testing.expect_value(t, g.outcome, Outcome.Coal)
	testing.expect_value(t, resolve_eve(&g), Outcome.Coal)
	testing.expect_value(t, g.rung, 0)
	testing.expect(t, end_day(&g).refused)
}

@(test)
debt_counts_against_standing :: proc(t: ^testing.T) {
	g := at_eve(55, 40) // 55 - 8 = 47, below 50.8
	testing.expect_value(t, resolve_eve(&g), Outcome.Coal)
}

@(test)
at_the_line_is_a_promotion :: proc(t: ^testing.T) {
	g := at_eve(51, 0) // 51 against 50.8
	testing.expect_value(t, resolve_eve(&g), Outcome.Promoted)
	testing.expect_value(t, g.rung, 1)
}

@(test)
promotion_restarts_the_loop_one_rung_up :: proc(t: ^testing.T) {
	g := at_eve(60, 35)
	g.dirt = 4
	g.gifts = 2
	g.warnings = 1
	g.coin = 3
	g.neighbours[0].debt = 12
	g.neighbours[0].grudge = 2
	g.neighbours[0].suspicion = 2
	g.neighbours[1].naughty = true
	g.neighbours[2].alive = false
	g.neighbours[2].debt = 9
	g.neighbours[2].naughty = true
	testing.expect_value(t, resolve_eve(&g), Outcome.Promoted)
	testing.expect_value(t, g.outcome, Outcome.Playing)
	testing.expect_value(t, g.day, 1)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
	testing.expect(t, !g.eve_reached)
	testing.expect_value(t, g.merit, 0)
	testing.expect_value(t, g.dirt, 0)
	testing.expect_value(t, g.gifts, 0)
	testing.expect_value(t, g.warnings, 0)
	testing.expect_value(t, g.debt, 35) // the Debt carries
	testing.expect_value(t, g.coin, START_COIN) // topped up
	// A survivor keeps debt and grudge but is Nice again.
	testing.expect_value(t, g.neighbours[0].debt, 12)
	testing.expect_value(t, g.neighbours[0].grudge, 2)
	testing.expect_value(t, g.neighbours[0].suspicion, 0)
	testing.expect(t, !g.neighbours[1].naughty)
	// A neighbour who was taken is replaced by a fresh family in the same house.
	testing.expect(t, g.neighbours[2].alive && !g.neighbours[2].naughty)
	testing.expect_value(t, g.neighbours[2].debt, 0)
	testing.expect_value(t, g.neighbours[2].role, 2)
	testing.expect_value(t, alive_count(&g), NEIGHBOURS)
}

@(test)
rich_coin_is_kept_on_promotion :: proc(t: ^testing.T) {
	g := at_eve(60, 0)
	g.coin = 90
	resolve_eve(&g)
	testing.expect_value(t, g.coin, 90)
}

@(test)
each_rung_raises_the_line_and_the_interest :: proc(t: ^testing.T) {
	testing.expect(t, nice_line(DAYS, 1) > nice_line(DAYS, 0))
	testing.expect(t, abs(nice_line(DAYS, 2) - (10 + (1.7 + 0.1) * 24)) < 0.001)
	a := new_game(1)
	a.debt = 1000
	b := a
	b.rung = 3
	end_day(&a)
	end_day(&b)
	testing.expect(t, b.debt > a.debt)
}

@(test)
a_run_ends_in_coal_eventually :: proc(t: ^testing.T) {
	// Even with flush Merit, a high rung needs more: climb until the line outruns a fixed Merit.
	g := at_eve(75, 0)
	years := 0
	for resolve_eve(&g) == .Promoted {
		years += 1
		g.merit = 75
		g.day = DAYS
		g.eve_reached = true
		testing.expect(t, years < 100)
	}
	testing.expect_value(t, g.outcome, Outcome.Coal)
	testing.expect(t, years >= 1)
}
