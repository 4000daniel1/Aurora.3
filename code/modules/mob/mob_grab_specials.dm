
/obj/item/grab/proc/inspect_organ(mob/living/carbon/human/H, mob/user, var/target_zone)

	var/obj/item/organ/external/E = H.get_organ(target_zone)

	if(!E || E.is_stump())
		to_chat(user, SPAN_NOTICE("[H] is missing that bodypart."))
		return

	user.visible_message(SPAN_NOTICE("[user] starts inspecting [affecting]'s [E.name] carefully."))
	if(!do_mob(user,H, 10))
		to_chat(user, SPAN_NOTICE("You must stand still to inspect [E] for wounds."))
	else if(E.wounds.len)
		to_chat(user, SPAN_WARNING("You find [E.get_wounds_desc()]"))
	else
		to_chat(user, SPAN_NOTICE("You find no visible wounds."))

	to_chat(user, SPAN_NOTICE("Checking bones now..."))
	if(!do_mob(user, H, 20))
		to_chat(user, SPAN_NOTICE("You must stand still to feel [E] for fractures."))
	else if(E.status & ORGAN_BROKEN)
		to_chat(user, SPAN_WARNING("The [E.encased ? E.encased : "bone in the [E.name]"] moves slightly when you poke it!"))
		H.custom_pain("Your [E.name] hurts where it's poked.")
	else
		to_chat(user, SPAN_NOTICE("The [E.encased ? E.encased : "bones in the [E.name]"] seem to be fine."))

	to_chat(user, SPAN_NOTICE("Checking skin now..."))
	if(!do_mob(user, H, 10))
		to_chat(user, SPAN_NOTICE("You must stand still to check [H]'s skin for abnormalities."))
	else
		var/bad = 0
		if(H.getToxLoss() >= 40)
			to_chat(user, SPAN_WARNING("[H] has an unhealthy skin discoloration."))
			bad = 1
		if(H.getOxyLoss() >= 20)
			to_chat(user, SPAN_WARNING("[H]'s skin is unusually pale."))
			bad = 1
		if(E.is_infected())
			var/severity = E.germ_level < INFECTION_LEVEL_TWO ? "slightly" : E.germ_level < INFECTION_LEVEL_THREE ? "moderately" : "extremely"
			to_chat(user, SPAN_WARNING("[H]'s skin is [severity] warm and reddened."))
			bad = 1
		if(E.status & ORGAN_DEAD)
			to_chat(user, SPAN_WARNING("[E] is decaying!"))
			bad = 1
		if(!bad)
			to_chat(user, SPAN_NOTICE("[H]'s skin is normal."))

/obj/item/grab/proc/jointlock(mob/living/carbon/human/target, mob/attacker, var/target_zone)
	if(state < GRAB_AGGRESSIVE)
		to_chat(attacker, SPAN_WARNING("You require a better grab to do this."))
		return

	var/obj/item/organ/external/organ = target.get_organ(check_zone(target_zone))
	if(!organ || organ.dislocated == -1)
		return

	attacker.visible_message(SPAN_DANGER("[attacker] [pick("bent", "twisted")] [target]'s [organ.name] into a jointlock!"))
	var/armor = 100 * affecting.get_blocked_ratio(target, DAMAGE_BRUTE, damage = 30)
	if(armor < 70)
		to_chat(target, SPAN_DANGER("You feel extreme pain!"))
		affecting.adjustHalLoss(clamp(0, 60 - affecting.getHalLoss(), 30)) //up to 60 halloss

/obj/item/grab/proc/attack_eye(mob/living/carbon/human/target, mob/living/carbon/human/attacker)
	if(!istype(attacker))
		return

	var/datum/unarmed_attack/attack = attacker.get_unarmed_attack(target, BP_EYES)

	if(!attack)
		return
	if(state < GRAB_NECK)
		to_chat(attacker, SPAN_WARNING("You require a better grab to do this."))
		return
	for(var/obj/item/protection in list(target.head, target.wear_mask, target.glasses))
		if(protection && (protection.body_parts_covered & EYES))
			to_chat(attacker, SPAN_DANGER("You're going to need to remove the eye covering first."))
			return
	if(!target.has_eyes())
		to_chat(attacker, SPAN_DANGER("You cannot locate any eyes on [target]!"))
		return
	if(isipc(target))
		to_chat(attacker, SPAN_DANGER("You cannot damage [target]'s optics with your bare hands!"))
		return

	admin_attack_log(attacker, target, "attacked [target.name]'s eyes using a grab.", "had eyes attacked by [attacker.name]'s grab.", "used a grab to attack eyes of")

	attack.handle_eye_attack(attacker, target)

