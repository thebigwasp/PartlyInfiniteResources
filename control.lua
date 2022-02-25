--[[

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, If not, see <https://www.gnu.org/licenses/>.

]]

local Util = require('util')
local ResourcePatch = require('resource-patch')

script.on_init(function()
	-- debug
	global.debug = {}
	global.debug.draw_chunk_colors = false
	global.debug.draw_chunk_coords = false
	global.debug.draw_resource_patch_boundaries = false
	global.debug.draw_resource_colors = false
	
	global.min_integer = -2^31
	global.max_integer = 2^31 - 1
	
	global.expecting_any_resource = false
	global.expecting_resource = {}
	global.expecting_chunk = {}
	global.group_chunk = {}
	global.chunk_group = {}
	global.infinite_resources = {}
	
	local resource_types = game.get_filtered_entity_prototypes({{filter = "type", type = "resource"}})
	global.resource_types = {}
	for _, resource_type in pairs(resource_types) do
		if resource_type.infinite_resource == false then
			table.insert(global.resource_types, resource_type.name)
			global.expecting_chunk[resource_type.name] = {}
			global.group_chunk[resource_type.name] = {}
			global.chunk_group[resource_type.name] = {}
		end
	end
	
	local initial_chunks_radius = 7
	for i = -initial_chunks_radius, initial_chunks_radius - 1, 1 do
		for j = -initial_chunks_radius, initial_chunks_radius - 1, 1 do
			game.surfaces[1].set_chunk_generated_status({x = i, y = j}, defines.chunk_generated_status.tiles) -- hack
		end
	end
end)


script.on_event(defines.events.on_resource_depleted, function(event)
	if Util.exists(global.infinite_resources, event.entity.position.x, event.entity.position.y) then
		game.surfaces[1].create_entity{
			name = 'infinite-'..event.entity.name,
			position = event.entity.position,
		}
		
		Util.remove(global.infinite_resources, event.entity.position.x, event.entity.position.y)
	end
end)


script.on_event(defines.events.on_chunk_generated, function(event)
	draw_chunk_coords(event.position)
	
	local x = event.position.x
	local y = event.position.y
	
	local resources_found = false
	local chunk_resources = {}
	for _, resource_type in pairs(global.resource_types) do
		local resources = game.surfaces[1].find_entities_filtered {
			area = event.area,
			name = resource_type,
		}
		if #resources > 0 then
			chunk_resources[resource_type] = resources
			resources_found = true
		end
	end
	
	local neighbors
	if resources_found then
		neighbors = get_neighbors(event.position)
		remove_generated_chunks(neighbors)
	end
	
	if global.expecting_any_resource == true then
		for _, resource_type in pairs(global.resource_types) do
			if Util.exists(global.expecting_chunk[resource_type], x, y) then
				local group = global.expecting_chunk[resource_type][x][y]
				Util.remove(global.expecting_chunk[resource_type], x, y)
				
				if chunk_resources[resource_type] == nil then
					if table_size(global.expecting_chunk[resource_type]) == 0 then
						global.expecting_resource[resource_type] = nil
						
						process_observable_resource_patches(resource_type)
						if table_size(global.expecting_resource) == 0 then
							global.expecting_any_resource = false
						end
					end
					color_chunk(event.area, {1, 0, 0, 0.02})
				else
					color_chunk(event.area, {0, 0, 1, 0.02})
					generate_neighboring_chunks(event.position, resource_type, neighbors, group)
				end
			else
				if resources_found == false then
					color_chunk(event.area, {1, 0, 0, 0.02})
				else
					color_chunk(event.area, {0, 1, 0, 0.02})
					if chunk_resources[resource_type] ~= nil then
						add_chunk_group(event.position, resource_type)
						generate_neighboring_chunks(event.position, resource_type, neighbors, table_size(global.group_chunk[resource_type]))
					end
				end
			end
		end
	else
		if resources_found == false then
			color_chunk(event.area, {1, 0, 0, 0.02})
		else
			color_chunk(event.area, {0, 1, 0, 0.02})
			for resource_type, resources in pairs(chunk_resources) do
				add_chunk_group(event.position, resource_type)
				generate_neighboring_chunks(event.position, resource_type, neighbors, 1)
			end
		end
	end
end)


function add_chunk_group(position, resource_type)
	local group = table_size(global.group_chunk[resource_type]) + 1
	
	global.group_chunk[resource_type][group] = position
	
	Util.insert(global.chunk_group[resource_type], position.x, position.y, group)
end


function remove_chunk_group(position, resource_type)
	local group = global.chunk_group[resource_type][position.x][position.y]
	global.group_chunk[resource_type][group] = nil
	
	Util.remove(global.chunk_group[resource_type], position.x, position.y)
end


function generate_neighboring_chunks(position, resource_type, neighbors, group)	
	if table_size(neighbors) > 0 then
		for _, neighbor in pairs(neighbors) do
			Util.insert(global.expecting_chunk[resource_type], neighbor.x, neighbor.y, group)
		end
		global.expecting_resource[resource_type] = true
		global.expecting_any_resource = true
		
		game.surfaces[1].request_to_generate_chunks({x = position.x * 32, y = position.y * 32}, 1)
	end
end


