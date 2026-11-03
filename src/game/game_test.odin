#+build !js
package game

import "core:testing"

@(test)
new_game_starts_on_day_one :: proc(t: ^testing.T) {
	g := new_game()
	testing.expect_value(t, g.day, 1)
	testing.expect_value(t, g.actions, ACTIONS_PER_DAY)
}

@(test)
calendar_stops_at_krimmis_eve :: proc(t: ^testing.T) {
	g := new_game()
	for _ in 1 ..< DAYS {
		testing.expect(t, end_day(&g))
	}
	testing.expect_value(t, g.day, DAYS)
	testing.expect(t, !end_day(&g))
}
