local api = vim.api
local fn = vim.fn

local grammar = {
	['preposition'] = {
		['i'] = 'in',
		['a'] = 'around',
		precedence = 0
	},
	['order'] = {
		['n'] = 'next',
		['p'] = 'previous',
		precedence = 1
	},
	['property'] = {
		['r'] = 'return_type',
		['b'] = 'body',
		['n'] = 'name',
		precedence = 2
	},
	['base'] = {
		['f'] = 'funtion',
		['c'] = 'class',
		['o'] = 'object',
		precedence = 4
	},
}

local default_hatchet_config = {
	grammar = {'preposition','order','property','base'}
}

_hatchet_config = default_hatchet_config

local grammar_order = {'preposition','order','property','base'}

local function grammar_match(input, grammar_name)
	local grammar_object = grammar[grammar_name] 
	return grammar_object[input], grammar_object.precedence
end

-- Find the tail match based on input and current grammar
local function find_matches(full_input, input_index, grammar_index)
	local max_expr_len =  table.getn(grammar_order)
	local input_len = table.getn(full_input) 
	if grammar_index > max_expr_len or max_expr_len - grammar_index < input_len - input_index then
		return {}
	end
	local current_char = full_input[input_index]
	local grammar_name = grammar_order[grammar_index]
	local grammar
	local precedence
	grammar, precedence = grammar_match(current_char, grammar_name)
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

local function evaluate_match_state(input,matches)
	local best_full_match
	local matches_exhuastive = true
	local input_len = table.getn(input)
	local last_prop = grammar_order[table.getn(grammar_order)]
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

local function get_user_input()
	local input = {}
	local full_match = nil
	while not full_match do
		table.insert(input, fn.nr2char(fn.getchar()))
		local matches = find_matches(input,1,1)
		if table.getn(matches) == 0 then
			print('no match found')
			return
		end
		print(input[table.getn(input)])
		local best_match, ex = evaluate_match_state(input,matches)
		if ex and best_match then
			full_match = best_match
		end
	end
	for i,v in pairs(full_match) do
		print(i,v)
	end
end

get_user_input()