function process_observable_resource_patches(resource_type)
	local ratio = settings.global['partly-infinite-resources-ratio'].value
	for group, position in pairs(global.group_chunk[resource_type]) do
		local chunks = {}
		local traversed = {}
		
		add_chunk_to_patch(chunks, position, traversed, resource_type, group)
		
		local min_x = global.max_integer
		local min_y = global.max_integer
		local max_x = global.min_integer
		local max_y = global.min_integer
		
		local resources = {}
		
		for _, chunk in pairs(chunks) do
			local chunk_resources = game.surfaces[1].find_entities_filtered {
				area = chunk_area(chunk),
				name = resource_type,
			}
			for _, resource in pairs(chunk_resources) do
				table.insert(resources, resource)
				if resource.position.x < min_x then
					min_x = resource.position.x
				end
				if resource.position.y < min_y then
					min_y = resource.position.y
				end
				if resource.position.x > max_x then
					max_x = resource.position.x
				end
				if resource.position.y > max_y then
					max_y = resource.position.y
				end
			end
		end
		
		draw_resource_patch_boundaries(min_x, min_y, max_x, max_y)
		
		local area = area(min_x, min_y, max_x, max_y)
		
		local inside_patch = ResourcePatch.patch_inside_patch(resources, area.left_top, area.right_bottom, ratio)
		for x, _ in pairs(inside_patch) do
			for y, _ in pairs(inside_patch[x]) do
				Util.insert(global.infinite_resources, x, y, true)
			end
		end
		
		draw_resource_colors(resources)
		remove_chunk_group(position, resource_type)
	end
end


function add_chunk_to_patch(chunks, position, traversed, resource_type, group)
	Util.insert(traversed, position.x, position.y, true)
	
	local count = game.surfaces[1].count_entities_filtered {
		area = chunk_area(position),
		name = resource_type,
	}
	
	if count > 0 then
		if Util.exists(global.chunk_group[resource_type], position.x, position.y) and global.chunk_group[resource_type][position.x][position.y] ~= group then
			remove_chunk_group(position, resource_type)
		end
		
		table.insert(chunks, position)
		
		local neighbors = get_neighbors(position)
		for _, neighbor in pairs(neighbors) do
			if traversed[neighbor.x] == nil or traversed[neighbor.x][neighbor.y] == nil then
				add_chunk_to_patch(chunks, neighbor, traversed, resource_type, group)
			end
		end
	end
end


function get_neighbors(position)
	local result = {}
	local x = position.x
	local y = position.y
	
	table.insert(result, {x = x - 1, y = y - 1})
	table.insert(result, {x = x, y = y - 1})
	table.insert(result, {x = x + 1, y = y - 1})
	table.insert(result, {x = x - 1, y = y})
	table.insert(result, {x = x + 1, y = y})
	table.insert(result, {x = x - 1, y = y + 1})
	table.insert(result, {x = x, y = y + 1})
	table.insert(result, {x = x + 1, y = y + 1})
	
	return result
end


function remove_generated_chunks(chunks)
	Util.filter(chunks, function(chunk)
		if game.surfaces[1].is_chunk_generated(chunk) == false then
			return true
		end
		
		return false
	end)
end


function chunk_area(position)
	return {left_top = {x = position.x * 32, y = position.y * 32}, right_bottom = {x = position.x * 32 + 32, y = position.y * 32 + 32}}
end


function area(min_x, min_y, max_x, max_y)
	return {left_top = {x = min_x, y = min_y}, right_bottom = {x = max_x, y = max_y}}
end


--------------------------------- debug


function draw_chunk_coords(position)
	if global.debug.draw_chunk_coords then
		rendering.draw_text{
			text = '['..position.x..']'..'['..position.y..']',
			surface = game.surfaces[1],
			target = {x = position.x * 32 + 12, y = position.y * 32 + 14},
			color = {1, 1, 1, 1},
			scale = 6,
			only_in_alt_mode = true,
		}
	end
end


function color_chunk(area, color)
	if global.debug.draw_chunk_colors then
		rendering.draw_rectangle{
			color = color,
			filled = false,
			left_top = {area.left_top.x + 0.5, area.left_top.y + 0.5},
			right_bottom = {area.right_bottom.x - 0.5, area.right_bottom.y-0.5},
			surface = game.surfaces[1],
			only_in_alt_mode = true,
		}
	end
end


function draw_resource_patch_boundaries(min_x, min_y, max_x, max_y)
	if global.debug.draw_resource_patch_boundaries then
		rendering.draw_rectangle {
			color = {1, 1, 1, 0.02},
			filled = false,
			left_top = {min_x - 0.5, min_y - 0.5},
			right_bottom = {max_x + 0.5, max_y + 0.5},
			surface = game.surfaces[1],
			only_in_alt_mode = true,
		}
	end
end


function draw_resource_colors(resources)
	if global.debug.draw_resource_colors then
		for _, resource in pairs(resources) do
			local color
			if Util.exists(global.infinite_resources, resource.position.x, resource.position.y) then
				color = {0, 1, 0, 0.005}
			else
				color = {1, 0, 0, 0.005}
			end
			rendering.draw_rectangle{
				color = color,
				filled = true,
				left_top = {resource.position.x - 0.5, resource.position.y - 0.5},
				right_bottom = {resource.position.x + 0.5, resource.position.y + 0.5},
				surface = game.surfaces[1],
				only_in_alt_mode = true,
			}
		end
	end
end

