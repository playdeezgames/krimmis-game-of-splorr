// All the rules of Krimmis live here, with no browser imports, so they build and test natively.
// The loop is specified in the vault note Games/Krimmis of SPLORR!!.md; tuning.odin holds the numbers.
package game

Outcome :: enum {
	Playing,
	Coal, // the run is over
	Promoted, // set only for the moment of promotion; the next year is already under way
}

Neighbour :: struct {
	role:       int, // index into the roster (the roster task fills these in)
	suspicion:  int, // how close they are to reporting you
	obliged:    int, // the favour they feel they owe you, in gifts delivered (returned in Coin each night)
	naughty:    bool, // on the Naughty List, waiting for the Coal Collection
	alive:      bool, // false once the Coal Collection has been
	grudge:     int, // how much they remember being informed on (used by the content task)
}

Game :: struct {
	day:        int, // 1 to DAYS
	actions:    int, // left today
	merit:      int,
	dirt:       int,
	gifts:      int, // wrapped presents bought and not yet delivered
	coin:       int,
	debt:       int, // your own Debt to Krimmis Inc.
	warnings:   int,
	santa_watching: bool, // Kris Krinkle was seen: one action fewer on the next day
	eve_reached: bool, // the night of day DAYS has run; the calendar is over
	rung:       int, // promotions so far: 0 is a mall-elf, 1 and up are Head Elf years
	outcome:    Outcome,
	neighbours: [NEIGHBOURS]Neighbour,
	rng:        Rng,
}

new_game :: proc(seed: u64) -> Game {
	g := Game {
		day     = 1,
		actions = ACTIONS_PER_DAY,
		coin    = START_COIN,
		debt    = START_DEBT,
		rng     = rng_seed(seed),
	}
	for &n, i in g.neighbours {
		n = Neighbour{role = i, alive = true}
	}
	return g
}

// Your rank on the Nice List: Merit less a fifth of your Debt.
standing :: proc(g: ^Game) -> int {
	return g.merit - g.debt / DEBT_PER_STANDING
}

// The Standing you must hold on a given day, steeper for each rung climbed.
nice_line :: proc(day: int, rung := 0) -> f64 {
	return LINE_BASE + (LINE_SLOPE + RUNG_LINE_SLOPE * f64(rung)) * f64(day)
}

// The most the Company Store card allows you to owe: raised a little with each promotion.
card_limit :: proc(g: ^Game) -> int {
	return CARD_LIMIT + RUNG_CARD_LIMIT * g.rung
}

alive_count :: proc(g: ^Game) -> int {
	count := 0
	for n in g.neighbours {
		if n.alive {
			count += 1
		}
	}
	return count
}

// How many misses a neighbour takes to report you: their trait's limit, one sooner with a grudge.
notice_limit :: proc(g: ^Game, i: int) -> int {
	base := NOTICE_NOSY if ROSTER[g.neighbours[i].role].trait == .Nosy else NOTICE_OBLIVIOUS
	return max(1, base - min(g.neighbours[i].grudge, GRUDGE_CAP))
}
