#+build !js
package game

import "core:log"
import "core:testing"

// Parity with tools/balance_sim.py. The Python sim is where the numbers are tuned; these bots play the
// same four fixed policies against the real rules, and the win rates must land near the sim's. If this
// fails after a rules or tuning change, either the rules drifted or the sim needs the same change.
//
// Reference values (balance_sim.py, 10000 seeds, rung 0 unless stated):
//   greedy 0.525, informer 0.400, gifter 0.536, idle 0.000; mean promotions climbed: greedy 0.72, gifter 0.69.

@(private = "file")
Policy :: enum {
	Greedy,
	Informer,
	Gifter,
	Idle,
}

@(private = "file")
Act :: enum {
	None,
	Surveil,
	Inform,
	Gift,
}

// Neighbours you can act on, in house order.
@(private = "file")
nice_neighbours :: proc(g: ^Game, out: ^[NEIGHBOURS]int) -> int {
	count := 0
	for n, i in g.neighbours {
		if n.alive && !n.naughty {
			out[count] = i
			count += 1
		}
	}
	return count
}

@(private = "file")
decide :: proc(p: Policy, g: ^Game, nice_count: int) -> Act {
	afford := g.debt + store_price(g.day) <= card_limit(g) // the Store would not decline the card
	switch p {
	case .Idle:
		return .None
	case .Informer:
		return .Inform if g.dirt >= INFORM_COST_LOW else .Surveil
	case .Gifter:
		if afford {
			return .Gift
		}
		return .Inform if g.dirt >= INFORM_COST_LOW else .Surveil
	case .Greedy:
		if g.dirt >= INFORM_COST_LOW {
			return .Inform
		}
		if afford && g.day <= 18 && nice_count > 2 {
			return .Gift if g.day % 2 == 0 else .Surveil
		}
		return .Surveil
	}
	return .None
}

// Plays one year, from day 1 to the Eve night, the way the sim does. The bot's own RNG picks who to
// inform on or gift, so the game's RNG stream is only the rules'.
@(private = "file")
play_year :: proc(g: ^Game, p: Policy, bot: ^Rng) {
	nice: [NEIGHBOURS]int
	for _ in 1 ..= DAYS {
		acts := g.actions // Kris Krinkle can take one away
		for _ in 0 ..< acts {
			count := nice_neighbours(g, &nice)
			switch decide(p, g, count) {
			case .None:
			case .Surveil:
				if count > 0 {
					lowest := nice[0]
					for k in 1 ..< count {
						if g.neighbours[nice[k]].suspicion < g.neighbours[lowest].suspicion {
							lowest = nice[k]
						}
					}
					surveil(g, lowest)
				}
			case .Inform:
				if count > 0 {
					inform(g, nice[rng_int(bot, count)])
				}
			case .Gift:
				if count > 0 {
					buy_gift(g)
					gift(g, nice[rng_int(bot, count)])
				}
			}
		}
		end_day(g)
	}
}

@(private = "file")
first_year_win_rate :: proc(p: Policy, runs: int) -> f64 {
	wins := 0
	for seed in 0 ..< runs {
		g := new_game(u64(seed) + 1)
		bot := rng_seed(u64(seed) + 1_000_003)
		play_year(&g, p, &bot)
		if resolve_eve(&g) == .Promoted {
			wins += 1
		}
	}
	return f64(wins) / f64(runs)
}

// Promotions climbed before coal, the way tools/balance_sim.py's years() counts them.
@(private = "file")
mean_climbs :: proc(p: Policy, runs: int) -> f64 {
	total := 0
	for seed in 0 ..< runs {
		g := new_game(u64(seed) + 1)
		bot := rng_seed(u64(seed) + 1_000_003)
		for total < 100000 {
			play_year(&g, p, &bot)
			if resolve_eve(&g) != .Promoted {
				break
			}
			total += 1
		}
	}
	return f64(total) / f64(runs)
}

RATE_TOLERANCE :: 0.035
CLIMB_TOLERANCE :: 0.10

@(test)
first_year_win_rates_match_the_simulator :: proc(t: ^testing.T) {
	RUNS :: 4000
	greedy := first_year_win_rate(.Greedy, RUNS)
	informer := first_year_win_rate(.Informer, RUNS)
	gifter := first_year_win_rate(.Gifter, RUNS)
	log.infof("win rates: greedy %.3f informer %.3f gifter %.3f", greedy, informer, gifter)
	testing.expect(t, abs(greedy - 0.525) < RATE_TOLERANCE)
	testing.expect(t, abs(informer - 0.400) < RATE_TOLERANCE)
	testing.expect(t, abs(gifter - 0.536) < RATE_TOLERANCE)
	testing.expect_value(t, first_year_win_rate(.Idle, 500), 0.0)
}

@(test)
promotion_climbs_match_the_simulator :: proc(t: ^testing.T) {
	RUNS :: 3000
	greedy := mean_climbs(.Greedy, RUNS)
	gifter := mean_climbs(.Gifter, RUNS)
	log.infof("mean climbs: greedy %.3f gifter %.3f", greedy, gifter)
	testing.expect(t, abs(greedy - 0.72) < CLIMB_TOLERANCE)
	testing.expect(t, abs(gifter - 0.69) < CLIMB_TOLERANCE)
}
