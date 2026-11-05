package game

import "core:math"

// The night reckoning: obliged neighbours return their favours, your own Debt is paid down and grows, and the
// Coal Collection calls on a Naughty neighbour. The order matches tools/balance_sim.py.

Night_Event :: enum {
	None,
	Audit_Pass, // Management audits you and is pleased
	Audit_Fail, // ...and is not
	Tip_Off, // a neighbour slips you a note
	Santa, // Kris Krinkle was seen: one action fewer tomorrow
}

Night_Report :: struct {
	refused:      bool, // the calendar was already over; nothing ran
	returners:     int, // neighbours who returned a favour
	favour_coin:   int, // Coin you kept from the favours returned
	removed:      int, // neighbour taken by the Coal Collection, or -1
	named:        bool, // the removed neighbour was clean: the street named them to fill the quota
	knocked:      bool, // the street named you instead (a Warning, KNOCK_PENALTY Merit)
	coal:         bool, // that was the last knock: coal now, and nothing after it ran
	own_paid:     int, // Coin you paid on your own Debt
	own_missed:   int, // the part of the card minimum you could not make (added to the Debt)
	interest:     int, // Debt added by interest
	eve:          bool, // this was the night of Krimmis Eve
	event:        Night_Event,
	event_amount: int, // Merit or Dirt the event gave or took
}

// Ends the day and runs the reckoning. The night of day DAYS is Krimmis Eve: it runs, the day does not
// advance, and eve_reached is set (the ending is the Eve task's job). After that, or after a coal knock, it refuses.
end_day :: proc(g: ^Game) -> Night_Report {
	if g.eve_reached || g.outcome == .Coal {
		return Night_Report{refused = true, removed = -1}
	}
	r := Night_Report{removed = -1}

	// Favours: each living, obliged neighbour returns a quarter of what they feel they owe, rounded up. You keep half.
	for &n in g.neighbours {
		if !n.alive || n.obliged <= 0 {
			continue
		}
		pay := min(n.obliged, (n.obliged + RETURN_DIVISOR - 1) / RETURN_DIVISOR)
		n.obliged -= pay
		kept := int(f64(pay) * RETURN_CUT)
		g.coin += kept
		r.favour_coin += kept
		r.returners += 1
	}

	// The Coal Collection, every second night, takes one Naughty neighbour at random. With nobody Naughty
	// the quota is still filled: the street names you (if you are behind the line, sometimes) or a neighbour.
	if g.day % COAL_EVERY == 0 {
		naughty, clean: [NEIGHBOURS]int
		n_naughty, n_clean := 0, 0
		for n, i in g.neighbours {
			switch {
			case n.alive && n.naughty:
				naughty[n_naughty] = i
				n_naughty += 1
			case n.alive:
				clean[n_clean] = i
				n_clean += 1
			}
		}
		switch {
		case n_naughty > 0:
			pick := naughty[rng_int(&g.rng, n_naughty)]
			g.neighbours[pick].alive = false
			r.removed = pick
		case (f64(standing(g)) < nice_line(g.day, g.rung) && rng_chance(&g.rng, QUOTA_YOU_CHANCE)) || n_clean == 0:
			r.knocked = true
			g.knocks += 1
			g.warnings += 1
			g.merit -= KNOCK_PENALTY
			if g.knocks >= KNOCK_LIMIT {
				g.outcome = .Coal
				r.coal = true
				return r
			}
		case:
			pick := clean[rng_int(&g.rng, n_clean)]
			g.neighbours[pick].alive = false
			r.removed = pick
			r.named = true
		}
	}

	// Your own Debt: the card minimum (what you cannot pay is added), then interest.
	due := max(OWN_MIN_PAYMENT, int(math.ceil(f64(g.debt) * OWN_MIN_RATE)))
	r.own_paid = min(g.coin, due)
	g.coin -= r.own_paid
	g.debt -= r.own_paid
	r.own_missed = due - r.own_paid
	g.debt += r.own_missed
	before := g.debt
	g.debt = int(f64(g.debt) * (1 + OWN_INTEREST + RUNG_INTEREST * f64(g.rung)))
	r.interest = g.debt - before

	if g.day >= DAYS {
		g.eve_reached = true
		r.eve = true
		return r
	}

	// One random event a night, never on Krimmis Eve.
	x := rng_float(&g.rng)
	switch {
	case x < AUDIT_CHANCE:
		if f64(standing(g)) >= nice_line(g.day, g.rung) {
			r.event, r.event_amount = .Audit_Pass, AUDIT_PASS
		} else {
			r.event, r.event_amount = .Audit_Fail, AUDIT_FAIL
		}
		g.merit += r.event_amount
	case x < AUDIT_CHANCE + TIP_CHANCE:
		r.event, r.event_amount = .Tip_Off, TIP_DIRT
		g.dirt += TIP_DIRT
	case x < AUDIT_CHANCE + TIP_CHANCE + SANTA_CHANCE:
		r.event = .Santa
		g.santa_watching = true
	}

	g.day += 1
	g.actions = ACTIONS_PER_DAY - (1 if g.santa_watching else 0)
	g.santa_watching = false
	return r
}
