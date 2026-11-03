package game

// The twelve houses on the street, in house order (the neighbour at index i lives in house i + 1).
// Roles were chosen by the user and the text drafted by the agent; the vault note Games/Krimmis of SPLORR!!.md
// holds the same roster. Nothing here may say the forbidden word.

Trait :: enum {
	Nosy, // notices you sooner (NOTICE_NOSY misses)
	Oblivious, // notices you later (NOTICE_OBLIVIOUS misses)
}

Role :: struct {
	short:   string, // fits a house label (8 characters at most)
	full:    string,
	label:   string, // the cliche, "the Karen"
	trait:   Trait,
	taste:   string, // what they like in a gift (flavour only)
	surveil: string, // shown when Surveil finds Dirt
	report:  string, // shown when a Report succeeds
	removed: string, // shown when the Coal Collection takes them
}

ROSTER := [NEIGHBOURS]Role {
	{
		short = "Karen",
		full = "Karen Pemberton-Wise",
		label = "the Karen",
		trait = .Nosy,
		taste = "gift receipts, just in case",
		surveil = "Karen has drafted a strongly worded review of Krimmis. Dirt.",
		report = "Karen is Naughty. She demands to see your manager. You are the manager.",
		removed = "Karen asked the Coal Collection for their supervisor. It went poorly.",
	},
	{
		short = "Maureen",
		full = "Maureen Holloway",
		label = "the choir mum",
		trait = .Oblivious,
		taste = "sheet music and lozenges",
		surveil = "Maureen sings while she shreds her bills. The bills are interesting.",
		report = "Maureen is Naughty. Her descant has been entered as evidence.",
		removed = "The choir is down an alto. Nobody has mentioned it. Nobody will.",
	},
	{
		short = "Gary",
		full = "Gary Dunmore",
		label = "the inflatable-lawn guy",
		trait = .Oblivious,
		taste = "more inflatables",
		surveil = "Gary's electric bill could power a small moon. He is proud of this.",
		report = "Gary is Naughty. His inflatable snowman is already deflating in sympathy.",
		removed = "Gary's lawn slowly collapses. A single reindeer wheezes on.",
	},
	{
		short = "Doreen",
		full = "Doreen Applegate",
		label = "the fruitcake baker",
		trait = .Nosy,
		taste = "candied things",
		surveil = "Doreen's fruitcake has a tag from 2009. It is not hers.",
		report = "Doreen is Naughty. She is not surprised. She has been expecting you.",
		removed = "The Coal Collection took the fruitcake too. It is evidence now.",
	},
	{
		short = "Dale",
		full = "Dale Sweeney",
		label = "the ugly-sweater dad",
		trait = .Oblivious,
		taste = "a louder sweater",
		surveil = "Dale's sweater plays a tune. Dale cannot turn it off. Dale has stopped trying.",
		report = "Dale is Naughty. His sweater blinks 'help' in a code only he knows.",
		removed = "Dale's sweater was left in the road, still playing. It plays on.",
	},
	{
		short = "Ellen",
		full = "Ellen Marlowe",
		label = "the greeting-card-movie widow",
		trait = .Nosy,
		taste = "cocoa and a meaningful look",
		surveil = "Ellen has a lumberjack in the pantry. She says he is 'a contractor.'",
		report = "Ellen is Naughty. The inn will be saved. Probably by the Coal Collection.",
		removed = "Ellen's inn was saved by a man who looks suspiciously like the Collector.",
	},
	{
		short = "Tomasz",
		full = "Tomasz Brandt",
		label = "the overworked courier",
		trait = .Oblivious,
		taste = "a chair",
		surveil = "Tomasz napped on your porch for nine minutes. His route said six.",
		report = "Tomasz is Naughty. The delay is blamed on him. The delay is his own.",
		removed = "A package arrives for Tomasz. It is a letter from the Coal Collection.",
	},
	{
		short = "Hank",
		full = "Hank Brickell",
		label = "the mall-Santa moonlighter",
		trait = .Nosy,
		taste = "a hot toddy in a thermos",
		surveil = "Hank keeps a second, secret list. It is mostly about management.",
		report = "Hank is Naughty. He has asked the real one for a lawyer.",
		removed = "Hank's throne at the Mall stands empty. A sign reads 'BACK IN FIVE MINUTES.'",
	},
	{
		short = "Tiffany",
		full = "Tiffany Pruitt, age 8",
		label = "the wish-list kid",
		trait = .Oblivious,
		taste = "everything on the list",
		surveil = "Tiffany's list has a clause about 'unlimited returns, forever.'",
		report = "Tiffany is Naughty. The list is confiscated. It will not be returned.",
		removed = "Tiffany's list remains. It has found several new owners.",
	},
	{
		short = "Odessa",
		full = "Odessa Crumb",
		label = "the cookie-tin grandmother",
		trait = .Nosy,
		taste = "buttons, honestly",
		surveil = "Odessa's cookie tin contains thread. She offers you a cookie. It is thread.",
		report = "Odessa is Naughty. She forgives you. She is writing it down.",
		removed = "Odessa's tin is left on the step. It is, finally, full of cookies.",
	},
	{
		short = "Ebb",
		full = "Ebb Thornwick",
		label = "the Scrooge",
		trait = .Nosy,
		taste = "nothing, on principle (he will accept it)",
		surveil = "Ebb counts the Krimmis lights on the street and bills each house.",
		report = "Ebb is Naughty. He calls it the first honest thing the List has done.",
		removed = "Ebb wakes on Krimmis morning, visited by three ghosts. They are auditors.",
	},
	{
		short = "Skylar",
		full = "Skylar-Jade Vance",
		label = "the influencer",
		trait = .Oblivious,
		taste = "a ring light and an audience",
		surveil = "Skylar-Jade streams her ham. Four hundred people watch. You are in frame.",
		report = "Skylar-Jade is Naughty. Her followers are very sorry. They are also leaving.",
		removed = "Skylar-Jade's last post: 'Something is happening to the lights. #blessed.'",
	},
}
