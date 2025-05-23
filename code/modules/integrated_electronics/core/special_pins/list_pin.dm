// These pins contain a list.  Null is not allowed.
/datum/integrated_io/list
	name = "list pin"
	data = list()

/datum/integrated_io/list/ask_for_pin_data(mob/user)
	interact(user)

// Positionless remove/Edit are a bit weird,
// not sure if adding these buttons is quite a good idea.
// They introduce uncertainty, since, in case of 2 elements,
// they will work just with the 1st one
/datum/integrated_io/list/proc/interact(mob/user)
	var/list/my_list = data
	var/t = "<h2>[src]</h2><br>"
	t += "List length: [my_list.len]<br>"
	t += "<a href='byond://?src=[REF(src)]'>Refresh</a>  |  "
	t += "<a href='byond://?src=[REF(src)];add=1'>Add</a>  |  "
	t += "<a href='byond://?src=[REF(src)];remove=1'>Remove</a>  |  "
	t += "<a href='byond://?src=[REF(src)];edit=1'>Edit</a>  |  "
	t += "<a href='byond://?src=[REF(src)];swap=1'>Swap</a>  |  "
	t += "<a href='byond://?src=[REF(src)];clear=1'>Clear</a><br>"
	t += "<hr>"
	// Iterating by index simplifies editing/deletion in game,
	// since the href_list["pos"] var is consistent
	for(var/i = 1, i <= my_list.len; i++)
		t += "#[i] | [display_data(my_list[i])]  |  "
		t += "<a href='byond://?src=[REF(src)];edit=1;pos=[i]'>Edit</a>  |  "
		t += "<a href='byond://?src=[REF(src)];remove=1;pos=[i]'>Remove</a><br>"
	var/datum/browser/B = new(user, "list_pin_[REF(src)]", null, 500, 400)
	B.set_content(t)
	B.open(FALSE)

/datum/integrated_io/list/proc/add_to_list(mob/user, new_entry)
	if(!new_entry && user)
		new_entry = ask_for_data_type(user)
	// is_valid can't be used here, since is_valid checks "data" and has no arguments
	if(!isnull(new_entry))
		Add(new_entry)

/datum/integrated_io/list/proc/Add(new_entry)
	var/list/my_list = data
	if(my_list.len > IC_MAX_LIST_LENGTH)
		my_list.Cut(1, 2)
	my_list.Add(new_entry)

/datum/integrated_io/list/proc/remove_from_list_by_position(mob/user, position)
	var/list/my_list = data
	if(!my_list.len)
		to_chat(user, SPAN_WARNING("The list is empty, there's nothing to remove."))
		return
	if(!position)
		return
	if(position > my_list.len)
		return
	var/target_entry = my_list[position]
	// Should be able to remove nulls, since we can add a null to the list from the outside.
	my_list -= target_entry

/datum/integrated_io/list/proc/remove_from_list(mob/user, target_entry)
	var/list/my_list = data
	if(!my_list.len)
		to_chat(user, SPAN_WARNING("The list is empty, there's nothing to remove."))
		return
	if(!target_entry)
		target_entry = input("Which piece of data do you want to remove?", "Remove") as null|anything in my_list
	if(target_entry)
		my_list -= target_entry

/datum/integrated_io/list/proc/edit_in_list(mob/user, target_entry)
	var/list/my_list = data
	if(!my_list.len)
		to_chat(user, SPAN_WARNING("The list is empty, there's nothing to modify."))
		return
	if(!target_entry)
		target_entry = input("Which piece of data do you want to edit?", "Edit") as null|anything in my_list
	if(target_entry)
		var/edited_entry = ask_for_data_type(user, target_entry)
		var/i = my_list.Find(target_entry)
		if(edited_entry)
			my_list[i] = edited_entry

/datum/integrated_io/list/proc/edit_in_list_by_position(mob/user, var/position)
	var/list/my_list = data
	if(!my_list.len)
		to_chat(user, SPAN_WARNING("The list is empty, there's nothing to modify."))
		return
	if(!position)
		return
	if(position > my_list.len)
		return
	var/target_entry = my_list[position]
	if(target_entry)
		var/edited_entry = ask_for_data_type(user, target_entry)
		if(edited_entry)
			my_list[position] = edited_entry

/datum/integrated_io/list/proc/swap_inside_list(mob/user, var/first_target, var/second_target)
	var/list/my_list = data
	if(my_list.len <= 1)
		to_chat(user, SPAN_WARNING("The list is empty, or too small to do any meaningful swapping."))
		return
	if(!first_target)
		first_target = input("Which piece of data do you want to swap? (1)", "Swap") as null|anything in my_list

	if(first_target)
		if(!second_target)
			second_target = input("Which piece of data do you want to swap? (2)", "Swap") as null|anything in my_list - first_target

		if(second_target)
			var/first_pos = my_list.Find(first_target)
			var/second_pos = my_list.Find(second_target)
			my_list.Swap(first_pos, second_pos)

/datum/integrated_io/list/proc/clear_list(mob/user)
	var/list/my_list = data
	my_list.Cut()

/datum/integrated_io/list/scramble()
	var/list/my_list = data
	my_list = shuffle(my_list)
	push_data()

/datum/integrated_io/list/write_data_to_pin(var/new_data)
	if(islist(new_data))
		var/list/new_list = new_data
		// Sanitize the input - no nulls allowed.
		while(new_list.Remove(null) == 1)
		data = new_list.Copy()
		holder.on_data_written()

/datum/integrated_io/list/display_pin_type()
	return IC_FORMAT_LIST

/datum/integrated_io/list/Topic(href, href_list, state = GLOB.always_state)
	if(!holder.check_interactivity(usr))
		return
	if(..())
		return 1

	if(href_list["add"])
		add_to_list(usr)

	if(href_list["swap"])
		swap_inside_list(usr)

	if(href_list["clear"])
		clear_list(usr)

	if(href_list["remove"])
		if(href_list["pos"])
			remove_from_list_by_position(usr, text2num(href_list["pos"]))
		else
			remove_from_list(usr)

	if(href_list["edit"])
		if(href_list["pos"])
			edit_in_list_by_position(usr, text2num(href_list["pos"]))
		else
			edit_in_list(usr)

	holder.interact(usr) // Refresh the main UI,
	interact(usr) // and the list UI.
