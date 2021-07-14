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

local function resolvePosition(position)
	if position == 'next' then return 1
	elseif position == 'previous' then return -1
	else return 0
	end
end

local function resolveCursorPosition(position)
	if position == 'end' then return 1
else return -1
end
end

local function printStringOrTable(val)
	if type(val) == 'table' then
		local tab = val
		val = ''
		for i,v in ipairs(tab) do
			val = val..(i == 1 and '' or ', ')..v
		end
	end
	return val
end

local function select()
	local lang = api.nvim_buf_get_option(buf,'filetype')
	local user_input = parse.get_user_input(lang)
	if not user_input then return end
	local object = query.get_object(user_input.object, lang)
	local position = resolvePosition(user_input.position)
	local target, offset_fn = query.get_target_and_offset(object, user_input.property, user_input.preposition)
	if not actions.select_query(object.parsed_query, target, offset_fn, position, lang) then
		print('No instance of '..(printStringOrTable(target))..' found for '..(order or 'current')..' '..(user_input.object and ' '..user_input.object or '')..' '..(printStringOrTable(user_input.property))..'.')
		print('No instance of '..(printStringOrTable(target))..' found for '..(order or 'current')..' '..(user_input.object and ' '..user_input.object or '')..' '..(printStringOrTable(user_input.property))..'.')
	end
end

local move_pos, move_cursor_pos, move_obj, move_target, move_offset_fn, move_parsed_query

local function move()
	local lang = api.nvim_buf_get_option(buf,'filetype')
	local user_input = parse.get_user_input(lang, grammar.movement_syntax)
	if not user_input then return end
	move_obj = query.get_object(user_input.object, lang)
	move_pos = resolvePosition(user_input.position)
	move_cursor_pos = resolveCursorPosition(user_input.cursor_position)
	move_target, move_offset_fn = query.get_movement_target_and_offset(move_obj, user_input.property, user_input.preposition)
	move_parsed_query = move_obj.parsed_query
	actions.move_query(move_parsed_query, move_target, move_pos, lang, move_cursor_pos)
end

local function repeat_move(reverse)
	local lang = api.nvim_buf_get_option(buf,'filetype')
	actions.move_query(move_parsed_query, move_target, reverse and -move_pos or move_pos, lang, move_cursor_pos)
end

return { setup = setup, move = move, select = select, move_in_cursor_node = actions.move_in_cursor_node, repeat_move = repeat_move }
