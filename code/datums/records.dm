// Generic data stored in record
/datum/record
	var/name
	var/id
	var/notes = "No notes found."

	var/cmp_field = "id"
	var/list/excluded_fields
	var/list/excluded_print_fields

/datum/record/New()
	..()
	var/tmp_ex = excluded_fields
	excluded_fields = list()
	for(var/f in tmp_ex)
		excluded_fields[f] = f
	tmp_ex = excluded_print_fields
	excluded_print_fields = list()
	for(var/f in tmp_ex)
		excluded_print_fields[f] = f

/datum/record/proc/Copy(var/datum/copied)
	if(!copied)
		copied = new src.type()
	var/exclusions = (SSrecords.excluded_fields | src.excluded_fields)
	for(var/variable in src.vars)
		if(exclusions[variable]) continue
		if(istype(src.vars[variable], /datum/record) || istype(src.vars[variable], /list))
			var/list/V = vars[variable]
			copied.vars[variable] = V.Copy()
		else
			copied.vars[variable] = src.vars[variable]
	return copied

#define CONDITIONAL_HTML_DECODE(VAR)\
	if(decode_html){\
		if(istext(##VAR)){\
			##VAR = html_decode(##VAR);\
		}\
	}

/datum/record/proc/Listify(var/deep = 1, var/list/excluded = list(), var/list/to_update, decode_html = FALSE) // Mostly to support old things or to use with serialization
	var/list/record
	if(!to_update)
		. = record = list()
	else
		record = to_update || list()
	var/tmp_ex = excluded
	excluded = list()
	for(var/e in tmp_ex)
		excluded[e] = e
	var/exclusions = (SSrecords.excluded_fields | src.excluded_fields | excluded)
	for(var/variable in src.vars)
		if(!exclusions[variable])
			if(deep && (istype(src.vars[variable], /datum/record)))
				if(to_update)
					var/datum/record/R = src.vars[variable]
					var/listified = R.Listify(to_update = to_update[variable], decode_html = decode_html)
					if(listified)
						record[variable] = listified
						CONDITIONAL_HTML_DECODE(record[variable])
						. = record
				else
					var/datum/record/R = src.vars[variable]
					record[variable] = R.Listify(decode_html = decode_html)
					//no escape
			else if(deep && islist(src.vars[variable]) && is_list_containing_type(src.vars[variable], /datum/record))
				record[variable] = list()
				for(var/subr in src.vars[variable])
					var/datum/record/r = subr
					record[variable] += list(r.Listify(decode_html = decode_html))
				var/llen = 0
				if((variable in to_update) && islist(to_update[variable]))
					var/list/L = to_update[variable]
					llen = L.len
				if(llen != LAZYLEN(record[variable]))
					. = record
					CONDITIONAL_HTML_DECODE(.)
			else if(islist(src.vars[variable]) || istext(src.vars[variable]) || isnum(src.vars[variable]))
				if(to_update && record[variable] != src.vars[variable])
					record[variable] = src.vars[variable]
					CONDITIONAL_HTML_DECODE(record[variable])
					. = record
				else if(!to_update)
					record[variable] = src.vars[variable]
					CONDITIONAL_HTML_DECODE(record[variable])

#undef CONDITIONAL_HTML_DECODE


/datum/record/proc/Printify(var/list/excluded = list()) // Mostly to support old things or to use with serialization
	. = ""
	var/tmp_ex = excluded
	excluded = list()
	for(var/e in tmp_ex)
		excluded[e] = e
	var/exclusions = (SSrecords.excluded_fields | src.excluded_fields | excluded | src.excluded_print_fields)
	var/extendedVars = list() // To put last
	for(var/variable in src.vars)
		if(!exclusions[variable])
			if(istype(src.vars[variable], /datum/record))
				var/datum/record/R = src.vars[variable]
				extendedVars[variable] = R
				// . += "<h3>[variable]</h3>"
				// . += src.vars[variable].Printify()
			else if(istype(src.vars[variable], /list))
				. += "<b>[get_field_name(variable)]:</b><br>"
				. += jointext(src.vars[variable], "<br>")
			else if(istext(src.vars[variable]) || isnum(src.vars[variable]))
				. += "<b>[get_field_name(variable)]:</b> [src.vars[variable]]<br>"
	for(var/variable in extendedVars)
		. += "<center><h3>[get_field_name(variable)]</h3></center>"
		var/datum/record/R = src.vars[variable]
		. += R.Printify()

/datum/record/proc/get_field_name(var/field)
	. = SSrecords.localized_fields[src.type][field]
	if(!.)
		return capitalize(replacetext(field, "_", " "))

// Record for storing general data, data tree top level datum
/datum/record/general
	name = "New Record"
	var/real_rank = "Unassigned"
	var/rank = "Unassigned"
	var/age = 0
	var/sex = "Unknown"
	var/fingerprint = "Unknown"
	var/physical_status = "Active"
	var/mental_status = "Stable"
	var/species = "Unknown"
	var/citizenship = "Unknown"
	var/employer = "Unknown"
	var/religion = "Unknown"
	var/ccia_record = "No CCIA records found"
	var/list/ccia_actions = list()
	var/icon/photo_front
	var/icon/photo_side
	var/datum/record/medical/medical
	var/datum/record/security/security
	var/list/advanced_fields = list("species", "citizenship", "employer", "religion", "ccia_record", "ccia_actions")
	cmp_field = "name"
	excluded_fields = list("photo_front", "photo_side", "advanced_fields", "real_rank")
	excluded_print_fields = list("ccia_actions")

/datum/record/general/New(var/mob/living/carbon/human/H, var/nid)
	..()
	if (!H)
		var/mob/living/carbon/human/dummy/mannequin/dummy = SSmobs.get_mannequin("New record")
		photo_front = getFlatIcon(dummy, SOUTH)
		photo_side = getFlatIcon(dummy, WEST)
	else
		photo_front = getFlatIcon(H, SOUTH)
		photo_side = getFlatIcon(H, WEST)
	if(!nid)
		nid = generate_record_id()
	id = nid
	if(H)
		name = H.real_name
		real_rank = H.mind.assigned_role
		rank = GetAssignment(H, TRUE)
		age = H.age
		fingerprint = md5(H.dna.uni_identity)
		sex = H.species.get_species_record_sex(H)
		species = H.get_species(FALSE, TRUE)
		citizenship = SSrecords.get_citizenship_record_name(H.citizenship)
		employer = H.employer_faction
		religion = SSrecords.get_religion_record_name(H.religion)
		ccia_record = H.ccia_record
		ccia_actions = H.ccia_actions
		if(H.gen_record && !jobban_isbanned(H, "Records"))
			notes = H.gen_record
	medical = new(H, id)
	security = new(H, id)


// Record for locked data
/datum/record/general/locked
	var/nid = ""
	var/enzymes
	var/identity
	var/exploit_record

/datum/record/general/locked/New(var/mob/living/carbon/human/H)
	..()
	// Only init things that are needed
	if(H)
		nid = md5("[H.real_name][H.mind.assigned_role]")
		enzymes = H.dna.SE
		identity = H.dna.UI
		if(H.exploit_record && !jobban_isbanned(H, "Records"))
			exploit_record = H.exploit_record

// Record for storing medical data
/datum/record/medical
	var/blood_type = "AB+"
	var/blood_dna = "63920c3ec24b5d57d459b33a2f4d6446"
	var/disabilities = "No disabilities have been declared."
	var/allergies = "No allergies have been detected in this patient."
	var/diseases = "No diseases have been diagnosed at the moment."
	var/list/comments = list()

/datum/record/medical/New(var/mob/living/carbon/human/H, var/nid)
	..()
	if(!nid)
		nid = generate_record_id()
	id = nid
	if(H)
		blood_type = H.b_type
		blood_dna = H.dna.unique_enzymes
		if(H.med_record && !jobban_isbanned(H, "Records"))
			notes = H.med_record

// Record for storing security data
/datum/record/security
	var/criminal = "None"
	var/crimes = "No criminal record."
	var/list/incidents = list()
	var/list/comments = list()

/datum/record/security/New(var/mob/living/carbon/human/H, var/nid)
	..()
	if(!nid)
		nid = generate_record_id()
	id = nid
	if(H)
		incidents = H.incidents
		if(H.sec_record && !jobban_isbanned(H, "Records"))
			notes = H.sec_record


// Digital warrant
/datum/record/warrant
	name = "Unknown"
	notes = "No charges present"
	cmp_field = "name"

	var/authorization = "Unauthorized"
	var/wtype = "Unknown"

GLOBAL_VAR_INIT(warrant_uid, 0)
/datum/record/warrant/New()
	..()
	id = GLOB.warrant_uid++

// Virus record
/datum/record/virus
	name = "Unknown"
	var/description = ""
	var/antigen
	var/spread_type = "Unknown"
	cmp_field = "name"

//Manifest record
/datum/record/shuttle_manifest
	name = "Unknown"
	cmp_field = "name"
	var/shuttle = "Unknown"
	var/pilot = FALSE
	var/lead = FALSE

GLOBAL_VAR_INIT(shuttle_uid, 0)
/datum/record/shuttle_manifest/New()
	..()
	id = GLOB.shuttle_uid++

/datum/record/shuttle_assignment
	var/shuttle
	var/destination = "Unknown"
	var/heading = 0
	var/mission = "Exploration"
	var/departure_time
	var/return_time
	cmp_field = "destination"

/datum/record/shuttle_assignment/New(var/for_shuttle)
	. = ..()
	shuttle = for_shuttle
