--[[

	TechAge
	=======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	TA2/TA3/TA4 Electronic Fab
	
]]--

-- for lazy programmers
local M = minetest.get_meta
-- Consumer Related Data
local CRD = function(pos) return (minetest.registered_nodes[techage.get_node_lvm(pos).name] or {}).consumer end

local S = techage.S
local STANDBY_TICKS = 10
local COUNTDOWN_TICKS = 6
local CYCLE_TIME = 6

local recipes = techage.recipes

local RecipeType = {	[2] = "ta2_electronic_fab",
	[3]	= "ta3_electronic_fab",
	[4] = "ta4_electronic_fab",
}

local function formspec(self, pos, mem)
	local rtype = RecipeType[CRD(pos).stage]
	return "size[8.4,8.4]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;2,4;]"..
	recipes.formspec(2.2, 0, rtype, mem)..
	"list[context;dst;6.4,0;2,4;]"..
	"image_button[3.7,3.3;1,1;".. self:get_state_button_image(mem) ..";state_button;]"..
	"tooltip[3.7,3.3;1,1;"..self:get_state_tooltip(mem).."]"..
	"list[current_player;main;0.2,4.5;8,4;]"..
	"listring[context;dst]"..
	"listring[current_player;main]"..
	"listring[context;src]"..
	"listring[current_player;main]"..
	default.get_hotbar_bg(0.2, 4.5)
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local crd = CRD(pos)
	if listname == "src" then
		crd.State:start_if_standby(pos)
		return stack:get_count()
	end
	return 0
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function making(pos, crd, mem, inv)
	local rtype = RecipeType[crd.stage]
	local recipe = recipes.get(mem, rtype)
	local output = ItemStack(recipe.output.name.." "..recipe.output.num)
	if inv:room_for_item("dst", output) then
		for _,item in ipairs(recipe.input) do
			local input = ItemStack(item.name.." "..item.num)
			if not inv:contains_item("src", input) then
				crd.State:idle(pos, mem)
				return
			end
		end
		for _,item in ipairs(recipe.input) do
			local input = ItemStack(item.name.." "..item.num)
			inv:remove_item("src", input)
		end
		inv:add_item("dst", output)
		crd.State:keep_running(pos, mem, COUNTDOWN_TICKS)
		return
	end
	crd.State:idle(pos, mem)
end

local function keep_running(pos, elapsed)
	local mem = tubelib2.get_mem(pos)
	local crd = CRD(pos)
	local inv = M(pos):get_inventory()
	if inv then
		making(pos, crd, mem, inv)
	end
	return crd.State:is_active(mem)
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	local mem = tubelib2.get_mem(pos)
	local crd = CRD(pos)
	
	if not mem.running then	
		recipes.on_receive_fields(pos, formname, fields, player)
	end
	
	crd.State:state_button_event(pos, mem, fields)
	M(pos):set_string("formspec", formspec(crd.State, pos, mem))
end

local function can_dig(pos, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return false
	end
	local inv = M(pos):get_inventory()
	return inv:is_empty("dst") and inv:is_empty("src")
end

local tiles = {}
-- '#' will be replaced by the stage number
tiles.pas = {
	-- up, down, right, left, back, front
	"techage_filling_ta#.png^techage_frame_ta#_top.png",
	"techage_filling_ta#.png^techage_frame_ta#.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_outp.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_inp.png",
	"techage_filling_ta#.png^techage_appl_electronic_fab.png^techage_frame_ta#.png",
	"techage_filling_ta#.png^techage_appl_electronic_fab.png^techage_frame_ta#.png",
}
tiles.act = {
	-- up, down, right, left, back, front
	"techage_filling_ta#.png^techage_frame_ta#_top.png",
	"techage_filling_ta#.png^techage_frame_ta#.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_outp.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_inp.png",
	{
		image = "techage_filling4_ta#.png^techage_appl_electronic_fab4.png^techage_frame4_ta#.png",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 0.5,
		},
	},
	{
		image = "techage_filling4_ta#.png^techage_appl_electronic_fab4.png^techage_frame4_ta#.png",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 0.5,
		},
	},
}

