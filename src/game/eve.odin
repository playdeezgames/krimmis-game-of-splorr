package game

// Krimmis Eve. Call resolve_eve after end_day reports the Eve night (or whenever eve_reached is set).
//
// Standing at or above the Nice line is a promotion: you are Head Elf, handed next year's List, and the
// loop restarts one rung up. Below it is coal, and the run is over. Coal is the only way out.

resolve_eve :: proc(g: ^Game) -> Outcome {
	if !g.eve_reached {
		return g.outcome // still playing (or already coal)
	}
	if g.outcome == .Coal {
		return .Coal
	}
	if f64(standing(g)) < nice_line(DAYS, g.rung) {
		g.outcome = .Coal
		return .Coal
	}
	next_year(g)
	return .Promoted
}

// A new List, one rung up. Your Debt carries over (the reward for good service is more of the system),
// the Coin tops up to the starting purse, and Merit, Dirt, presents and Warnings reset. Survivors keep
// their Debt, grudges and role but start the year Nice; the neighbours the Coal Collection took are
// replaced by fresh families in the same houses.
@(private)
next_year :: proc(g: ^Game) {
	g.rung += 1
	g.day = 1
	g.actions = ACTIONS_PER_DAY
	g.merit = 0
	g.dirt = 0
	g.gifts = 0
	g.warnings = 0
	g.knocks = 0
	g.santa_watching = false
	g.coin = max(g.coin, START_COIN)
	g.eve_reached = false
	for &n, i in g.neighbours {
		if n.alive {
			n.suspicion = 0
			n.naughty = false
		} else {
			n = Neighbour{role = i, alive = true}
		}
	}
}
