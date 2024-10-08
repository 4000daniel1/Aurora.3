/obj/item/flame/candle
	name = "red candle"
	desc = "A small pillar candle. Its specially-formulated fuel-oxidizer wax mixture allows continued combustion in airless environments."
	icon = 'icons/obj/storage/fancy/candle.dmi'
	icon_state = "candle1"
	item_state = "candle1"
	drop_sound = 'sound/items/drop/gloves.ogg'
	pickup_sound = 'sound/items/pickup/gloves.ogg'
	w_class = WEIGHT_CLASS_TINY
	light_color = "#E09D37"
	var/wax = 3200
	var/start_lit = FALSE

/obj/item/flame/candle/Initialize()
	. = ..()
	wax = rand(2800, 3400)
	if(start_lit)
		light()

/obj/item/flame/candle/update_icon()
	var/i
	if(wax > 2000)
		i = 1
	else if(wax > 1200)
		i = 2
	else i = 3
	icon_state = "candle[i][lit ? "_lit" : ""]"


/obj/item/flame/candle/attackby(obj/item/attacking_item, mob/user)
	..()
	if(attacking_item.iswelder())
		var/obj/item/weldingtool/WT = attacking_item
		if(WT.isOn()) //Badasses dont get blinded by lighting their candle with a welding tool
			light()
			to_chat(user, SPAN_NOTICE("\The [user] casually lights \the [name] with [attacking_item]."))
	else if(attacking_item.isFlameSource())
		light()
		to_chat(user, SPAN_NOTICE("\The [user] lights \the [name]."))
	else if(istype(attacking_item, /obj/item/flame/candle))
		var/obj/item/flame/candle/C = attacking_item
		if(C.lit)
			light()
			to_chat(user, SPAN_NOTICE("\The [user] lights \the [name]."))

/obj/item/flame/candle/proc/light()
	if(!src.lit)
		src.lit = 1
		playsound(src.loc, 'sound/items/cigs_lighters/cig_light.ogg', 50, 1)
		//src.damtype = "fire"
		set_light(CANDLE_LUM)
		update_icon()
		START_PROCESSING(SSprocessing, src)

/obj/item/flame/candle/process(mob/user)
	if(!lit)
		return
	update_icon()
	wax--
	if(!wax)
		new /obj/item/trash/candle(src.loc)
		if(istype(src.loc, /mob))
			src.dropped(user)
		to_chat(user, SPAN_NOTICE("The candle burns out."))
		playsound(src.loc, 'sound/items/cigs_lighters/cig_snuff.ogg', 50, 1)
		STOP_PROCESSING(SSprocessing, src)
		qdel(src)
	update_icon()
	if(istype(loc, /turf)) //start a fire if possible
		var/turf/T = loc
		T.hotspot_expose(700, 5)

/obj/item/flame/candle/attack_self(mob/user as mob)
	if(lit)
		lit = 0
		to_chat(user, SPAN_NOTICE("You snuff out the flame."))
		playsound(src.loc, 'sound/items/cigs_lighters/cig_snuff.ogg', 50, 1)
		update_icon()
		set_light(0)
