--[[

	TechAge
	=======

	Copyright (C) 2019-2022 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	Helper functions

]]--

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta
local S = techage.S

-- Input data to generate the Param2ToDir table
local Input = {
	8,9,10,11,    -- 1
	16,17,18,19,  -- 2
	4,5,6,7,      -- 3
	12,13,14,15,  -- 4
	0,1,2,3,      -- 5
	20,21,22,23,  -- 6
}

--  Input data to turn a "facedir" block to the right/left
local ROTATION = {
	{5,14,11,16},  -- x+
	{7,12,9,18},   -- x-
	{0,1,2,3},     -- y+
	{22,21,20,23}, -- y-
	{6,15,8,17},   -- z+
	{4,13,10,19},  -- z-
}

local FACEDIR_TO_ROT = {[0] =
	{x=0.000000, y=0.000000, z=0.000000},
	{x=0.000000, y=4.712389, z=0.000000},
	{x=0.000000, y=3.141593, z=0.000000},
	{x=0.000000, y=1.570796, z=0.000000},
	{x=4.712389, y=0.000000, z=0.000000},
	{x=3.141593, y=1.570796, z=1.570796},
	{x=1.570796, y=4.712389, z=4.712389},
	{x=3.141593, y=4.712389, z=4.712389},
	{x=1.570796, y=0.000000, z=0.000000},
	{x=0.000000, y=4.712389, z=1.570796},
	{x=4.712389, y=1.570796, z=4.712389},
	{x=0.000000, y=1.570796, z=4.712389},
	{x=0.000000, y=0.000000, z=1.570796},
	{x=4.712389, y=0.000000, z=1.570796},
	{x=0.000000, y=3.141593, z=4.712389},
	{x=1.570796, y=3.141593, z=4.712389},
	{x=0.000000, y=0.000000, z=4.712389},
	{x=1.570796, y=0.000000, z=4.712389},
	{x=0.000000, y=3.141593, z=1.570796},
	{x=4.712389, y=0.000000, z=4.712389},
	{x=0.000000, y=0.000000, z=3.141593},
	{x=0.000000, y=1.570796, z=3.141593},
	{x=0.000000, y=3.141593, z=3.141593},
	{x=0.000000, y=4.712389, z=3.141593},
}

local RotationViaYAxis = {}

for _,row in ipairs(ROTATION) do
	for i = 1,4 do
		local val = row[i]
		local left  = row[i == 1 and 4 or i - 1]
		local right = row[i == 4 and 1 or i + 1]
		RotationViaYAxis[val] = {left, right}
	end
end

function techage.facedir_to_rotation(facedir)
	return FACEDIR_TO_ROT[facedir]
end

function techage.param2_turn_left(param2)
	return (RotationViaYAxis[param2] or RotationViaYAxis[0])[1]
end

function techage.param2_turn_right(param2)
	return (RotationViaYAxis[param2] or RotationViaYAxis[0])[2]
end

