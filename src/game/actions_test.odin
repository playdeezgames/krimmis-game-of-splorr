#+build !js
package game

import "core:strings"
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
	g.neighbours[0].suspicion = notice_limit(&g, 0) - 1
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
	testing.expect_value(t, g.debt, START_DEBT + GIFT_PRICE) // on the card
	testing.expect_value(t, g.coin, START_COIN)
	testing.expect_value(t, g.gifts, 1)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
	e = gift(&g, 2)
	testing.expect_value(t, e.kind, Event_Kind.Gift_Delivered)
	testing.expect_value(t, g.merit, GIFT_MERIT)
	testing.expect_value(t, g.neighbours[2].obliged, GIFT_OBLIGATION)
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
	g.debt = card_limit(&g) - 1
	testing.expect_value(t, buy_gift(&g).kind, Event_Kind.Card_Declined)
	testing.expect_value(t, g.debt, card_limit(&g) - 1)
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

@(test)
nosy_and_oblivious_neighbours_notice_at_different_misses :: proc(t: ^testing.T) {
	g := new_game(1)
	testing.expect_value(t, notice_limit(&g, 0), NOTICE_NOSY) // Karen
	testing.expect_value(t, notice_limit(&g, 1), NOTICE_OBLIVIOUS) // Maureen
}

@(test)
a_grudge_makes_a_neighbour_notice_one_miss_sooner_and_no_more :: proc(t: ^testing.T) {
	g := new_game(1)
	g.neighbours[1].grudge = 1
	testing.expect_value(t, notice_limit(&g, 1), NOTICE_OBLIVIOUS - 1)
	g.neighbours[1].grudge = 9
	testing.expect_value(t, notice_limit(&g, 1), NOTICE_OBLIVIOUS - GRUDGE_CAP)
}

@(test)
a_backfired_report_leaves_a_grudge :: proc(t: ^testing.T) {
	g := game_where_next_draw(INFORM_CHANCE_LOW, false)
	g.dirt = 3
	inform(&g, 6)
	testing.expect_value(t, g.neighbours[6].grudge, GRUDGE_STEP)
}

@(test)
the_roster_is_complete_and_balanced :: proc(t: ^testing.T) {
	nosy := 0
	for r in ROSTER {
		if r.trait == .Nosy {
			nosy += 1
		}
		testing.expect(t, len(r.short) > 0 && len(r.short) <= 8)
		testing.expect(t, len(r.full) > 0 && len(r.label) > 0 && len(r.taste) > 0)
		testing.expect(t, len(r.surveil) > 0 && len(r.report) > 0 && len(r.removed) > 0)
		testing.expect(t, len(r.surveil) <= 80 && len(r.report) <= 80 && len(r.removed) <= 80)
	}
	testing.expect_value(t, nosy, 6)
}

@(test)
no_roster_text_says_the_forbidden_word :: proc(t: ^testing.T) {
	for r in ROSTER {
		for text in ([?]string{r.short, r.full, r.label, r.taste, r.surveil, r.report, r.removed}) {
			lower := strings.to_lower(text, context.temp_allocator)
			testing.expect(t, !strings.contains(lower, "christmas") && !strings.contains(lower, "xmas"))
			testing.expect(t, !strings.contains(lower, "hallmark"))
		}
	}
}

@(test)
the_card_limit_rises_with_each_promotion :: proc(t: ^testing.T) {
	g := new_game(1)
	testing.expect_value(t, card_limit(&g), CARD_LIMIT)
	g.rung = 2
	testing.expect_value(t, card_limit(&g), CARD_LIMIT + 2 * RUNG_CARD_LIMIT)
}

@(test)
a_gift_that_fits_under_the_limit_is_charged_to_the_card :: proc(t: ^testing.T) {
	g := new_game(1)
	g.debt = card_limit(&g) - store_price(g.day) // exactly at the limit afterwards
	testing.expect_value(t, buy_gift(&g).kind, Event_Kind.Gift_Bought)
	testing.expect_value(t, g.debt, card_limit(&g))
	testing.expect_value(t, buy_gift(&g).kind, Event_Kind.Card_Declined)
	testing.expect_value(t, g.gifts, 1)
}