local tubing = {
	on_pull_item = function(pos, in_dir, num)
		local meta = minetest.get_meta(pos)
		if meta:get_int("pull_dir") == in_dir then
			local inv = M(pos):get_inventory()
			return techage.get_items(inv, "dst", num)
		end
	end,
	on_push_item = function(pos, in_dir, stack)
		local meta = minetest.get_meta(pos)
		if meta:get_int("push_dir") == in_dir  or in_dir == 5 then
			local inv = M(pos):get_inventory()
			CRD(pos).State:start_if_standby(pos)
			return techage.put_items(inv, "src", stack)
		end
	end,
	on_unpull_item = function(pos, in_dir, stack)
		local meta = minetest.get_meta(pos)
		if meta:get_int("pull_dir") == in_dir then
			local inv = M(pos):get_inventory()
			return techage.put_items(inv, "dst", stack)
		end
	end,
	on_recv_message = function(pos, src, topic, payload)
		local resp = CRD(pos).State:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		CRD(pos).State:on_node_load(pos)
	end,
}

local node_name_ta2, node_name_ta3, node_name_ta4 = 
	techage.register_consumer("electronic_fab", S("Electronic Fab"), tiles, {
		drawtype = "normal",
		cycle_time = CYCLE_TIME,
		standby_ticks = STANDBY_TICKS,
		formspec = formspec,
		tubing = tubing,
		after_place_node = function(pos, placer)
			local inv = M(pos):get_inventory()
			inv:set_size("src", 8)
			inv:set_size("dst", 8)
		end,
		can_dig = can_dig,
		node_timer = keep_running,
		on_receive_fields = on_receive_fields,
		allow_metadata_inventory_put = allow_metadata_inventory_put,
		allow_metadata_inventory_move = allow_metadata_inventory_move,
		allow_metadata_inventory_take = allow_metadata_inventory_take,
		groups = {choppy=2, cracky=2, crumbly=2},
		sounds = default.node_sound_wood_defaults(),
		num_items = {0,1,1,1},
		power_consumption = {0,8,12,18},
	})

minetest.register_craft({
	output = node_name_ta2,
	recipe = {
		{"group:wood", "default:diamond", "group:wood"},
		{"techage:tubeS", "basic_materials:gear_steel", "techage:tubeS"},
		{"group:wood", "default:steel_ingot", "group:wood"},
	},
})

minetest.register_craft({
	output = node_name_ta3,
	recipe = {
		{"", "default:diamond", ""},
		{"", node_name_ta2, ""},
		{"", "techage:vacuum_tube", ""},
	},
})

minetest.register_craftitem("techage:vacuum_tube", {
	description = S("TA3 Vacuum Tube"),
	inventory_image = "techage_vacuum_tube.png",
})

minetest.register_craftitem("techage:ta4_wlanchip", {
	description = S("TA4 WLAN Chip"),
	inventory_image = "techage_wlanchip.png",
})

minetest.register_craftitem("techage:wlanchip", {
	description = S("WLAN Chip"),
	inventory_image = "techage_wlanchip.png",
})


if minetest.global_exists("unified_inventory") then
	unified_inventory.register_craft_type("ta2_electronic_fab", {
		description = S("TA2 Ele Fab"),
		icon = 'techage_filling_ta2.png^techage_appl_electronic_fab.png^techage_frame_ta2.png',
		width = 2,
		height = 2,
	})
	unified_inventory.register_craft_type("ta3_electronic_fab", {
		description = S("TA3 Ele Fab"),
		icon = 'techage_filling_ta3.png^techage_appl_electronic_fab.png^techage_frame_ta3.png',
		width = 2,
		height = 2,
	})
end


recipes.add("ta2_electronic_fab", {
	output = "techage:vacuum_tube 2",
	input = {"default:glass 1", "basic_materials:copper_wire 1", "basic_materials:plastic_sheet 1", "techage:usmium_nuggets 1"}
})

recipes.add("ta3_electronic_fab", {
	output = "techage:vacuum_tube 2",
	input = {"default:glass 1", "basic_materials:copper_wire 1", "basic_materials:plastic_sheet 1", "techage:usmium_nuggets 1"}
})

recipes.add("ta3_electronic_fab", {
	output = "techage:ta4_wlanchip 8",
	input = {"default:mese_crystal 1", "default:copper_ingot 1", "default:gold_ingot 1", "techage:ta4_silicon_wafer 1"}
})
