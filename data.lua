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

for _, resource in pairs(data.raw.resource) do
	local settings_startup = settings.startup
	if resource.infinite == nil or resource.infinite == false then
		local infinite_resource = Util.shallow_copy(resource)
		
		infinite_resource.name = 'infinite-'..resource.name
		infinite_resource.autoplace = nil
		infinite_resource.infinite = true
		infinite_resource.normal = 10000
		infinite_resource.minimum = infinite_resource.normal * settings_startup["partly-infinite-resources-minimum-yield"].value
		infinite_resource.initial_amount = infinite_resource.normal
		infinite_resource.infinite_depletion_amount = 1
		
		data:extend({infinite_resource})
	end
end
