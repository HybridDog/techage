--[[

	TechAge
	=======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	Recipe lib for formspecs

]]--

local S = techage.S
local M = minetest.get_meta

local Recipes = {}     -- {rtype = {ouput = {....},...}}
local RecipeList = {}  -- {rtype = {<output name>,...}}

local range = techage.range

techage.recipes = {}

-- Formspec
local function input_string(recipe)
	local tbl = {}
	for idx, item in ipairs(recipe.input) do
		local x = ((idx-1) % 2)
		local y = math.floor((idx-1) / 2)
		tbl[idx] = techage.item_image(x, y, item.name.." "..item.num)
	end
	return table.concat(tbl, "")
end

function techage.recipes.get(mem, rtype)
	local recipes = Recipes[rtype] or {}
	local recipe_list = RecipeList[rtype] or {}
	return recipes[recipe_list[mem.recipe_idx or 1]]
end
	
-- Add 4 input/output/waste recipe
-- {
--     output = "<item-name> <units>",  -- units = 1..n
--     waste = "<item-name> <units>",   -- units = 1..n
--     input = {                        -- up to 4 items
--         "<item-name> <units>",
--         "<item-name> <units>",
--     },
-- }
function techage.recipes.add(rtype, recipe)
	if not Recipes[rtype] then
		Recipes[rtype] = {}
	end
	if not RecipeList[rtype] then
		RecipeList[rtype] = {}
	end
	
	local name, num
	local item = {input = {}}
	for idx = 1,4 do
		local inp = recipe.input[idx] or ""
		name, num = unpack(string.split(inp, " "))
		item.input[idx] = {name = name or "", num = tonumber(num) or 0}
	end
	if recipe.waste then 
		name, num = unpack(string.split(recipe.waste, " "))
	else
		name, num = "", "0"
	end
	item.waste = {name = name or "", num = tonumber(num) or 0}
	name, num = unpack(string.split(recipe.output, " "))
	item.output = {name = name or "", num = tonumber(num) or 0}
	Recipes[rtype][name] = item
	RecipeList[rtype][#(RecipeList[rtype])+1] = name

	if minetest.global_exists("unified_inventory") then
		unified_inventory.register_craft({
			output = recipe.output, 
			items = recipe.input,
			type = rtype,
		})
	end
end

function techage.recipes.formspec(x, y, rtype, mem)
	local recipes = Recipes[rtype] or {}
	local recipe_list = RecipeList[rtype] or {}
	mem.recipe_idx = range(mem.recipe_idx or 1, 1, #recipe_list)
	local idx = mem.recipe_idx
	local recipe = recipes[recipe_list[idx]]
	local output = recipe.output.name.." "..recipe.output.num
	local waste = recipe.waste.name.." "..recipe.waste.num
	return "container["..x..","..y.."]"..
		"background[0,0;4,3;techage_form_grey.png]"..
		input_string(recipe)..
		"image[2,0.5;1,1;techage_form_arrow.png]"..
		techage.item_image(2.95, 0, output)..
		techage.item_image(2.95, 1, waste)..
		"button[0,2;1,1;priv;<<]"..
		"button[1,2;1,1;next;>>]"..
		"label[1.9,2.2;"..S("Recipe")..": "..idx.."/"..#recipe_list.."]"..
		"container_end[]"
end

function techage.recipes.on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local mem = tubelib2.get_mem(pos)
	
	mem.recipe_idx = mem.recipe_idx or 1
	if not mem.running then	
		if fields.next == ">>" then
			mem.recipe_idx = mem.recipe_idx + 1
		elseif fields.priv == "<<" then
			mem.recipe_idx = mem.recipe_idx - 1
		end
	end
end
