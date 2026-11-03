package game

// The night reckoning: tithes come in, your own Debt is paid down and grows, and the Coal Collection
// calls on a Naughty neighbour. The order matches tools/balance_sim.py.

Night_Report :: struct {
	refused:      bool, // the calendar was already over; nothing ran
	tithe_payers: int, // neighbours who paid a tithe
	tithe_coin:   int, // Coin you kept from the tithes
	removed:      int, // neighbour taken by the Coal Collection, or -1
	own_paid:     int, // Coin you paid on your own Debt
	own_missed:   int, // the part of the minimum payment you could not make (added to the Debt)
	interest:     int, // Debt added by interest
	eve:          bool, // this was the night of Krimmis Eve
}

// Ends the day and runs the reckoning. The night of day DAYS is Krimmis Eve: it runs, the day does not
// advance, and eve_reached is set (the ending is the Eve task's job). After that it refuses.
end_day :: proc(g: ^Game) -> Night_Report {
	if g.eve_reached {
		return Night_Report{refused = true, removed = -1}
	}
	r := Night_Report{removed = -1}

	// Tithes: each living, indebted neighbour pays a quarter of their Debt, rounded up. You keep half.
	for &n in g.neighbours {
		if !n.alive || n.debt <= 0 {
			continue
		}
		pay := min(n.debt, (n.debt + TITHE_DIVISOR - 1) / TITHE_DIVISOR)
		n.debt -= pay
		kept := int(f64(pay) * TITHE_CUT)
		g.coin += kept
		r.tithe_coin += kept
		r.tithe_payers += 1
	}

	// The Coal Collection, every second night, takes one Naughty neighbour at random.
	if g.day % COAL_EVERY == 0 {
		candidates: [NEIGHBOURS]int
		count := 0
		for n, i in g.neighbours {
			if n.alive && n.naughty {
				candidates[count] = i
				count += 1
			}
		}
		if count > 0 {
			pick := candidates[rng_int(&g.rng, count)]
			g.neighbours[pick].alive = false
			r.removed = pick
		}
	}

	// Your own Debt: the minimum payment (what you cannot pay is added), then interest.
	r.own_paid = min(g.coin, OWN_MIN_PAYMENT)
	g.coin -= r.own_paid
	g.debt -= r.own_paid
	r.own_missed = OWN_MIN_PAYMENT - r.own_paid
	g.debt += r.own_missed
	before := g.debt
	g.debt = int(f64(g.debt) * (1 + OWN_INTEREST + RUNG_INTEREST * f64(g.rung)))
	r.interest = g.debt - before

	if g.day >= DAYS {
		g.eve_reached = true
		r.eve = true
	} else {
		g.day += 1
		g.actions = ACTIONS_PER_DAY
	}
	return r
}