-------------------------------------------------------------------------------
-- Rotate nodes around the center
-------------------------------------------------------------------------------
function techage.positions_center(lpos)
	local c = {x=0, y=0, z=0}
	for _,v in ipairs(lpos) do
		c = vector.add(c, v)
	end
	c = vector.divide(c, #lpos)
	c = vector.round(c)
	c.y = 0
	return c
end

function techage.rotate_around_axis(v, c, turn)
	local dx, dz = v.x - c.x, v.z - c.z
	if turn == "l" then
		return {
			x = c.x - dz,
			y = v.y,
			z = c.z + dx,
		}
	elseif turn == "r" then
		return {
			x = c.x + dz,
			y = v.y,
			z = c.z - dx,
		}
	elseif turn == "" then
		return v
	else -- turn 180 degree
		return {
			x = c.x - dx,
			y = v.y,
			z = c.z - dz,
		}
	end
end

-- Function returns a list ẃith the new node positions
-- turn is one of "l", "r", "2l", "2r"
-- cpos is the center pos (optional)
function techage.rotate_around_center(nodes1, turn, cpos)
	cpos = cpos or techage.positions_center(nodes1)
	local nodes2 = {}
	for _,pos in ipairs(nodes1) do
		nodes2[#nodes2 + 1] = techage.rotate_around_axis(pos, cpos, turn)
	end
	return nodes2
end

-- allowed for digging
local RegisteredNodesToBeDug = {}

function techage.register_node_to_be_dug(name)
	RegisteredNodesToBeDug[name] = true
end

-- translation from param2 to dir (out of the node upwards)
local Param2Dir = {}
for idx,val in ipairs(Input) do
	Param2Dir[val] = math.floor((idx - 1) / 4) + 1
end

-- used by lamps and power switches
function techage.determine_node_bottom_as_dir(node)
	return tubelib2.Turn180Deg[Param2Dir[node.param2] or 1]
end

function techage.determine_node_top_as_dir(node)
	return Param2Dir[node.param2] or 1
end

-- rotation rules (screwdriver) for wallmounted "facedir" nodes
function techage.rotate_wallmounted(param2)
	local offs = math.floor(param2 / 4) * 4
	local rot = ((param2 % 4) + 1) % 4
	return offs + rot
end

function techage.in_range(val, min, max)
	val = tonumber(val)
	if val < min then return min end
	if val > max then return max end
	return val
end

function techage.one_of(val, selection)
	for _,v in ipairs(selection) do
		if val == v then return val end
	end
	return selection[1]
end

function techage.index(list, x)
	for idx, v in pairs(list) do
		if v == x then return idx end
	end
	return nil
end

function techage.in_list(list, x)
	for idx, v in pairs(list) do
		if v == x then return true end
	end
	return false
end

function techage.add_to_set(set, x)
	if not techage.index(set, x) then
		table.insert(set, x)
	end
end

function techage.get_node_lvm(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then
		return node
	end
	local vm = minetest.get_voxel_manip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	local idx = area:indexp(pos)
	if data[idx] and param2_data[idx] then
		return {
			name = minetest.get_name_from_content_id(data[idx]),
			param2 = param2_data[idx]
		}
	end
	return {name="ignore", param2=0}
end

--
-- Functions used to hide electric cable and biogas pipes
--
-- Overridden method of tubelib2!
function techage.get_primary_node_param2(pos, dir)
	local npos = vector.add(pos, tubelib2.Dir6dToVector[dir or 0])
	local param2 = M(npos):get_int("tl2_param2")
	if param2 ~= 0 then
		return param2, npos
	end
end

-- Overridden method of tubelib2!
function techage.is_primary_node(pos, dir)
	local npos = vector.add(pos, tubelib2.Dir6dToVector[dir or 0])
	local param2 = M(npos):get_int("tl2_param2")
	return param2 ~= 0
end

function techage.is_air_like(name)
	local ndef = minetest.registered_nodes[name]
	if ndef and ndef.buildable_to then
		return true
	end
	return false
end

-- returns true, if node can be dug, otherwise false
function techage.can_node_dig(node, ndef)
	if RegisteredNodesToBeDug[node.name] then
		return true
	end
	if not ndef then return false end
	if node.name == "ignore" then return false end
	if node.name == "air" then return true end
	if ndef.buildable_to == true then return true end
	if ndef.diggable == false then return false end
	if ndef.after_dig_node then return false end
	-- add it to the white list
	RegisteredNodesToBeDug[node.name] = true
	return true
end

techage.dig_states = {
	NOT_DIGGABLE = 1,
	INV_FULL = 2,
	DUG = 3
}

-- Digs a node like a player would by utilizing a fake player object.
-- add_to_inv(itemstacks) is a method that should try to add the dropped stacks to an appropriate inventory.
-- The node will only be dug, if add_to_inv(itemstacks) returns true.
function techage.dig_like_player(pos, fake_player, add_to_inv)
	local node = techage.get_node_lvm(pos)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef or ndef.diggable == false or (ndef.can_dig and not ndef.can_dig(pos, fake_player)) then
		return techage.dig_states.NOT_DIGGABLE
	end
	local drop_as_strings = minetest.get_node_drops(node)
	local drop_as_stacks = {}
	for _,itemstring in ipairs(drop_as_strings) do
		drop_as_stacks[#drop_as_stacks+1] = ItemStack(itemstring)
	end
	local meta = M(pos)
	if ndef.preserve_metadata then
		ndef.preserve_metadata(pos, node, meta, drop_as_stacks)
	end

	if add_to_inv(drop_as_stacks) then
		local oldmeta = meta:to_table()
		minetest.remove_node(pos)

		if ndef.after_dig_node then
			ndef.after_dig_node(pos, node, oldmeta, fake_player)
		end
		return techage.dig_states.DUG
	end
	return techage.dig_states.INV_FULL
end

local function handle_drop(drop)
	-- To keep it simple, return only the item with the lowest rarity
	if drop.items then
		local rarity = 9999
		local name
		for idx,item in ipairs(drop.items) do
			if item.rarity and item.rarity < rarity then
				rarity = item.rarity
				name = item.items[1] -- take always the first item
			else
				return item.items[1] -- take always the first item
			end
		end
		return name
	end
	return false
end

-- returns the node name, if node can be dropped, otherwise nil
function techage.dropped_node(node, ndef)
	if node.name == "air" then return end
	--if ndef.buildable_to == true then return end
	if not ndef.diggable then return end
	if ndef.drop == "" then return end
	if type(ndef.drop) == "table" then
		return handle_drop(ndef.drop)
	end
	return ndef.drop or node.name
end

-- needed for windmill plants
local function determine_ocean_ids()
	techage.OceanIdTbl = {}
	for name, _ in pairs(minetest.registered_biomes) do
		if string.find(name, "ocean") then
			local id = minetest.get_biome_id(name)
			--print(id, name)
			techage.OceanIdTbl[id] = true
		end
	end
end

determine_ocean_ids()

-- check if natural water is on given position (water placed by player has param2 = 1)
function techage.is_ocean(pos)
	if pos.y > 1 then return false end
	local node = techage.get_node_lvm(pos)
	if node.name ~= "default:water_source" then return false end
	if node.param2 == 1 then return false end
	return true
end

function techage.item_image(x, y, itemname, count)
	local name, size = unpack(string.split(itemname, " "))
	size = count and count or size
	size = tonumber(size) or 1
	local label = ""
	local text = minetest.formspec_escape(ItemStack(itemname):get_description())
	local tooltip = "tooltip["..x..","..y..";1,1;"..text..";#0C3D32;#FFFFFF]"

	if minetest.registered_tools[name] and size > 1 then
		local offs
		if size < 10 then
			offs = 0.65
		elseif size < 100 then
			offs = 0.5
		elseif size < 1000 then
			offs = 0.35
		else
			offs = 0.2
		end
		label = "label["..(x + offs)..","..(y + 0.45)..";"..tostring(size).."]"
	end

	return "box["..x..","..y..";0.85,0.9;#808080]"..
		"item_image["..x..","..y..";1,1;"..itemname.."]"..
		tooltip..
		label
end

function techage.item_image_small(x, y, itemname, tooltip_prefix)
	local name = unpack(string.split(itemname, " "))
	local tooltip = ""
	local ndef = minetest.registered_nodes[name] or minetest.registered_items[name] or minetest.registered_craftitems[name]

	if ndef and ndef.description then
		local text = minetest.formspec_escape(ndef.description)
		tooltip = "tooltip["..x..","..y..";0.8,0.8;"..tooltip_prefix..": "..text..";#0C3D32;#FFFFFF]"
	end

	return "box["..x..","..y..";0.65,0.7;#808080]"..
		"item_image["..x..","..y..";0.8,0.8;"..name.."]"..
		tooltip
end

-- Copied from Minetest's builtin/common/misc_helpers.lua
local function basic_dump(o)
	local tp = type(o)
	if tp == "number" then
		return tostring(o)
	elseif tp == "string" then
		return string.format("%q", o)
	elseif tp == "boolean" then
		return tostring(o)
	elseif tp == "nil" then
		return "nil"
	-- Uncomment for full function dumping support.
	-- Not currently enabled because bytecode isn't very human-readable and
	-- dump's output is intended for humans.
	--elseif tp == "function" then
	--	return string.format("loadstring(%q)", string.dump(o))
	elseif tp == "userdata" then
		return tostring(o)
	else
		return string.format("<%s>", tp)
	end
end

local keywords = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["goto"] = true,  -- Lua 5.2
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}
local function is_valid_identifier(str)
	if not str:find("^[a-zA-Z_][a-zA-Z0-9_]*$") or keywords[str] then
		return false
	end
	return true
end

function techage.mydump(o, indent, nested, level)
	local t = type(o)
	if not level and t == "userdata" then
		-- when userdata (e.g. player) is passed directly, print its metatable:
		return "userdata metatable: " .. techage.mydump(getmetatable(o))
	end
	if t ~= "table" then
		return basic_dump(o)
	end
	-- Contains table -> true/nil of currently nested tables
	nested = nested or {}
	if nested[o] then
		return "<circular reference>"
	end
	nested[o] = true
	indent = indent or " "
	level = level or 1
	local t = {}
	local dumped_indexes = {}
	for i, v in ipairs(o) do
		t[#t + 1] = techage.mydump(v, indent, nested, level + 1)
		dumped_indexes[i] = true
	end
	for k, v in pairs(o) do
		if not dumped_indexes[k] then
			if type(k) ~= "string" or not is_valid_identifier(k) then
				k = "["..techage.mydump(k, indent, nested, level + 1).."]"
			end
			v = techage.mydump(v, indent, nested, level + 1)
			t[#t + 1] = k.." = "..v
		end
	end
	nested[o] = nil
	if indent ~= "" then
		local indent_str = string.rep(indent, level)
		local end_indent_str = string.rep(indent, level - 1)
		return string.format("{%s%s%s}",
				indent_str,
				table.concat(t, ","..indent_str),
				end_indent_str)
	end
	return "{"..table.concat(t, ", ").."}"
end

function techage.vector_dump(posses)
	local t = {}
	for _,pos in ipairs(posses) do
		t[#t + 1] = minetest.pos_to_string(pos)
	end
	return table.concat(t, " ")
end

-- title bar help (width is the fornmspec width)
function techage.question_mark_help(width, tooltip)
	local x = width- 0.6
	return "label["..x..",-0.1;"..minetest.colorize("#000000", minetest.formspec_escape("[?]")).."]"..
		"tooltip["..x..",-0.1;0.5,0.5;"..tooltip..";#0C3D32;#FFFFFF]"
end

function techage.wrench_tooltip(x, y)
	local tooltip = S("Block has an\nadditional wrench menu")
	return "label["..x..","..y..";"..minetest.colorize("#000000", minetest.formspec_escape("[?]")).."]"..
		"tooltip["..x..","..y..";0.5,0.5;"..tooltip..";#0C3D32;#FFFFFF]"
end

-------------------------------------------------------------------------------
-- Terminal history buffer
-------------------------------------------------------------------------------
local BUFFER_DEPTH = 10

function techage.historybuffer_add(pos, s)
	local mem = techage.get_mem(pos)
	mem.hisbuf = mem.hisbuf or {}

	if #s > 2 then
		table.insert(mem.hisbuf, s)
		if #mem.hisbuf > BUFFER_DEPTH then
			table.remove(mem.hisbuf, 1)
		end
		mem.hisbuf_idx = #mem.hisbuf + 1
	end
end

function techage.historybuffer_priv(pos)
	local mem = techage.get_mem(pos)
	mem.hisbuf = mem.hisbuf or {}
	mem.hisbuf_idx = mem.hisbuf_idx or 1

	mem.hisbuf_idx = math.max(1, mem.hisbuf_idx - 1)
	return mem.hisbuf[mem.hisbuf_idx]
end

function techage.historybuffer_next(pos)
	local mem = techage.get_mem(pos)
	mem.hisbuf = mem.hisbuf or {}
	mem.hisbuf_idx = mem.hisbuf_idx or 1

	mem.hisbuf_idx = math.min(#mem.hisbuf, mem.hisbuf_idx + 1)
	return mem.hisbuf[mem.hisbuf_idx]
end

-------------------------------------------------------------------------------
-- Player TA5 Experience Points
-------------------------------------------------------------------------------
function techage.get_expoints(player)
	if player and player.get_meta then
		local meta = player:get_meta()
		if meta then
			return meta:get_int("techage_ex_points")
		end
	end
end

-- Can only be used from one collider
function techage.add_expoint(player, number)
	if player and player.get_meta then
		local meta = player:get_meta()
		if meta then
			if not meta:contains("techage_collider_number") then
				meta:set_string("techage_collider_number", number)
			end
			if meta:get_string("techage_collider_number") == number then
				meta:set_int("techage_ex_points", meta:get_int("techage_ex_points") + 1)
				return true
			else
				minetest.chat_send_player(player:get_player_name(), "[techage] More than one collider is not allowed!")
				return false
			end
		end
	end
end

function techage.on_remove_collider(player)
	if player and player.get_meta then
		local meta = player:get_meta()
		if meta then
			meta:set_string("techage_collider_number", "")
		end
	end
end

function techage.set_expoints(player, ex_points)
	if player and player.get_meta then
		local meta = player:get_meta()
		if meta then
			meta:set_int("techage_ex_points", ex_points)
			return true
		end
	end
end
