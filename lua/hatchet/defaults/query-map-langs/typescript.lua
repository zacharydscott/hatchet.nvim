local util = require'hatchet.query-utlis'
local w = util.word_property
local b = util.block_property
local bp = util.block_prepositions
local off_word = util.offset_trailing_range
local target_body_prepositions = util.target_body_prepositions

return {
	['function'] = {
		query = [[
		[(function_declaration (identifier) @name (formal_parameters) @parameters (statement_block) @body) @root
		(method_definition  (property_identifier) @name (formal_parameters) @parameters (type_annotation (_)? @return_type_inner )? @return_type (statement_block) @body) @root
		(arrow_function (formal_parameters) @parameters (statement_block) @body) @root ]
		]],
		properties = {
			name = w,
			parameters = b,
			return_type = {
				prepositions = {
					['in'] = {
						target = return_type_inner,
						offset_fn = off_word
					},
					default_preposition = 'in'
				},
			},
			body = b,
		},
		prepositions = target_body_prepositions,
		default_preposition = 'in',
	},
	switch = {
		query = [[
			(switch_statement
				(parenthesized_expression) @expression
				(switch_body
					[(switch_case
						. (_) @value
						. (_)? @case_logic_start
						 (_)? @case_logic_end .
					)
					(switch_default
						. (_)? @case_logic_start
						 (_)? @case_logic_end .
					 )
					]? @case
				) @body
			) @root
		]],
		prepositions = target_body_prepositions,
		default_preposition = 'around',
		properties = {
			body = b,
			expression = b,
			case = {
				prepositions = {
					['in'] = {target = 'case_logic', offset_fn = off_word},
					around = w
				}
			}
		}
	},
	['method'] = {
		query = [[
		[
		(method_definition) @root
		]
		]],
		properties = {
			name = w,
			parameters = b,
			body = b
		},
		prepositions = target_body_prepositions,
		default_preposition = 'in',
	},
	class = {
		query = [[
		(class_declaration
		(type_identifier) @name
		(class_heritage 
		(extends_clause (type_identifier)? @inner_extends )? @extends
		(implements_clause . (type_identifier)? @inner_implements_start (type_identifier)?  @inner_implements_end . )? @implements
		)? @heritage
		(class_body) 
		@body) @root
		]],
		properties = {
			name = w,
			body = b,
			extends = {
				prepositions = {
					['in'] = {
						target = 'inner_extends',
						offset_fn = off_word
					},
					around = off_word
				},
				default_preposition = 'around'
			},
			implements = {
				prepositions = {
					['in'] = {
						target = 'inner_implements',
						offset_fn = off_word
					},
					around = off_word
				},
				default_preposition = 'around'
			},
			heritage = w
		},
		prepositions = target_body_prepositions,
		default_preposition = 'in'
	},
	object = {
		query = [[(object) @root]],
		prepositions = bp
	}
}
