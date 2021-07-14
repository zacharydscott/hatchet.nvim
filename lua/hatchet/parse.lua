local api = vim.api
local fn = vim.fn

local gm = require('hatchet.grammar')

-- Find the tail match based on input and current grammar
local function find_matches(full_input, input_index, grammar_index, lang, syntax)
	syntax = syntax or gm.syntax
	local max_expr_len =  table.getn(syntax)
	local input_len = table.getn(full_input) 
	if grammar_index > max_expr_len or max_expr_len - grammar_index < input_len - input_index then
		return {}
	end
	local current_char = full_input[input_index]
	local grammar_name = syntax[grammar_index]
	local grammar, precedence = gm.match_input(current_char, grammar_name,lang)
	local matches = {}
	local deffered_matches = find_matches(full_input, input_index, grammar_index + 1)
	for _,match in ipairs(deffered_matches) do
		table.insert(matches, match)
	end
	if grammar then
		if input_len == input_index then
			table.insert(matches, {
				[grammar_name] = grammar,
				precedence = precedence
			}
			)
		else
			local eager_matches = find_matches(full_input, input_index + 1, grammar_index + 1)
			for _,match in ipairs(eager_matches) do
				match[grammar_name] = grammar
				match.precedence = match.precedence + precedence
				table.insert(matches, match)
			end
		end
	end
	return matches
end

local function evaluate_match_state(input,matches, syntax)
	syntax = syntax or gm.syntax
	local best_full_match
	local matches_exhuastive = true
	local input_len = table.getn(input)
	local last_prop = syntax[table.getn(syntax)]
	for _, match in ipairs(matches) do
		if not match[last_prop] then
			matches_exhuastive = false
		end
		if not best_full_match or best_full_match.precedence < match.precedence then
			best_full_match = match
		end
	end
	return best_full_match, matches_exhuastive
end

local function get_user_input(lang, syntax)
	syntax = syntax or gm.syntax
	local input = {}
	local full_match = nil
	local best_match = nil
	while not full_match do
		local ex
		local next_char = fn.getchar()
		if next_char == 13 then
			if best_match then
				return best_match
			else
				print('No match found')
				return
			end
		elseif next_char == 27 then
			api.nvim_exec('normal! <esc>', true)
			return nil
		end
		next_char = fn.nr2char(next_char)
		table.insert(input, next_char)
		local matches = find_matches(input,1,1, lang, syntax)
		if table.getn(matches) == 0 then
			print('no match found')
			return
		end
		best_match, ex = evaluate_match_state(input,matches, syntax)
		if ex and best_match then
			full_match = best_match
		end
	end
	return full_match
end

return {
	get_user_input = get_user_input
}
