/mob/living/silicon/ai/Life(seconds_per_tick, times_fired)
	if(!..())
		return FALSE

	if (src.stat == DEAD)
		return FALSE

	if (src.stat!=CONSCIOUS)
		src.cameraFollow = null
		src.reset_view(null)

	src.updatehealth()

	if (hardware_integrity() <= 0 || backup_capacitor() <= 0)
		death()
		return

	// If our powersupply object was destroyed somehow, create new one.
	if(!psupply)
		create_powersupply()


	// Handle power damage (oxy)
	if(ai_restore_power_routine != 0 && !APU_power)
		// Lose power
		adjustOxyLoss(1)
	else
		// Gain Power
		ai_restore_power_routine = 0 // Necessary if AI activated it's APU AFTER losing primary power.
		adjustOxyLoss(-1)

	handle_stunned()	// Handle EMP-stun
	lying = 0			// Handle lying down

	malf_process()

	if(APU_power && (hardware_integrity() < 50))
		to_chat(src, SPAN_NOTICE("<b>APU GENERATOR FAILURE! (System Damaged)</b>"))
		stop_apu(1)

	if (!is_blind())
		if (ai_restore_power_routine==2)
			to_chat(src, "Alert cancelled. Power has been restored without our assistance.")
			ai_restore_power_routine = 0
			clear_fullscreen("blind")
			update_icon()
			return
		else if (ai_restore_power_routine==3)
			to_chat(src, "Alert cancelled. Power has been restored.")
			ai_restore_power_routine = 0
			clear_fullscreen("blind")
			update_icon()
			return
		else if (APU_power)
			ai_restore_power_routine = 0
			clear_fullscreen("blind")
			update_icon()
			return
	else
		var/area/current_area = get_area(src)

		if(lacks_power())
			if(ai_restore_power_routine==0)
				INVOKE_ASYNC(src, PROC_REF(handle_power_loss), current_area)


	process_queued_alarms()
	handle_regular_hud_updates()
	switch(src.sensor_mode)
		if (SEC_HUD)
			process_sec_hud(src,0,src.eyeobj)
		if (MED_HUD)
			process_med_hud(src,0,src.eyeobj)

	return TRUE

/**
 * Handles the power loss for the AI
 *
 * Broken up from the Life() proc so it can be done async, I claim no part in the creation of this abhorrent mess
 * apart from copying the code from the aforementioned proc
 */
/mob/living/silicon/ai/proc/handle_power_loss(area/current_area)
	ai_restore_power_routine = 1

	var/turf/T = get_turf(src)

	//Now to tell the AI why they're blind and dying slowly.
	to_chat(src, "You've lost power!")

	spawn(20)
		to_chat(src, "Backup battery online. Scanners, camera, and radio interface offline. Beginning fault-detection.")
		sleep(50)
		if (current_area.power_equip)
			if (!istype(T, /turf/space))
				to_chat(src, "Alert cancelled. Power has been restored without our assistance.")
				ai_restore_power_routine = 0
				clear_fullscreen("blind")
				return
		to_chat(src, "Fault confirmed: missing external power. Shutting down main control system to save power.")
		sleep(20)
		to_chat(src, "Emergency control system online. Verifying connection to power network.")
		sleep(50)
		if (istype(T, /turf/space))
			to_chat(src, "Unable to verify! No power connection detected!")
			ai_restore_power_routine = 2
			return
		to_chat(src, "Connection verified. Searching for APC in power network.")
		sleep(50)
		var/obj/machinery/power/apc/theAPC = null

		var/PRP
		for (PRP=1, PRP<=4, PRP++)
			for (var/obj/machinery/power/apc/APC in current_area)
				if (!(APC.stat & BROKEN))
					theAPC = APC
					break
			if (!theAPC)
				switch(PRP)
					if (1) to_chat(src, "Unable to locate APC!")
					else to_chat(src, "Lost connection with the APC!")
				ai_restore_power_routine = 2
				return
			if (current_area.power_equip)
				if (!istype(T, /turf/space))
					to_chat(src, "Alert cancelled. Power has been restored without our assistance.")
					ai_restore_power_routine = 0
					clear_fullscreen("blind")
					return
			switch(PRP)
				if (1) to_chat(src, "APC located. Optimizing route to APC to avoid needless power waste.")
				if (2) to_chat(src, "Best route identified. Hacking offline APC power port.")
				if (3) to_chat(src, "Power port upload access confirmed. Loading control program into APC power port software.")
				if (4)
					to_chat(src, "Transfer complete. Forcing APC to execute program.")
					sleep(50)
					to_chat(src, "Receiving control information from APC.")
					sleep(2)
					theAPC.operating = 1
					theAPC.equipment = 3
					theAPC.update()
					ai_restore_power_routine = 3
					to_chat(src, "Here are your current laws:")
					show_laws()
					update_icon()
			sleep(50)
			theAPC = null

/mob/living/silicon/ai/proc/lacks_power()
	if(APU_power)
		return 0
	var/turf/T = get_turf(src)
	var/area/A = get_area(src)
	return ((!A.power_equip) && A.requires_power == 1 || istype(T, /turf/space)) && !istype(src.loc,/obj/item)

/mob/living/silicon/ai/rejuvenate()
	var/was_dead = stat == DEAD

	..()

	if(was_dead && stat != DEAD)
		// Arise!
		GLOB.cameranet.update_visibility(src, FALSE)

	add_ai_verbs(src)

/mob/living/silicon/ai/update_sight()
	if(is_blind())
		update_icon()
		overlay_fullscreen("blind", /atom/movable/screen/fullscreen/blind)
		set_sight(sight&(~SEE_TURFS)&(~SEE_MOBS)&(~SEE_OBJS))
		set_see_invisible(SEE_INVISIBLE_LIVING)
	else if(stat == DEAD)
		update_dead_sight()
	else
		set_sight(sight|SEE_TURFS|SEE_MOBS|SEE_OBJS)
		set_see_invisible(SEE_INVISIBLE_LIVING)

/mob/living/silicon/ai/is_blind()
	var/area/A = get_area(src)
	if (A && !A.power_equip && !istype(src.loc,/obj/item) && !APU_power)
		return TRUE
	return FALSE
