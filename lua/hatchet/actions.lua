local utils = require'nvim-treesitter.ts_utils'
local parsers = require'nvim-treesitter.parsers'
local ts = vim.treesitter
local api = vim.api

local function node_start_end_positions(node)
	local s_pos = {}
	local e_pos = {}
	s_pos[1], s_pos[2], e_pos[1], e_pos[2] = node:range()
	e_pos[2] = e_pos[2] - 1
	return s_pos, e_pos
end

local function position_difference(a, b)
	local row_dif = a[1] - b[1]
	local col_dif = a[2] - b[2]
	local dir = row_dif ~= 0 and row_dif or col_dif
	return dir, {row_dif, col_dif}
end

local function node_to_cursor(node, offset, win)
	local c_pos = api.nvim_win_get_cursor(win)
	c_pos[1] = c_pos[1] - 1
	c_pos[2] = c_pos[2]
	local s_pos, e_pos = node_start_end_positions(node)
	s_pos[2] = s_pos[2] - (offset or 0)
	e_pos[2] = e_pos[2] + (offset or 0)
	local s_dir, s_dif = position_difference(s_pos,c_pos)
	local e_dir, e_dif = position_difference(e_pos,c_pos)
	return s_dir, e_dir, s_dif, e_dif
end

local function find_target_list(query, base_node, target, start_direction, end_direction, offset)
	local start_row, start_col, end_row, end_col = base_node:range()
	matches = {}
	for id,node in query:iter_captures(base_node, 0, start_row, end_row +1) do
		local tag = query.captures[id] 
		local match = false
		if type(target) == 'string' then
			match = tag == target
		elseif type(target) == 'table' then
			for _,v in ipairs(target) do
				if v == tag then
					match = true
					break
				end
			end
		end
		if (match) then
			local s_dir, e_dir, s_dif, e_dif = node_to_cursor(node, offset, 0)
			if (not start_direction or s_dir*start_direction > 0) and
				(not end_direction or e_dir*end_direction > 0) then
				table.insert(matches, {node = node, s_dif = s_dif, e_dif = e_dif})
			end
		end
		::capture::
	end
	return matches
end

local function find_closer_dif(a,b)
	if not a then return b end
	if not b then return a end
	local dif = (a[1] < 1 and -a[1] or a[1]) - (b[1] < 1 and -b[1] or b[1])
	if dif == 0 then 
		dif =  (a[2] < 2 and -a[2] or a[2]) - (b[2] < 2 and -b[2] or b[2])
	end
	return  dif > 0 and b or a
end

local function get_query_node(query, target, direction, target_position, lang)
	local adjusted_target
	local postfix = target_position == -1 and '_start' or '_end'
	if type(target) == 'string' then
		adjusted_target = {target, target..postfix}
	else
		adjusted_target = {}
		for _,v in ipairs(target) do
			table.insert(adjusted_target, v)
			table.insert(adjusted_target, v..postfix)
		end
	end
	local curr_node = utils.get_node_at_cursor()
	print(curr_node)
	local start_direction
	local end_direction
	if direction ~= 0 then
		start_direction = target_position == -1 and direction
		end_direction  = target_position == 1 and direction
	end
	local best_match
	while curr_node do
		local roots = find_target_list(query, curr_node, 'root', direction == 0 and -1, direction == 0 and 1, direction and 1)
		for _,root in ipairs(roots) do
			local matches = find_target_list(query, root.node, adjusted_target, start_direction, end_direction)
			for _, match in ipairs(matches) do
				if direction == 0 then
					local match_roots = find_target_list(query, root.node, 'root', start_direction, end_direction, 1)
					local curr_root = curr_node
					while curr_root do
						for _,v in ipairs(match_roots) do
							if curr_root == v.node then
								goto curr
							end
						end
						curr_root = curr_root:parent()
					end
					::curr::
					local match_root = match.node
					while match_root do
						for _,v in ipairs(match_roots) do
							if match_root == v.node then
								goto match
							end
						end
						match_root = match_root:parent()
					end
					::match::
					if curr_root ~= match_root or not curr_root then
						goto match_loop
					end
				end
				if not best_match then
					best_match = match
				elseif target_position == -1 and find_closer_dif(best_match.s_dif, match.s_dif) == match.s_dif then
					best_match = match
				elseif target_position == 1 and find_closer_dif(best_match.e_dif, match.e_dif) == match.e_dif then
					best_match = match
				end
				::match_loop::
			end
		end
		if best_match then return best_match.node end
		curr_node = curr_node:parent()
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

local function move_to_query(query, target, direction, target_position, offset_fn, lang)
	local node = get_query_node(query, target, direction, target_position, lang)
	if not node then return false end
	local sr, sc, er, ec = node:range()
	ec = ec - 1
	print(sr, sc, er, ec)
	if offset_fn then
		sr, sc, er, ec = offset_fn(sr, sc, er, ec)
	end
	print(sr, sc, er, ec,target_position)
	if target_position == 1 then
		api.nvim_win_set_cursor(0,{er + 1, ec})
	else 
		api.nvim_win_set_cursor(0,{sr + 1, sc})
	end
	return true
end

local function query_select(query, target, direction, offset_fn, lang)
	local node = get_query_node(query, target, direction, -direction, lang)
	if not node then return false end
	local sr, sc, er, ec = node:range()
	ec = ec + 1
	if offset_fn then
		sr, sc, er, ec = offset_fn(sr, sc, er, ec)
	end
	set_visual_selection(sr, sc, er, ec)
	return true
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
	query_select = query_select,
	move_to_query = move_to_query
}
