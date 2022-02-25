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

local Util = {}

function Util.insert(table, x, y, value)
	if table[x] == nil then
		table[x] = {}
	end
	table[x][y] = value
end


function Util.remove(table, x, y)
	if table[x] ~= nil then
		table[x][y] = nil
	end
	if table_size(table[x]) == 0 then
		table[x] = nil
	end
end


function Util.exists(table, x, y)
	if table[x] ~= nil and table[x][y] ~= nil then
		return true
	end
	
	return false
end


function Util.compute(table, x, y, func)
	if table[x] == nil then
		table[x] = {}
	end
	table[x][y] = func(table[x][y])
end


function Util.filter(table, func)
	for k, v in pairs(table) do
		if func(v) == false then
			table[k] = nil
		end
	end
end


function Util.deep_copy(table)
	if type(table) == 'table' then
		local copy = {}
		for k, v in pairs(table) do
			copy[k] = Util.deep_copy(v)
		end
		
		return copy
	else
		return table
	end
end


function Util.shallow_copy(table)
	local copy = {}
	for k, v in pairs(table) do
		copy[k] = v
	end
	
	return copy
end

return Util
