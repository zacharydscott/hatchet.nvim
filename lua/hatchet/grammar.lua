-- [[
--	The grammar map consists of a base layer, and a language specific map which will take precedence.
---- ]]

local grammar = {
}

local syntax = {
	'preposition','direction','property','object'
}

local movement_syntax = {
   'cursor_position','direction','property','object'
}



local lang_map = { }

local function new_map() 
	return {
		['preposition'] = { },
		['order'] = { },
		['direction'] = { },
		['property'] = { },
		['object'] = { },
	}
end

local function set_grammar(map)
	grammar = map
end

local function set_movement_grammar(map)
	movement_syntax = map
end

local function register_language(language, map)
	if not map then
		map = new_map()
	end
	lang_map[language] = map
end

local function match_input(input, grammar_name, language)
	local gram = lang_map[language] or grammar
	local gram_obj = gram[grammar_name]
	return gram_obj[input], gram_obj.precedence
end

return {
	new_map = new_map,
	set_grammar = set_grammar,
	register_language = register_language,
	match_input = match_input,
	syntax = syntax,
	movement_syntax = movement_syntax,
	grammar = grammar
}
