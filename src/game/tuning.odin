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

// Gift: bought on the Company Store card (it adds to your own Debt, up to the card limit), then delivered.
GIFT_PRICE :: 5 // added to your Debt; rises by GIFT_PRICE_WEEKLY each week
GIFT_PRICE_WEEKLY :: 1
GIFT_MERIT :: 2
GIFT_OBLIGATION :: 12 // the favour the recipient now feels they owe you
CARD_LIMIT :: 50 // the Store declines a gift that would take your Debt past this
RUNG_CARD_LIMIT :: 40 // a Head Elf credit line increase, per promotion

// Night
RETURN_DIVISOR :: 4 // an obliged neighbour returns a quarter of the favour (1 Coin per 4), rounded up
RETURN_CUT :: 0.5 // the share of it you keep; the Company Store takes the rest
OWN_MIN_PAYMENT :: 1 // the card minimum is at least this...
OWN_MIN_RATE :: 0.05 // ...or this share of your Debt, rounded up, paid from your Coin
OWN_INTEREST :: 0.03
COAL_EVERY :: 2 // the Coal Collection takes one Naughty every second night

// The quota: when the Coal Collection calls and nobody is Naughty, the street names someone. If you are behind
// today's Nice line it is you with this chance (a knock: a Warning and lost Merit); otherwise a clean neighbour
// is taken. The third knock in a year is coal on the spot.
QUOTA_YOU_CHANCE :: 0.6
KNOCK_PENALTY :: 2
KNOCK_LIMIT :: 3

// Standing and the Nice line
DEBT_PER_STANDING :: 5 // Standing = Merit - Debt / 5
LINE_BASE :: 10.0
LINE_SLOPE :: 1.55 // Nice line on day d = 10 + 1.55 d (eased from 1.7 when the quota came in)

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
