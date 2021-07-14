-- local off = require'hatchet.offset_fn'
local query_map = {}

local function set_query_map(map)
	query_map = map
end

local function register_query(query, name, language)
	if not query_map[language] then
		query_map[language] = {}
	end
	query_map[language][name] = query
end

local function get_object(object_name, lang)
	if not lang then
		local lang = api.nvim_buf_get_option(buf,'filetype')
	end
	if not query_map[lang] then
		print('No queries have been registered for '
		..lang..' files')
		return
	end
	local object = query_map[lang][object_name]
	if not object then
		print('No query for '..object_name..' in filetype ')
		return
	end
	if not object.parsed_query then
		object.parsed_query = vim.treesitter.parse_query(lang,object.query)
	end
	return object
end

local function get_target_and_offset(object, property_name, preposition_name)
	local offset_fn
	local property
	if not object.properties then
		property = object
	elseif not property_name then
		property = object.properties[object.default_property] or object
	elseif type(property_name) == 'string' then
		property = object.properties[property_name]
	elseif type(property_name) == 'table' and object.properties then
		for _,v in ipairs(property_name) do
			property = object.properties[v]
			if property then
				break
			end 
		end
	end
	local preps = property and property.prepositions
	if preps then 
		preposition = preps[preposition_name] or not preposition_name and property.default_preposition and preps[property.default_preposition]
	end
	local target = property and property.target or property_name or 'root'
	local offset_fn = property and property.offset_fn
	if type(preposition) == 'function' then
		offset_fn = preposition
	elseif type(preposition) == 'table' then
		target = preposition.target or target
		offset_fn = preposition.offset_fn or offset_fn
	end
	return target, offset_fn
end

local function get_movement_target_and_offset(object, property_name, preposition_name)
	local offset_fn
	local property
	if not object.properties then
		property = object
	elseif not property_name then
		property = object.properties[object.default_property] or object
	elseif type(property_name) == 'string' then
		property = object.properties[property_name]
	elseif type(property_name) == 'table' and object.properties then
		for _,v in ipairs(property_name) do
			property = object.properties[v]
			if property then
				break
			end 
		end
	end
	local preps = property and property.prepositions
	if preps then 
		preposition = preps[preposition_name] or not preposition_name and property.default_movement_preposition and preps[property.default_movement_preposition]
	end
	local target = property and property.target or property_name or 'root'
	local offset_fn = property and property.offset_fn
	if type(preposition) == 'function' then
		offset_fn = preposition
	elseif type(preposition) == 'table' then
		target = preposition.target or target
		offset_fn = preposition.offset_fn or offset_fn
	end
	return target, offset_fn
end

return {
	set_query_map = set_query_map,
	register_query = register_query,
	get_object = get_object,
	get_target_and_offset = get_target_and_offset,
	get_movement_target_and_offset = get_movement_target_and_offset
}
