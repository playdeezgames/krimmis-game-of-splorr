package game

// Our own generator (xoshiro256**, seeded with splitmix64), so a seed gives the same run natively and
// in wasm and the tests are deterministic.
Rng :: struct {
	s: [4]u64,
}

rng_seed :: proc(seed: u64) -> Rng {
	r: Rng
	x := seed
	for i in 0 ..< 4 {
		x += 0x9e3779b97f4a7c15
		z := x
		z = (z ~ (z >> 30)) * 0xbf58476d1ce4e5b9
		z = (z ~ (z >> 27)) * 0x94d049bb133111eb
		r.s[i] = z ~ (z >> 31)
	}
	return r
}

rng_next :: proc(r: ^Rng) -> u64 {
	rotl :: #force_inline proc(x: u64, k: u64) -> u64 {
		return (x << k) | (x >> (64 - k))
	}
	result := rotl(r.s[1] * 5, 7) * 9
	t := r.s[1] << 17
	r.s[2] ~= r.s[0]
	r.s[3] ~= r.s[1]
	r.s[1] ~= r.s[2]
	r.s[0] ~= r.s[3]
	r.s[2] ~= t
	r.s[3] = rotl(r.s[3], 45)
	return result
}

// A float in [0, 1).
rng_float :: proc(r: ^Rng) -> f64 {
	return f64(rng_next(r) >> 11) * (1.0 / 9007199254740992.0)
}

// An int in [0, n). n must be above zero.
rng_int :: proc(r: ^Rng, n: int) -> int {
	return int(rng_next(r) % u64(n))
}

rng_chance :: proc(r: ^Rng, p: f64) -> bool {
	return rng_float(r) < p
}
