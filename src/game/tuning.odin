package game

// Every balance number in one place. These mirror tools/balance_sim.py (the DEFAULTS in its P table);
// change them together and rerun the sim. Values come from the vault note's "Economy numbers" section.

DAYS :: 24 // days until Krimmis Eve
ACTIONS_PER_DAY :: 3
NEIGHBOURS :: 12

START_COIN :: 30
START_DEBT :: 30

// Surveil
SURVEIL_CHANCE :: 0.75
SURVEIL_DIRT :: 2
NOTICE_NOSY :: 3 // misses at which a nosy neighbour reports you
NOTICE_OBLIVIOUS :: 5 // misses at which an oblivious one does
GRUDGE_STEP :: 1 // a backfired Report leaves the neighbour with this much grudge
GRUDGE_CAP :: 1 // and a grudge makes them notice you up to this many misses sooner
NOTICE_PENALTY :: 5 // Merit lost when they do

// Inform
INFORM_COST_LOW :: 3 // Dirt
INFORM_COST_HIGH :: 5
INFORM_CHANCE_LOW :: 0.60
INFORM_CHANCE_HIGH :: 0.90
INFORM_MERIT :: 6
INFORM_FAIL_MERIT :: -3

// Gift
GIFT_PRICE :: 5 // Coin; rises by GIFT_PRICE_WEEKLY each week
GIFT_PRICE_WEEKLY :: 1
GIFT_MERIT :: 2
GIFT_DEBT :: 8 // added to the recipient

// Night
TITHE_DIVISOR :: 4 // a neighbour pays 1 Coin per 4 Debt
TITHE_CUT :: 0.5 // the share you keep
OWN_MIN_PAYMENT :: 1
OWN_INTEREST :: 0.03
COAL_EVERY :: 2 // the Coal Collection takes one Naughty every second night

// Standing and the Nice line
DEBT_PER_STANDING :: 5 // Standing = Merit - Debt / 5
LINE_BASE :: 10.0
LINE_SLOPE :: 1.7 // Nice line on day d = 10 + 1.7 d

// Promotion (the trap): each rung up makes the next year slightly harder. Debt carries over and is the
// main pressure; the Coin resets to START_COIN if it is lower (a Head Elf signing bonus). Paper-balanced in
// tools/balance_sim.py: the rung 1 win rate is about half, rung 2 about a fifth, and coal is the only exit.
RUNG_LINE_SLOPE :: 0.05 // added to LINE_SLOPE per rung
RUNG_INTEREST :: 0.002 // added to OWN_INTEREST per rung

// Night events: at most one a night, never on Krimmis Eve. One roll: audit, then tip-off, then Santa.
AUDIT_CHANCE :: 0.08 // Management audits: Merit up if your Standing is on pace, down if not
AUDIT_PASS :: 3
AUDIT_FAIL :: -3
TIP_CHANCE :: 0.10 // a neighbour slips you a note
TIP_DIRT :: 2
SANTA_CHANCE :: 0.06 // Kris Krinkle is seen on the street; everyone straightens up, one action fewer tomorrow
