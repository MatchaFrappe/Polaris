var/global/list/active_radio_jammers = list()

/proc/is_jammed(var/obj/radio)
	var/turf/Tr = get_turf(radio)
	if(!Tr) return 0 //Nullspace radios don't get jammed.

	for(var/jammer in active_radio_jammers)
		var/obj/item/device/radio_jammer/J = jammer
		var/turf/Tj = get_turf(J)

		if(J.on && Tj.z == Tr.z) //If we're on the same Z, it's worth checking.
			var/dist = get_dist(Tj,Tr)
			if(dist <= J.jam_range)
				return list("jammer" = J, "distance" = dist)

/obj/item/device/radio_jammer
	name = "subspace jammer"
	desc = "Primarily for blocking subspace communications, preventing the use of headsets, PDAs, and communicators."
	icon = 'icons/obj/device.dmi'
	icon_state = "jammer0"
	var/active_state = "jammer1"

	var/on = 0
	var/jam_range = 7
	var/obj/item/weapon/cell/device/weapon/power_source
	var/tick_cost = 80

	origin_tech = list(TECH_ILLEGAL = 7, TECH_BLUESPACE = 5) //Such technology! Subspace jamming!

/obj/item/device/radio_jammer/New()
	power_source = new(src)

/obj/item/device/radio_jammer/Destroy()
	if(on)
		turn_off()
	if(power_source)
		qdel(power_source)
	power_source = null
	..()

/obj/item/device/radio_jammer/proc/turn_off(mob/user)
	if(user)
		to_chat(user,"<span class='warning'>\The [src] deactivates.</span>")
	processing_objects.Remove(src)
	active_radio_jammers -= src
	on = FALSE
	icon_state = initial(icon_state)

/obj/item/device/radio_jammer/proc/turn_on(mob/user)
	if(user)
		to_chat(user,"<span class='notice'>\The [src] is now active.</span>")
	processing_objects.Add(src)
	active_radio_jammers += src
	on = TRUE
	icon_state = active_state

/obj/item/device/radio_jammer/process()
	if(!power_source || !power_source.check_charge(tick_cost))
		var/mob/living/notify
		if(isliving(loc))
			notify = loc
		turn_off(notify)
	else
		power_source.use(tick_cost)


/obj/item/device/radio_jammer/attack_hand(mob/user)
	if(user.get_inactive_hand() == src && power_source)
		to_chat(user,"<span class='notice'>You eject \the [power_source] from \the [src].</span>")
		user.put_in_hands(power_source)
		power_source = null
		turn_off()
	else
		return ..()

/obj/item/device/radio_jammer/attack_self(mob/user)
	if(on)
		turn_off(user)
	else
		if(power_source)
			turn_on(user)
		else
			to_chat(user,"<span class='warning'>\The [src] has no power source!</span>")

/obj/item/device/radio_jammer/attackby(obj/W, mob/user)
	if(istype(W,/obj/item/weapon/cell/device/weapon) && !power_source)
		power_source = W
		power_source.update_icon() //Why doesn't a cell do this already? :|
		user.unEquip(power_source)
		power_source.forceMove(src)
		to_chat(user,"<span class='notice'>You insert \the [power_source] into \the [src].</span>")
