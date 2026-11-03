#+build !js
package game

import "core:testing"

@(test)
new_game_starts_on_day_one :: proc(t: ^testing.T) {
	g := new_game(1)
	testing.expect_value(t, g.day, 1)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
}

@(test)
new_game_has_starting_resources :: proc(t: ^testing.T) {
	g := new_game(1)
	testing.expect_value(t, g.coin, START_COIN)
	testing.expect_value(t, g.debt, START_DEBT)
	testing.expect_value(t, g.merit, 0)
	testing.expect_value(t, g.dirt, 0)
	testing.expect_value(t, g.warnings, 0)
}

@(test)
new_game_has_twelve_clean_living_neighbours :: proc(t: ^testing.T) {
	g := new_game(1)
	testing.expect_value(t, alive_count(&g), 12)
	for n, i in g.neighbours {
		testing.expect_value(t, n.role, i)
		testing.expect(t, n.alive && !n.naughty)
		testing.expect_value(t, n.suspicion, 0)
		testing.expect_value(t, n.debt, 0)
	}
}

@(test)
calendar_runs_to_krimmis_eve_then_refuses :: proc(t: ^testing.T) {
	g := new_game(1)
	for _ in 1 ..< DAYS {
		r := end_day(&g)
		testing.expect(t, !r.refused && !r.eve)
	}
	testing.expect_value(t, g.day, DAYS)
	testing.expect(t, !g.eve_reached)
	r := end_day(&g) // the night of Krimmis Eve still runs
	testing.expect(t, r.eve && !r.refused)
	testing.expect_value(t, g.day, DAYS)
	testing.expect(t, g.eve_reached)
	testing.expect(t, end_day(&g).refused)
}

@(test)
standing_is_merit_less_a_fifth_of_debt :: proc(t: ^testing.T) {
	g := new_game(1)
	g.merit = 40
	g.debt = 30
	testing.expect_value(t, standing(&g), 34)
}

@(test)
nice_line_matches_the_paper_numbers :: proc(t: ^testing.T) {
	testing.expect(t, abs(nice_line(DAYS) - 50.8) < 0.001)
	testing.expect(t, nice_line(1) < nice_line(2))
}

@(test)
rng_is_deterministic_per_seed :: proc(t: ^testing.T) {
	a := rng_seed(42)
	b := rng_seed(42)
	c := rng_seed(43)
	same := true
	differs := false
	for _ in 0 ..< 100 {
		x, y, z := rng_next(&a), rng_next(&b), rng_next(&c)
		same &&= x == y
		differs ||= x != z
	}
	testing.expect(t, same)
	testing.expect(t, differs)
}

@(test)
rng_ranges_and_chance_are_sane :: proc(t: ^testing.T) {
	r := rng_seed(7)
	hits := 0
	seen: [12]bool
	for _ in 0 ..< 20000 {
		f := rng_float(&r)
		testing.expect(t, f >= 0 && f < 1)
		seen[rng_int(&r, 12)] = true
		if rng_chance(&r, 0.75) {
			hits += 1
		}
	}
	for s in seen {
		testing.expect(t, s)
	}
	rate := f64(hits) / 20000
	testing.expect(t, rate > 0.73 && rate < 0.77)
}