/obj/item/grab/proc/headbutt(mob/living/carbon/human/target, mob/living/carbon/human/attacker)
	if(!istype(attacker))
		return
	if(target.lying)
		return
	attacker.visible_message(SPAN_DANGER("[attacker] thrusts [attacker.get_pronoun("his")] head into [target]'s skull!"))

	var/damage = 15
	if(attacker.mob_size >= 10)
		damage += min(attacker.mob_size, 20)

	if(isunathi(attacker))
		damage += 5

	target.apply_damage(damage, DAMAGE_BRUTE, BP_HEAD)
	attacker.apply_damage(10, DAMAGE_BRUTE, BP_HEAD)

	var/targetarmor = 100 * target.get_blocked_ratio(BP_HEAD, DAMAGE_BRUTE, damage = damage)
	var/attackerarmor = 100 * attacker.get_blocked_ratio(BP_HEAD, DAMAGE_BRUTE, damage = damage)
	if((targetarmor < 25 || targetarmor < attackerarmor) && target.headcheck(BP_HEAD) && prob(damage))
		target.apply_effect(20, PARALYZE)
		target.visible_message(SPAN_DANGER("[target] [target.species.knockout_message]"))
	if(attackerarmor < targetarmor && attacker.headcheck(BP_HEAD) && prob(damage))
		attacker.apply_effect(20, PARALYZE)
		attacker.visible_message(SPAN_DANGER("[attacker] [attacker.species.knockout_message]"))

	playsound(attacker.loc, /singleton/sound_category/swing_hit_sound, 25, 1, -1)
	attacker.attack_log += "\[[time_stamp()]\] <span class='warning'>Headbutted [target.name] ([target.ckey])</span>"
	target.attack_log += "\[[time_stamp()]\] <font color='orange'>Headbutted by [attacker.name] ([attacker.ckey])</font>"
	msg_admin_attack("[key_name(attacker)] has headbutted [key_name(target)]",ckey=key_name(attacker),ckey_target=key_name(target))

	qdel(src)
	return

/obj/item/grab/proc/dislocate(mob/living/carbon/human/target, mob/living/attacker, var/target_zone)
	if(state < GRAB_NECK)
		to_chat(attacker, SPAN_WARNING("You require a better grab to do this."))
		return
	if(target.grab_joint(attacker, target_zone))
		playsound(loc, 'sound/weapons/push_connect.ogg', 50, 1, -1)
		return

/obj/item/grab/proc/pin_down(mob/target, mob/attacker)
	if(state < GRAB_AGGRESSIVE)
		to_chat(attacker, SPAN_WARNING("You require a better grab to do this."))
		return
	if(force_down)
		to_chat(attacker, SPAN_WARNING("You are already pinning [target] to the ground."))

	attacker.visible_message(SPAN_DANGER("[attacker] starts forcing [target] to the ground!"))
	if(do_after(attacker, 20) && target)
		last_action = world.time
		attacker.visible_message(SPAN_DANGER("[attacker] forces [target] to the ground!"))
		apply_pinning(target, attacker)

/obj/item/grab/proc/apply_pinning(mob/target, mob/attacker)
	force_down = 1
	target.Weaken(3)
	target.lying = 1
	step_to(attacker, target)
	attacker.set_dir(EAST) //face the victim
	target.set_dir(SOUTH) //face up

/obj/item/grab/proc/devour(mob/target, mob/user)
	var/mob/living/carbon/human/H = user
	H.devour(target)


/obj/item/grab/proc/hair_pull(mob/living/carbon/human/target, mob/attacker, var/target_zone)


	var/datum/sprite_accessory/hair/hair_style = GLOB.hair_styles_list[target.h_style]
	var/hairchatname = hair_style.chatname
	for(var/obj/item/protection in list(target.head, target.wear_mask))
		if(protection && (protection.body_parts_covered & HEAD))
			to_chat(assailant, SPAN_WARNING("You can't tug their hair while something is covering it!."))
			return
	switch(hair_style.length)
		if(0)
			visible_message(SPAN_NOTICE("[assailant] tried to grab [target] but they have no hair!"))
		if(1)
			visible_message(SPAN_DANGER("[assailant] tugs [target]'s [hairchatname] before releasing their grip!"))
			target.apply_damage(5, DAMAGE_PAIN)
		if(2)
			visible_message(SPAN_DANGER("[assailant] tugs [target]'s [hairchatname]!"))
			target.apply_damage(5, DAMAGE_PAIN)
			src.state = GRAB_PASSIVE

		if(3)
			visible_message(SPAN_DANGER("[assailant] tugs [target]'s [hairchatname]!"))
			target.apply_damage(10, DAMAGE_PAIN)
			src.state = GRAB_PASSIVE

		if(4)
			visible_message(SPAN_DANGER("[assailant] violently tugs [target]'s [hairchatname], ripping out a clump!"))
			target.apply_damage(15, DAMAGE_PAIN)
			src.state = GRAB_PASSIVE

		if(5)
			if(prob(77))
				visible_message(SPAN_DANGER("[assailant] has [target] grasped by their [hairchatname], however suddenly it slips from  [assailant]'s hand!"))
				src.state = GRAB_PASSIVE
			else
				visible_message(SPAN_DANGER("[assailant] violently tugs [target]'s [hairchatname]!"))
				target.apply_damage(10, DAMAGE_PAIN)
				src.state = GRAB_AGGRESSIVE

		if(6)
			if(prob(67))
				visible_message(SPAN_DANGER("[assailant] has [target] grasped by their [hairchatname], however suddenly it slips from  [assailant]'s hand!"))
				src.state = GRAB_PASSIVE
				playsound(target.loc, 'sound/misc/slip.ogg', 50, 1, -3)
			else
				visible_message(SPAN_DANGER("[assailant] violently tugs [target]'s [hairchatname]!"))
				target.apply_damage(15, DAMAGE_PAIN)
				src.state = GRAB_AGGRESSIVE
