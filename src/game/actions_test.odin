#+build !js
package game

import "core:testing"

// Finds a seed whose next draw matches want_chance's outcome, so a rule can be checked exactly.
@(private = "file")
game_where_next_draw :: proc(p: f64, succeeds: bool) -> Game {
	for seed in u64(1) ..< 10000 {
		probe := rng_seed(seed)
		if rng_chance(&probe, p) == succeeds {
			return new_game(seed)
		}
	}
	panic("no seed found")
}

@(test)
store_price_creeps_up_weekly :: proc(t: ^testing.T) {
	testing.expect_value(t, store_price(1), 5)
	testing.expect_value(t, store_price(7), 5)
	testing.expect_value(t, store_price(8), 6)
	testing.expect_value(t, store_price(24), 8)
}

@(test)
surveil_hit_gives_dirt_and_costs_an_action :: proc(t: ^testing.T) {
	g := game_where_next_draw(SURVEIL_CHANCE, true)
	e := surveil(&g, 3)
	testing.expect_value(t, e.kind, Event_Kind.Surveil_Hit)
	testing.expect_value(t, g.dirt, SURVEIL_DIRT)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY - 1)
}

@(test)
surveil_miss_adds_suspicion :: proc(t: ^testing.T) {
	g := game_where_next_draw(SURVEIL_CHANCE, false)
	e := surveil(&g, 0)
	testing.expect_value(t, e.kind, Event_Kind.Surveil_Miss)
	testing.expect_value(t, g.neighbours[0].suspicion, 1)
	testing.expect_value(t, g.warnings, 0)
}

@(test)
third_miss_is_noticed_and_becomes_a_warning :: proc(t: ^testing.T) {
	g := game_where_next_draw(SURVEIL_CHANCE, false)
	g.neighbours[0].suspicion = NOTICE_LIMIT - 1
	e := surveil(&g, 0)
	testing.expect_value(t, e.kind, Event_Kind.Noticed)
	testing.expect_value(t, g.warnings, 1)
	testing.expect_value(t, g.merit, -NOTICE_PENALTY)
	testing.expect_value(t, g.neighbours[0].suspicion, 0)
}

@(test)
inform_success_marks_naughty_and_pays_merit :: proc(t: ^testing.T) {
	g := game_where_next_draw(INFORM_CHANCE_LOW, true)
	g.dirt = 3
	e := inform(&g, 5)
	testing.expect_value(t, e.kind, Event_Kind.Inform_Success)
	testing.expect(t, g.neighbours[5].naughty)
	testing.expect_value(t, g.merit, INFORM_MERIT)
	testing.expect_value(t, g.dirt, 0)
}

@(test)
inform_backfire_costs_merit_and_dirt :: proc(t: ^testing.T) {
	g := game_where_next_draw(INFORM_CHANCE_LOW, false)
	g.dirt = 3
	e := inform(&g, 5)
	testing.expect_value(t, e.kind, Event_Kind.Inform_Backfire)
	testing.expect(t, !g.neighbours[5].naughty)
	testing.expect_value(t, g.merit, INFORM_FAIL_MERIT)
	testing.expect_value(t, g.dirt, 0)
}

@(test)
inform_spends_five_dirt_when_it_can :: proc(t: ^testing.T) {
	g := new_game(3)
	g.dirt = 7
	inform(&g, 0)
	testing.expect_value(t, g.dirt, 2)
}

@(test)
inform_rates_match_the_tuning :: proc(t: ^testing.T) {
	low, high := 0, 0
	for seed in u64(1) ..= 4000 {
		g := new_game(seed)
		g.dirt = 3
		if inform(&g, 0).kind == .Inform_Success {
			low += 1
		}
		g = new_game(seed)
		g.dirt = 5
		if inform(&g, 0).kind == .Inform_Success {
			high += 1
		}
	}
	testing.expect(t, abs(f64(low) / 4000 - INFORM_CHANCE_LOW) < 0.03)
	testing.expect(t, abs(f64(high) / 4000 - INFORM_CHANCE_HIGH) < 0.03)
}

@(test)
buying_is_free_of_actions_and_gifting_is_not :: proc(t: ^testing.T) {
	g := new_game(1)
	e := buy_gift(&g)
	testing.expect_value(t, e.kind, Event_Kind.Gift_Bought)
	testing.expect_value(t, g.coin, START_COIN - GIFT_PRICE)
	testing.expect_value(t, g.gifts, 1)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
	e = gift(&g, 2)
	testing.expect_value(t, e.kind, Event_Kind.Gift_Delivered)
	testing.expect_value(t, g.merit, GIFT_MERIT)
	testing.expect_value(t, g.neighbours[2].debt, GIFT_DEBT)
	testing.expect_value(t, g.gifts, 0)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY - 1)
}

@(test)
refusals_cost_nothing :: proc(t: ^testing.T) {
	g := new_game(1)
	testing.expect_value(t, gift(&g, 0).kind, Event_Kind.No_Gifts)
	testing.expect_value(t, inform(&g, 0).kind, Event_Kind.Not_Enough_Dirt)
	testing.expect_value(t, surveil(&g, 99).kind, Event_Kind.Bad_Target)
	testing.expect_value(t, surveil(&g, -1).kind, Event_Kind.Bad_Target)
	g.coin = 0
	testing.expect_value(t, buy_gift(&g).kind, Event_Kind.Not_Enough_Coin)
	g.neighbours[1].naughty = true
	g.neighbours[2].alive = false
	testing.expect_value(t, surveil(&g, 1).kind, Event_Kind.Bad_Target)
	testing.expect_value(t, surveil(&g, 2).kind, Event_Kind.Bad_Target)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
	testing.expect_value(t, g.dirt, 0)
	testing.expect_value(t, g.merit, 0)
}

@(test)
actions_run_out_after_three :: proc(t: ^testing.T) {
	g := new_game(1)
	g.dirt = 100
	for _ in 0 ..< ACTIONS_PER_DAY {
		testing.expect(t, surveil(&g, 4).kind != .No_Actions)
	}
	testing.expect_value(t, surveil(&g, 4).kind, Event_Kind.No_Actions)
	testing.expect_value(t, inform(&g, 4).kind, Event_Kind.No_Actions)
	g.gifts = 1
	testing.expect_value(t, gift(&g, 4).kind, Event_Kind.No_Actions)
}
