/mob/living/simple_animal/hostile/faithless
	name = "faithless"
	desc = "A creature. Darkness incarnate?"
	icon = 'icons/mob/npc/human.dmi'
	icon_state = "faithless"
	icon_living = "faithless"
	icon_dead = "faithless_dead"
	speak_chance = 0
	turns_per_move = 5
	organ_names = list("chest", "lower body", "left arm", "right arm", "left leg", "right leg", "head")
	response_help = "passes through"
	response_disarm = "shoves"
	response_harm = "hits"
	speed = 4
	maxHealth = 80
	health = 80
	environment_smash = 2

	tameable = FALSE

	melee_damage_lower = 15
	melee_damage_upper = 15
	attacktext = "gripped"
	attack_sound = 'sound/hallucinations/growl1.ogg'

	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0

	faction = "faithless"

	flying = TRUE

	psi_pingable = FALSE
	sample_data = null

/mob/living/simple_animal/hostile/faithless/Allow_Spacemove(var/check_drift = 0)
	return 1

/mob/living/simple_animal/hostile/faithless/FindTarget()
	var/my_target = last_found_target
	. = ..()
	if(. && (prob(30) || (. != my_target)))
		audible_emote("wails at [.]")

/mob/living/simple_animal/hostile/faithless/AttackingTarget()
	. =..()
	var/mob/living/L = .
	if(istype(L))
		if(prob(12))
			L.Weaken(3)
			L.visible_message(SPAN_DANGER("\the [src] knocks down \the [L]!"))

/mob/living/simple_animal/hostile/faithless/cult
	faction = "cult"
	appearance_flags = NO_CLIENT_COLOR

/mob/living/simple_animal/hostile/faithless/cult/cultify()
	return

/mob/living/simple_animal/hostile/faithless/cult/Life(seconds_per_tick, times_fired)
	..()
	check_horde()

/mob/living/simple_animal/hostile/faithless/can_fall()
	return FALSE

/mob/living/simple_animal/hostile/faithless/can_ztravel()
	return TRUE

/mob/living/simple_animal/hostile/faithless/CanAvoidGravity()
	return TRUE
