local utils = require'nvim-treesitter.ts_utils'
local parsers = require'nvim-treesitter.parsers'
local ts = vim.treesitter
local api = vim.api


local function is_cursor_in_node(node,win)
	local cursor_row, cursor_col = unpack(api.nvim_win_get_cursor(win))
	cursor_row = cursor_row - 1
	cursor_col = cursor_col - 1
	local start_row, start_col, end_row, end_col = node:range()
	return (cursor_row > start_row or (cursor_row == start_row and cursor_col >= start_col))and
	(cursor_row < end_row or (cursor_row == end_row and cursor_col <= end_col))
end

local function find_cursor_node_position(node,win)
	local cursor_row, cursor_col = unpack(api.nvim_win_get_cursor(win))
	cursor_row = cursor_row - 1
	cursor_col = cursor_col - 1
	local start_row, start_col, end_row, end_col = node:range()
	if cursor_row < start_row or (cursor_row == start_row and cursor_col + 1 < start_col) then
		return 1, start_row - cursor_row, start_col - cursor_col
	elseif  cursor_row > end_row or (cursor_row == end_row and cursor_col + 2 > end_col) then
		return -1, cursor_row - end_row, cursor_col - end_col
	else
		return 0, 0, 0
	end
end

local function set_visual_selection(sr,sc,er,ec)
	local mode = api.nvim_get_mode()
	if mode == 'v' then
		nvim.cmd('normal! <ESC>')
	end
	local save_sel = api.nvim_get_option('selection')
	api.nvim_set_option('selection','exclusive')
	api.nvim_win_set_cursor(0,{sr+1,sc})
	vim.cmd('normal! v')
	api.nvim_win_set_cursor(0,{er+1,ec-1})
	api.nvim_set_option('selection',save_sel)
end

local function find_target(query, base_node, target, target_position)
	local start_row, start_col, end_row, end_col = base_node:range()
	local found_root = nil
	local cursor_node_position
	local found_row_dif, found_col_dif
	for id,node in query:iter_captures(base_node, 0, start_row, end_row +1) do
		local tag = query.captures[id] 
		local match = false
		if type(target) == 'string' then
			match = tag == target
				  print(target,tag)
		elseif type(target) == 'table' then
			for _,v in ipairs(target) do
			  if v == tag then
				  print(v,tag)
				  match = true
				  break
			  end
			end
		end
		if (match) then
			local cnp, row_dif, col_dif = find_cursor_node_position(node,0)
			if (cnp == target_position) or not target_position then
			print(cnp,row_dif, col_dif, target_position)
			print((cnp ==target_position) or not target_position)
				if not found_root then
			print('hello',found_root)
					found_root = node
					found_row_dif = row_dif
					found_col_dif = col_dif
				elseif found_row_dif > row_dif or found_row_dif == row_dif and found_col_dif > col_dif then
					found_root = node
					found_row_dif = row_dif
					found_col_dif = col_dif
				end
			end
		end
	end
	return found_root
end

local function query_at_cursor(query, target, target_position)
	local curr_node = utils.get_node_at_cursor()
	while curr_node do
		local found_root = find_target(query, curr_node, 'root', nil)
		if (found_root) then
			local check_match = find_target(query, found_root, target, target_position)
			return 
		end
		curr_node = curr_node:parent()
	end
end

local function find_query_coordinates(query, target, offset_fn, target_position, lang)
	local node = query_at_cursor(query, target, target_position)
	local sr, sc, er, ec
	if node then
		sr, sc, er, ec = node:range()
	else
		if type(target) == 'table' then
			local start_target = {}
			local end_target = {}
			for i,v in ipairs(target) do
			  start_target[i] = v..'_start'
			  end_target[i] = v..'_end'
			end
			local start_node = query_at_cursor(query,start_target, target_position)
			local end_node = query_at_cursor(query, end_target, target_position)
		else
			local start_node = query_at_cursor(query, target..'_start')
			local end_node = query_at_cursor(query, target..'_end')
		end
		if not start_node then
			return nil, nil, nil, nil
		end
		sr, sc, er, ec = start_node:range()
		local end_range
		if end_node then
			_, _, er, ec = end_node:range()
		end
	end
	if offset_fn then
		sr, sc, er, ec  = offset_fn(sr, sc, er, ec )
	end
	return sr, sc, er, ec 
end

local function move_query(query, target, target_position, lang, cursor_position)
	local sr, sc, er, ec  = find_query_coordinates(query, target, nil, target_position, lang)
	if er and ec and cursor_position == 1 then
		api.nvim_win_set_cursor(0,{er+1,ec})
		return truee
	elseif sr and sc then
		api.nvim_win_set_cursor(0,{sr+1,sc})
		return true
	else
		return false
	end
end

local function select_query(query, target, offset_fn, target_position, lang)
	local sr, sc, er, ec  = find_query_coordinates(query, target, offset_fn, target_position, lang)
	if sr and sc and er and ec then
		set_visual_selection(sr, sc, er, ec )
		return true
	else
		return false
	end
end

local function move_to_node(node, start_end)
	sr, sc, er, ec = node:range()
	r = start_end == 1 and er or sr
	c = start_end == 1 and ec or sc
	api.nvim_win_set_cursor(0,{r+1,c -1})
end

local function move_in_cursor_node(start_end)
	move_to_node(utils.get_node_at_cursor(),start_end)
end

return {
	select = select,
	move_to_node = move_to_node,
	move_in_cursor_node = move_in_cursor_node,
	select_query = select_query,
	move_query = move_query
}
