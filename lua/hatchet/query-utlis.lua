local function offset_inner_range(sr,sc,er,ec)
	if sr == er and sc == ec - 2 then
		return sr, sc + 1, er, ec -1
	end
	local lines = api.nvim_buf_get_lines(0, sr, er + 1, true)
	if sc == string.len(lines[1]) - 1 then
		sr = sr + 1
		sc = 0
	else
		sc = sc + 1
	end
	if ec == 1 then
		er = er - 1
		local len_lines = table.getn(lines)
		ec = string.len(lines[len_lines - 1]) 
		if ec == 0 then ec = 1 end
	else
		ec = ec - 1
	end
	return sr, sc, er, ec
end

-- local function offset_surrounding_char(sr,sc,er,ec)
-- 	local lines = api.nvim_buf_get_lines(0,sr,er + 1, true)
-- end

local function offset_trailing_range(sr,sc,er,ec)
	local lines = api.nvim_buf_get_lines(0, sr, er + 1, true)
	local last = lines[table.getn(lines)]
	local test_ec = string.sub(last,ec + 1, ec + 1)
	while test_ec and test_ec == ' ' do
		ec = ec + 1
		test_ec = string.sub(last,ec + 1, ec + 1)
	end
	return sr, sc, er, ec
end

local word_prepositions = {
	['in'] = nil,
	around = offset_trailing_range
}

local block_prepositions = {
	['in'] = offset_inner_range,
	around = nil
}

local word_property = {
	prepositions = word_prepositions,
	default_preposition = 'in'
}

local block_property = {
	prepositions = block_prepositions,
	default_preposition = 'in'
}

local target_body_prepositions = {
	['in'] = {
		offset_fn = offset_inner_range,
		target = 'body'
	},
	around = nil,
}

local word

return {
	offset_inner_range = offset_inner_range,
	offset_trailing_range = offset_trailing_range,
	word_prepositions = word_prepositions,
	block_prepositions = block_prepositions,
	target_body_prepositions = target_body_prepositions,
	word_property = word_property,
	block_property = block_property
}
