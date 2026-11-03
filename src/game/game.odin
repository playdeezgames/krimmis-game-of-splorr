// All the rules of Krimmis live here, with no browser imports, so they build and test natively.
// This is the scaffold: the state and the calendar only. The loop is specified in the vault note
// Games/Krimmis of SPLORR!!.md and tools/balance_sim.py holds the tuned numbers.
package game

DAYS :: 24 // days until Krimmis Eve
ACTIONS_PER_DAY :: 3
NEIGHBOURS :: 12

Game :: struct {
	day:     int, // 1 to DAYS
	actions: int, // left today
}

new_game :: proc() -> Game {
	return Game{day = 1, actions = ACTIONS_PER_DAY}
}

// Ends the day. Returns false once Krimmis Eve has passed.
end_day :: proc(g: ^Game) -> bool {
	if g.day >= DAYS {
		return false
	}
	g.day += 1
	g.actions = ACTIONS_PER_DAY
	return true
}
