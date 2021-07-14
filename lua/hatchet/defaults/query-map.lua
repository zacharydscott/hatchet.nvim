local langs = {
	'lua',
	'typescript'
}

local query_map = {}

for _,v in ipairs(langs) do
	query_map[v] = require('hatchet.defaults.query-map-langs.'..v)
end

return query_map

