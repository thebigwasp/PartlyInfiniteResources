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

data:extend({
	{
		type = "double-setting",
		name = "partly-infinite-resources-minimum-yield",
		setting_type = "startup",
		default_value = 0.25,
		minimum_value = 0,
		maximum_value = 1,
	},
	{
		type = "double-setting",
		name = "partly-infinite-resources-ratio",
		setting_type = "runtime-global",
		default_value = 0.25,
		minimum_value = 0,
		maximum_value = 1,
	},
})
