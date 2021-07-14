local util = require'hatchet.query-utlis'
local w = util.word_property
local b = util.block_property

return {
	['function'] = {
		query = [[
			[(local_function (identifier) @name (parameters) @parameters . (_)? @body_start (_)? @body_end . ) @root
			(function (function_name) @name (parameters) @parameters . (_)? @body_start (_)? @body_end . ) @root
			]
			]],
		properties = {
			['name'] = w,
			['parameters'] = b
		},
		prepositions = {
			['in'] = { target = 'body' }
		},
	},
	['if'] = {
		query = [[(if_statement (condition_expression) @condition . (_)? @body_start ()? (!else)? @body_end . ) @root]],
		prepositions = {
			['in'] = { target = 'body' }
		}
	},
	['comment'] = {
		-- query = [[(local_function (identifier) @name (parameters) @parameters . (_)? @body_start (_)? @body_end . ) @root]],
		-- properties = {
		-- 	['name'] = w,
		-- 	['parameters'] = b
		-- },
		-- prepositions = {
		-- 	['in'] = { target = 'body' }
		-- },
		query = [[(_ . (comment) @root_start (comment) @root_end .)]], marker = 'hi',
		properties = {},
		prepositions = w
	},
	object = {
		query = [[(!object (object) @root)]]
	}
}
