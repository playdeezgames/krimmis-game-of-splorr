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
tithe_is_a_quarter_rounded_up_and_you_keep_half :: proc(t: ^testing.T) {
	g := new_game(1)
	g.neighbours[0].debt = 8
	g.neighbours[1].debt = 1
	g.neighbours[2].debt = 17
	start := g.coin
	r := end_day(&g)
	testing.expect_value(t, g.neighbours[0].debt, 6) // paid 2, you kept 1
	testing.expect_value(t, g.neighbours[1].debt, 0) // paid 1, you kept 0
	testing.expect_value(t, g.neighbours[2].debt, 12) // paid 5, you kept 2
	testing.expect_value(t, r.tithe_payers, 3)
	testing.expect_value(t, r.tithe_coin, 3)
	testing.expect_value(t, g.coin, start + 3 - OWN_MIN_PAYMENT)
}

@(test)
removed_neighbours_pay_nothing :: proc(t: ^testing.T) {
	g := new_game(1)
	g.neighbours[0].debt = 8
	g.neighbours[0].alive = false
	r := end_day(&g)
	testing.expect_value(t, r.tithe_payers, 0)
	testing.expect_value(t, g.neighbours[0].debt, 8)
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
coal_does_not_come_when_nobody_is_naughty :: proc(t: ^testing.T) {
	g := new_game(5)
	end_day(&g)
	r := end_day(&g)
	testing.expect_value(t, r.removed, -1)
	testing.expect_value(t, alive_count(&g), 12)
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
own_debt_takes_the_minimum_payment_then_interest :: proc(t: ^testing.T) {
	g := new_game(1)
	g.coin = 10
	g.debt = 100
	r := end_day(&g)
	testing.expect_value(t, r.own_paid, OWN_MIN_PAYMENT)
	testing.expect_value(t, r.own_missed, 0)
	testing.expect_value(t, g.coin, 9)
	testing.expect_value(t, g.debt, 101) // (100 - 1) * 1.03 = 101.97, truncated
	testing.expect_value(t, r.interest, 2)
}

@(test)
a_missed_payment_is_added_to_the_debt :: proc(t: ^testing.T) {
	g := new_game(1)
	g.coin = 0
	g.debt = 100
	r := end_day(&g)
	testing.expect_value(t, r.own_paid, 0)
	testing.expect_value(t, r.own_missed, OWN_MIN_PAYMENT)
	testing.expect_value(t, g.debt, 104) // (100 + 1) * 1.03 = 104.03, truncated
	testing.expect_value(t, g.coin, 0)
}
