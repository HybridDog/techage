--[[

	TechAge
	=======

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	TA3 Power Terminal

]]--

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta
local S = techage.S

local Param2ToDir = {
	[0] = 6,
	[1] = 5,
	[2] = 2,
	[3] = 4,
	[4] = 1,
	[5] = 3,
}

local function formspec(pos)
	local jpos = minetest.deserialize(M(pos):get_string("junction_pos"))
	local ndef = minetest.registered_nodes[minetest.get_node(jpos).name]
	if ndef.is_power_available then
		local power = ndef.is_power_available(jpos)
		if power and power.prim_available then
			return "size[5,4]"..
			default.gui_bg..
			default.gui_bg_img..
			default.gui_slots..
			"label[1.5,0.0;"..S("Network Data").."]"..
			"label[0,0.8;"..S("Generators").."        : "..power.prim_available.." ku]"..
			"label[0,1.4;"..S("Akkus").."                 : "..power.sec_available.." ku]"..
			"label[0,2.0;"..S("Machines").."           : "..power.prim_needed.." ku]"..
			"label[0,2.6;"..S("Number nodes").."  : "..power.num_nodes.."]"..
			"button[1.5,3.3;2,1;update;"..S("Update").."]"
		end
	end
	return "size[5,4]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
			"label[1.5,0.0;"..S("Network Data").."]"..
			"label[0,0.8;"..S("Generators").."        : 0 ku]"..
			"label[0,1.4;"..S("Akkus").."                 : 0 ku]"..
			"label[0,2.0;"..S("Machines").."           : 0 ku]"..
			"label[0,2.6;"..S("Number nodes").."  : 0]"..
			"button[1.5,3.3;2,1;update;"..S("Update").."]"
end


minetest.register_node("techage:ta3_power_terminal", {
	description = S("TA3 Power Terminal"),
	inventory_image = "techage_power_terminal_front.png",
	tiles = {
		"techage_power_terminal_top.png",
		"techage_power_terminal_top.png",
		"techage_power_terminal_side.png",
		"techage_power_terminal_side.png",
		"techage_power_terminal_back.png",
		"techage_power_terminal_front.png",
		},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, 0/16,  8/16, 8/16, 8/16},
		},
	},
	
	after_place_node = function(pos, placer, itemstack)
		local node = minetest.get_node(pos)
		local outdir = techage.side_to_outdir("B", node.param2)
		local jpos = tubelib2.get_pos(pos, outdir)
		local meta = M(pos)
		meta:set_string("junction_pos", minetest.serialize(jpos))
		meta:set_string("formspec", formspec(pos))
	end,
	
	on_receive_fields = function(pos, formname, fields, player)
		if fields.update then
			M(pos):set_string("formspec", formspec(pos))
		end
	end,
	on_rightclick = function(pos, node, clicker)
		M(pos):set_string("formspec", formspec(pos))
	end,
	
	paramtype2 = "facedir",
	paramtype = "light",
	on_rotate = screwdriver.disallow,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
	output = "techage:ta3_power_terminal",
	recipe = {
		{"", "techage:usmium_nuggets", "default:steel_ingot"},
		{"", "techage:basalt_glass_thin", "default:copper_ingot"},
		{"", "techage:vacuum_tube", "default:steel_ingot"},
	},
})

techage.register_entry_page("ta3ps", "ta3_power_terminal",
	S("TA3 Power Terminal"), 
	S("Terminal for power network information. Has to be placed in front of an Electric Junction Box."), 
	"techage:ta3_power_terminal")