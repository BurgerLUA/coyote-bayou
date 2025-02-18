/obj/item/ammo_casing/proc/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, damage_multiplier = 1, penetration_multiplier = 1, projectile_speed_multiplier = 1, atom/fired_from)
	distro += variance
	if(istype(BB))
		distro += BB.spread
	var/targloc = get_turf(target)
	ready_proj(target, user, quiet, zone_override, damage_multiplier, penetration_multiplier, projectile_speed_multiplier, fired_from, damage_threshold_penetration)
	if(pellets == 1)
		if(distro) //We have to spread a pixel-precision bullet. throw_proj was called before so angles should exist by now...
			if(HAS_TRAIT(user,TRAIT_FEV)) //You really shouldn't try this at home.
				spread += rand(-3,3) //YOU AINT HITTING SHIT BROTHA. REALLY.
			if(HAS_TRAIT(user,TRAIT_NEARSIGHT)) //Yes.
				spread += rand(-0.2,0.2) //You're slightly less accurate because you can't see well - as an upside, lasers don't suffer these penalties!
			if(HAS_TRAIT(user,TRAIT_POOR_AIM)) //You really shouldn't try this at home.
				spread += rand(-1.5,1.5)//This is cripplingly bad. Trust me.
			if(randomspread)
				spread *= distro
			else //Smart spread
				spread = round(1 - 0.5) * distro
		if(!throw_proj(target, targloc, user, params, spread))
			return FALSE
	else
		if(isnull(BB))
			return FALSE
		AddComponent(/datum/component/pellet_cloud, projectile_type, pellets)
		SEND_SIGNAL(src, COMSIG_PELLET_CLOUD_INIT, target, user, fired_from, randomspread, spread, zone_override, params, distro)

	user.DelayNextAction(considered_action = TRUE, immediate = FALSE)
	user.newtonian_move(get_dir(target, user))
	update_icon()
	return 1

/obj/item/ammo_casing/proc/ready_proj(atom/target, mob/living/user, quiet, zone_override = "", damage_multiplier = 1, penetration_multiplier = 1, projectile_speed_multiplier = 1, fired_from, damage_threshold_penetration = 0)
	if (!BB)
		return
	BB.original = target
	BB.firer = user
	BB.fired_from = fired_from
	if (zone_override)
		BB.def_zone = zone_override
	else
		BB.def_zone = user.zone_selected
	BB.suppressed = quiet
	BB.damage_threshold_penetration = damage_threshold_penetration

	if(isgun(fired_from))
		var/obj/item/gun/G = fired_from
		BB.damage *= G.damage_multiplier
		BB.armour_penetration *= G.penetration_multiplier
		BB.pixels_per_second *= G.projectile_speed_multiplier
		if(BB.zone_accuracy_type == ZONE_WEIGHT_GUNS_CHOICE)
			BB.zone_accuracy_type = G.get_zone_accuracy_type()
		if(HAS_TRAIT(user, TRAIT_INSANE_AIM))
			BB.ricochets_max = max(BB.ricochets_max, 10) //bouncy!
			BB.ricochet_chance = max(BB.ricochet_chance, 100) //it wont decay so we can leave it at 100 for always bouncing
			BB.ricochet_auto_aim_range = max(BB.ricochet_auto_aim_range, 3)
			BB.ricochet_auto_aim_angle = max(BB.ricochet_auto_aim_angle, 360) //it can turn full circle and shoot you in the face because our aim? is insane.
			BB.ricochet_decay_chance = 0
			BB.ricochet_decay_damage = max(BB.ricochet_decay_damage, 0.1)
			BB.ricochet_incidence_leeway = 0

	if(reagents && BB.reagents)
		reagents.trans_to(BB, reagents.total_volume) //For chemical darts/bullets
		qdel(reagents)

/obj/item/ammo_casing/proc/throw_proj(atom/target, turf/targloc, mob/living/user, params, spread)
	var/turf/curloc = get_turf(user)
	if (!istype(targloc) || !istype(curloc) || !BB)
		return 0

	var/firing_dir
	if(BB.firer)
		firing_dir = BB.firer.dir
	if(!BB.suppressed && firing_effect_type)
		new firing_effect_type(get_turf(src), firing_dir)

	var/direct_target
	if(targloc == curloc)
		if(target) //if the target is right on our location we'll skip the travelling code in the proj's fire()
			direct_target = target
	if(!direct_target)
		BB.preparePixelProjectile(target, user, params, spread)
	BB.fire(null, direct_target)
	BB = null
	deduct_powder_and_bullet_mats()
	return 1

/obj/item/ammo_casing/proc/spread(turf/target, turf/current, distro)
	var/dx = abs(target.x - current.x)
	var/dy = abs(target.y - current.y)
	return locate(target.x + round(gaussian(0, distro) * (dy+2)/8, 1), target.y + round(gaussian(0, distro) * (dx+2)/8, 1), target.z)
