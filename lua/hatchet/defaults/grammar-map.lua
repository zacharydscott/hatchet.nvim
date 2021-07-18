return {
	cursor_position = {
		b = 'start',
		e = 'end',
		precedence = 8
	},
	preposition = {
		i = 'in',
		a = 'around',
		precedence = 1
	},
	direction = {
		n = 'next',
		l = 'previous',
		precedence = 2
	},
	property = {
		r = 'return_type',
		b = 'body',
		p = 'parameters',
		d = 'name',
		m = 'implements',
		x = {'extends', 'expression'},
		h = 'heritage',
		c = {'condition', 'case', 'constructor'},
		e = 'else',
		precedence = 4
	},
	object = {
		f = 'function',
		c = 'class',
		['/'] = 'comment',
		m = 'method',
		s = 'switch',
		i = 'if',
		o = 'object',
		precedence = 16
	},
}

