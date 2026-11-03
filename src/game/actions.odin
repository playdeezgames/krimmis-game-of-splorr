package game

// What a day's three actions do. Each proc returns an Event describing what happened, for the UI and the
// sounds, and never prints. A refused action (no actions left, a bad target, not enough Dirt or Coin) costs
// nothing. Buying presents at the Company Store is free of actions; surveilling, informing and delivering
// each cost one.

Event_Kind :: enum {
	None,
	// Refusals: nothing was spent.
	No_Actions,
	Bad_Target,
	Not_Enough_Dirt,
	Not_Enough_Coin,
	No_Gifts,
	// Outcomes.
	Surveil_Hit,
	Surveil_Miss,
	Noticed, // a miss that tipped the neighbour over the limit: they reported you
	Inform_Success,
	Inform_Backfire,
	Gift_Bought,
	Gift_Delivered,
}

Event :: struct {
	kind:   Event_Kind,
	target: int, // neighbour index, or -1
	amount: int, // Dirt gained, Merit change, Coin spent or Debt added, by kind
}

// The Company Store price, which creeps up a Coin each week.
store_price :: proc(day: int) -> int {
	return GIFT_PRICE + (day - 1) / 7 * GIFT_PRICE_WEEKLY
}

// Someone you can still act on: alive and not already on the Naughty List.
@(private)
valid_target :: proc(g: ^Game, target: int) -> bool {
	return target >= 0 && target < NEIGHBOURS && g.neighbours[target].alive && !g.neighbours[target].naughty
}

@(private)
refuse :: proc(kind: Event_Kind, target: int = -1) -> Event {
	return Event{kind = kind, target = target}
}

buy_gift :: proc(g: ^Game) -> Event {
	price := store_price(g.day)
	if g.coin < price {
		return refuse(.Not_Enough_Coin)
	}
	g.coin -= price
	g.gifts += 1
	return Event{kind = .Gift_Bought, target = -1, amount = price}
}

surveil :: proc(g: ^Game, target: int) -> Event {
	if g.actions <= 0 {
		return refuse(.No_Actions, target)
	}
	if !valid_target(g, target) {
		return refuse(.Bad_Target, target)
	}
	g.actions -= 1
	n := &g.neighbours[target]
	if rng_chance(&g.rng, SURVEIL_CHANCE) {
		g.dirt += SURVEIL_DIRT
		return Event{kind = .Surveil_Hit, target = target, amount = SURVEIL_DIRT}
	}
	n.suspicion += 1
	if n.suspicion >= NOTICE_LIMIT {
		n.suspicion = 0
		g.merit -= NOTICE_PENALTY
		g.warnings += 1
		return Event{kind = .Noticed, target = target, amount = -NOTICE_PENALTY}
	}
	return Event{kind = .Surveil_Miss, target = target}
}

// Spends 5 Dirt when you have it (a 90% report), otherwise 3 (60%).
inform :: proc(g: ^Game, target: int) -> Event {
	if g.actions <= 0 {
		return refuse(.No_Actions, target)
	}
	if !valid_target(g, target) {
		return refuse(.Bad_Target, target)
	}
	if g.dirt < INFORM_COST_LOW {
		return refuse(.Not_Enough_Dirt, target)
	}
	g.actions -= 1
	spend, chance := INFORM_COST_LOW, INFORM_CHANCE_LOW
	if g.dirt >= INFORM_COST_HIGH {
		spend, chance = INFORM_COST_HIGH, INFORM_CHANCE_HIGH
	}
	g.dirt -= spend
	if rng_chance(&g.rng, chance) {
		g.merit += INFORM_MERIT
		g.neighbours[target].naughty = true
		return Event{kind = .Inform_Success, target = target, amount = INFORM_MERIT}
	}
	g.merit += INFORM_FAIL_MERIT
	return Event{kind = .Inform_Backfire, target = target, amount = INFORM_FAIL_MERIT}
}

// Delivers one wrapped present. The recipient takes on Debt (the tithe) and you take the Merit.
gift :: proc(g: ^Game, target: int) -> Event {
	if g.actions <= 0 {
		return refuse(.No_Actions, target)
	}
	if !valid_target(g, target) {
		return refuse(.Bad_Target, target)
	}
	if g.gifts <= 0 {
		return refuse(.No_Gifts, target)
	}
	g.actions -= 1
	g.gifts -= 1
	g.merit += GIFT_MERIT
	g.neighbours[target].debt += GIFT_DEBT
	return Event{kind = .Gift_Delivered, target = target, amount = GIFT_DEBT}
}
