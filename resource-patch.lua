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
local Queue = require('queue')

local ResourcePatch = {}


function spread_west(x, y, left_top, right_bottom, queue, traversed)
	if x - 1 >= left_top.x and Util.exists(traversed, x - 1, y) == false then
		Queue.pushright(queue, {x = x - 1, y = y})
	end
end


function spread_east(x, y, left_top, right_bottom, queue, traversed)
	if x + 1 <= right_bottom.x and Util.exists(traversed, x + 1, y) == false then
		Queue.pushright(queue, {x = x + 1, y = y})
	end
end


function spread_north(x, y, left_top, right_bottom, queue, traversed)
	if y - 1 >= left_top.y and Util.exists(traversed, x, y - 1) == false then
		Queue.pushright(queue, {x = x, y = y - 1})
	end
end


function spread_south(x, y, left_top, right_bottom, queue, traversed)
	if y + 1 <= right_bottom.y and Util.exists(traversed, x, y + 1) == false then
		Queue.pushright(queue, {x = x, y = y + 1})
	end
end


ResourcePatch.cur_spread_func = 0
ResourcePatch.spread_funcs = {}
ResourcePatch.spread_funcs[0] = spread_west
ResourcePatch.spread_funcs[1] = spread_east
ResourcePatch.spread_funcs[2] = spread_north
ResourcePatch.spread_funcs[3] = spread_south
ResourcePatch.spread = table_size(ResourcePatch.spread_funcs)


function ResourcePatch.patch_inside_patch(resources, left_top, right_bottom, ratio)
	local patch = {}

	local count = #resources

	for _, resource in pairs(resources) do
		Util.insert(patch, resource.position.x, resource.position.y, resource)
	end

	local inside_patch_size = math.floor(count * ratio)
	local inside_patch = {}
	
	if inside_patch_size == 0 then
		return inside_patch
	end

	local random_tile_position = ResourcePatch.choose_random_tile(resources, count)

	local candidates = {}
	local candidate_sum = 0

	Util.insert(inside_patch, random_tile_position.x, random_tile_position.y, true)

	for i = 1, inside_patch_size - 1, 1 do
		local to_choose = math.min(count - i, ResourcePatch.spread)
		local neighbors = ResourcePatch.choose_random_neighbors(patch, inside_patch, left_top, right_bottom, random_tile_position, to_choose)
		candidate_sum = candidate_sum + to_choose
		for _, neighbor in pairs(neighbors) do
			Util.compute(candidates, neighbor.x, neighbor.y, function(value)
				if value == nil then
					return 1
				end
				
				return value + 1
			end)
		end

		local tile_selected = false
		while tile_selected == false do
			for i,_ in pairs(candidates) do
				if tile_selected then
					break
				end
				for j, candidate in pairs(candidates[i]) do
					if math.random(candidate_sum) <= candidate then
						tile_selected = true
						Util.insert(inside_patch, i, j, true)
						candidate_sum = candidate_sum - candidate
						Util.remove(candidates, i, j)
						random_tile_position.x = i
						random_tile_position.y = j
						break
					end
				end
			end
		end
	end
	
	return inside_patch
end


function ResourcePatch.choose_random_neighbors(patch, inside_patch, left_top, right_bottom, position, to_choose)
	local neighbors = {}
	local queue = Queue.new()
	local traversed = {}

	Queue.pushright(queue, position)

	while to_choose > 0 do
		position = Queue.popleft(queue)
		
		local x = position.x
		local y = position.y
		if Util.exists(traversed, x, y) == false then
			Util.insert(traversed, x, y, true)

			if Util.exists(patch, x, y) and Util.exists(inside_patch, x, y) == false then
				table.insert(neighbors, position)
				to_choose = to_choose - 1
			end

			ResourcePatch.cur_spread_func = (ResourcePatch.cur_spread_func + 1) % ResourcePatch.spread
			for i = 1, ResourcePatch.spread, 1 do
				ResourcePatch.cur_spread_func = (ResourcePatch.cur_spread_func + 1) % ResourcePatch.spread
				ResourcePatch.spread_funcs[ResourcePatch.cur_spread_func](x, y, left_top, right_bottom, queue, traversed)
			end
		end
	end

	return neighbors
end


function ResourcePatch.choose_random_tile(resources, count)
	while true do
		for _, resource in pairs(resources) do
			if math.random(count) == count then
				return {x = resource.position.x, y = resource.position.y}
			end
		end
	end
end

return ResourcePatch

