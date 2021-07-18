local grammar = require'hatchet.grammar'
local default_query_map = require'hatchet.defaults.query-map'
local default_grammar_map = require'hatchet.defaults.grammar-map'
local parse = require'hatchet.parse'
local query = require'hatchet.query'
local actions = require'hatchet.actions'
local api = vim.api

local function setup(config)
	grammar.set_grammar(config.grammar or default_grammar_map)
	query.set_query_map(config.queries or default_query_map)
end

local function resolve_direction(position)
	if position == 'next' then return 1
	elseif position == 'previous' then return -1
	else return 0
	end
end

local function target_position(position)
	if position == 'end' then return 1
	else return -1
	end
end

local function print_string_or_table(val)
	if type(val) == 'table' then
		local tab = val
		val = ''
		for i,v in ipairs(tab) do
			val = val..(i == 1 and '' or ', ')..v
		end
	end
	return val or ''
end

local function select()
	local lang = api.nvim_buf_get_option(buf,'filetype')
	local user_input = parse.get_user_input(lang)
	if not user_input then return end
	local object = query.get_object(user_input.object, lang)
	local direction = resolve_direction(user_input.direction)
	local target, offset_fn = query.get_target_and_offset(object, user_input.property, user_input.preposition)
	if not actions.query_select(object.parsed_query, target, direction, offset_fn, lang) then
		print('No instance of '..(print_string_or_table(target))..' found for '..(order or 'current')..' '..(user_input.object and ' '..user_input.object or '')..' '..(print_string_or_table(user_input.direction))..'.')
	end
end

local mov_direction, move_target_position, move_obj, move_target, move_offset_fn, move_parsed_query

local function move()
	local lang = api.nvim_buf_get_option(buf,'filetype')
	local user_input = parse.get_user_input(lang, grammar.movement_syntax)
	if not user_input then return end
	move_obj = query.get_object(user_input.object, lang)
	mov_direction = resolve_direction(user_input.direction)
	move_target_position = target_position(user_input.cursor_position)
	move_target, move_offset_fn = query.get_movement_target_and_offset(move_obj, user_input.property, user_input.preposition)
	move_parsed_query = move_obj.parsed_query
	actions.move_to_query(move_parsed_query, move_target, mov_direction, move_target_position, mov_offset_fn, lang)
end

local function repeat_move(reverse)
	local lang = api.nvim_buf_get_option(buf,'filetype')
	actions.move_to_query(move_parsed_query, move_target, reverse and -mov_direction or mov_direction, move_target_position, lang)
end

return { setup = setup, move = move, select = select, move_in_cursor_node = actions.move_in_cursor_node, repeat_move = repeat_move }
