-- from: 
-- https://github.com/ReallySnazzy/single-file-lua-json-parser/blob/main/json.lua

--json lib

do
	-- Converts non-string-friendly characters into a friendly string
	local function escape(ch)
		if ch == '\a' then return '\\a' end
		if ch == '\b' then return '\\b' end
		if ch == '\f' then return '\\f' end
		if ch == '\n' then return '\\n' end
		if ch == '\r' then return '\\r' end
		if ch == '\t' then return '\\t' end
		if ch == '\v' then return '\\v' end
		if ch == '\\' then return '\\\\' end
		if ch == '\"' then return '\\\"' end
		if ch == '\'' then return '\\\'' end
		return ch
	end

	-- Converts a friendly string into its original
	local function unescape_str(str)
		local escapes = {
			['a'] = '\a',
			['b'] = '\b',
			['f'] = '\f',
			['n'] = '\n',
			['r'] = '\r',
			['t'] = '\t',
			['v'] = '\v',
			['\\'] = '\\',
			['"'] = '\"',
			['\''] = '\'',
			['['] = '[',
			[']'] = ']',
		}
		local escaped = false
		local res = {}
		for i = 1, str:len() do
			local ch = str:sub(i, i)
			if not escaped then
				if ch == '\\' then
					escaped = true
				else
					table.insert(res, ch)
				end
			else
				local match = escapes[ch]
				assert(match ~= nil, "Unknown escape sequence")
				table.insert(res, match)
			end
		end
		return table.concat(res, '')
	end

	-- Converts a string into its JSON representation
	local function str_to_str(s)
		local res = {}
		for i = 1, s:len() do
			table.insert(res, escape(s:sub(i, i)))
		end
		return "\"" .. table.concat(res, '') .. "\""
	end

	-- Converts a table into its JSON representation
	local function tab_to_str(t)
		if #t == 0 then
			-- Sorting keys to give a deterministic output
			local keys = {}
			for k, _ in pairs(t) do
				table.insert(keys, k)
			end
			table.sort(keys)
			-- Creating list of "k": to_str(v)
			local items = {}
			for i = 1, #keys do
				local k = keys[i]
				local v = t[k]
				table.insert(items, "\"" .. k .. "\"" .. ":" .. to_json_str(v))
			end
			-- Concatenate list together
			return '{' .. table.concat(items, ',') .. '}'
		else
			local items = {}
			for i, v in ipairs(t) do
				table.insert(items, to_json_str(v))
			end
			return '[' .. table.concat(items, ',') .. ']'
		end
	end

	local TOKEN_TYPE_OP = 'op'
	local TOKEN_TYPE_STR = 'str'
	local TOKEN_TYPE_NUM = 'num'
	local TOKEN_TYPE_SPACE = 'space'
	local TOKEN_TYPE_ID = 'id' -- mostly for true/false/null

	local function Token(typ, val)
		assert(typ == TOKEN_TYPE_OP or typ == TOKEN_TYPE_STR or typ == TOKEN_TYPE_ID or typ == TOKEN_TYPE_SPACE or typ == TOKEN_TYPE_NUM, "Invalid token type")
		return {
			typ = typ,
			val = val
		}
	end

	local function ParserState(str)
		return {
			source = str,
			indx = 1,
			tokens = {}
		}
	end

	-- Returns true only when the source string has finished being consumed
	local function parser_has_more(parser_state)
		return parser_state.indx <= parser_state.source:len()
	end

	-- A few tests. TODO: More rigorous tests
	function test_json_lib()
		local result = "{\"escapes\":\"\\r\\n\\tf\",\"nums\":[1,2,4,5,9,12],\"other\":[true,false],\"people\":[\"john\",\"becky\"]}"
		local t = {
			["nums"] = {1, 2, 4, 5, 9, 12},
			["people"] = {"john", "becky"},
			["escapes"] = "\r\n\tf",
			["other"] = {true, false, nil}
		}
		assert(to_json_str(t) == result, "to_str test 1 failed")
		print("test_json_lib() tests passed")
	end

	-- Consumes a string from the ParserState and saves it in its tokens
	local function parse_next_str(parser_state)
		local indx = parser_state.indx
		local done = false
		indx = indx + 1
		local data = {}
		while indx < parser_state.source:len() and (parser_state.source:sub(indx, indx) ~= '\"' or parser_state.source:sub(indx - 1, indx - 1) == '\\') do
			table.insert(data, parser_state.source:sub(indx, indx))
			indx = indx + 1
		end
		assert(parser_state.source:sub(indx, indx) == '\"', "Unclosed string")
		local raw_str = table.concat(data, '')
		parser_state.indx = indx + 1
		table.insert(parser_state.tokens, Token(TOKEN_TYPE_STR, unescape_str(raw_str)))
	end

	-- Consumes a number from the ParserState and saves it in its tokens
	local function parse_next_num(parser_state)
		local indx = parser_state.indx
		local data = {}
		while true do
			local ch = parser_state.source:sub(indx, indx)
			if ch == '.' or ch == '-' or ch:match('%d') then
				table.insert(data, ch)
				indx = indx + 1
			else
				break
			end	
		end
		local num_str = table.concat(data, '')
		local num = tonumber(num_str)
		if num == nil then
			error("Invalid number" .. num_str)
		end
		parser_state.indx = indx
		table.insert(parser_state.tokens, Token(TOKEN_TYPE_NUM, num))
	end

	-- Parses the next operator in the ParserState
	local function parse_next_op(parser_state)
		-- Already checked op is valid in parse_next()
		local ch = parser_state.source:sub(parser_state.indx, parser_state.indx)
		table.insert(parser_state.tokens, Token(TOKEN_TYPE_OP, ch))
		parser_state.indx = parser_state.indx + 1
	end

	-- Parses the next identifier (true/false/null) in the ParserState
	local function parse_next_identifier(parser_state)
		local indx = parser_state.indx
		local data = {}
		while true do
			local ch = parser_state.source:sub(indx, indx)
			if string.match(ch, '%a') then
				table.insert(data, ch)
				indx = indx + 1
			else
				break
			end
		end
		parser_state.indx = indx
		local str = table.concat(data, '')
		if str ~= "true" and str ~= "false" and str ~= "null" then
			error("Unknown identifier")
		end
		local val = nil
		if str == 'true' then val = true end
		if str == 'false' then val = false end
		table.insert(parser_state.tokens, Token(TOKEN_TYPE_ID, val))
	end

	-- Strips the whitespace from the ParserState
	local function parse_next_space(parser_state)
		while parser_state.source:sub(parser_state.indx, parser_state.indx):match('%s') do
			parser_state.indx = parser_state.indx + 1
		end
	end

	-- Gets the next token from the ParserState
	local function parse_next(parser_state)
		local ch = parser_state.source:sub(parser_state.indx, parser_state.indx)
		if ch == '\"' then
			parse_next_str(parser_state)
		elseif ch == '-' or ch == '.' or tonumber(ch) ~= nil then
			parse_next_num(parser_state)
		elseif ch == ':' or ch == ',' or ch == '{' or ch == '}' or ch == '[' or ch == ']' then
			parse_next_op(parser_state)
		elseif string.match(ch, '%a') then
			parse_next_identifier(parser_state)
		elseif string.match(ch, '%s') then
			parse_next_space(parser_state)
		else
			error("Invalid token")
		end
	end

	-- An object for keeping track of the document building
	local function DocumentTreeBuildState(tokens)
		return {
			tokens = tokens,
			indx = 1
		}
	end

	-- Checks to see what token is next
	local function tree_peek_tk(tree_state)
		return tree_state.tokens[tree_state.indx]
	end

	-- Consumes a token from the DocumentTreeBuildState
	local function tree_consume_tk(tree_state)
		local result = tree_peek_tk(tree_state)
		tree_state.indx = tree_state.indx + 1
		return result
	end

	-- Checks if any tokens remain in the DocumentTreeBuildState
	local function tree_has_more(tree_state)
		return tree_peek_tk(tree_state) ~= nil
	end

	-- Predefining construct_tree
	local construct_tree

	-- Consumes the map parts of a JSON document
	local function construct_tree_map(tree_state)
		local result = {}
		local done = false
		while not done do
			if tree_peek_tk(tree_state).typ == TOKEN_TYPE_STR then
				local key = tree_consume_tk(tree_state).val
				assert(tree_consume_tk(tree_state).val == ':', "Expected :")
				local val = construct_tree(tree_state)
				result[key] = val
			else
				assert("String key expected")
			end
			assert(tree_has_more(tree_state), "Expected , or } to complete {")
			if tree_peek_tk(tree_state).val == ',' then
				tree_consume_tk(tree_state)
			else
				done = true
			end
		end
		return result
	end

	-- Consumes the array parts of a JSON document
	local function construct_tree_array(tree_state)
		local result = {}
		local done = false
		while not done do
			local peek = tree_peek_tk(tree_state)
			if peek.typ == TOKEN_TYPE_OP then
				if peek.val == ']' then
					done = true
				elseif peek.val == ',' then
					tree_consume_tk(tree_state)
				elseif peek.val == '{' or peek.val == '[' then
					table.insert(result, construct_tree(tree_state))
				else
					error("Expected ] or , got " .. peek.val)
				end
			else
				table.insert(result, tree_consume_tk(tree_state).val)
			end
		end
		return result
	end

	-- Consumes all other parts of a JSON document
	construct_tree = function(tree_state)
		if tree_peek_tk(tree_state).typ == TOKEN_TYPE_OP then
			local op = tree_consume_tk(tree_state).val
			if op == '{' then
				local result = construct_tree_map(tree_state)
				assert(tree_peek_tk(tree_state).val == '}', "Expected } to close {, got " .. tree_peek_tk(tree_state).typ)
				tree_consume_tk(tree_state)
				return result
			elseif op == '[' then
				local result = construct_tree_array(tree_state)
				assert(tree_consume_tk(tree_state).val == ']', "Expected ] to close [")
				return result
			else
				error('Unexpected op ' .. op)
			end
		else
			return tree_consume_tk(tree_state).val
		end
	end

	-- Takes in a string and gives back a Lua table
	function parse_json(str)
		-- Get tokens
		local state = ParserState(str)
		while parser_has_more(state) do
			parse_next(state)
		end
		-- Construct tree
		local tree_state = DocumentTreeBuildState(state.tokens)
		local result = construct_tree(tree_state)
		assert(tree_has_more(tree_state) == false, "Unexpected tokens following end of document")
		return result
	end

	-- Converts a Lua table into a JSON string
	function to_json_str(t)
		if t == nil then
			return 'null'
		elseif type(t) == 'table' then
			return tab_to_str(t)
		elseif type(t) == 'number' then
			return tostring(t)
		elseif type(t) == 'boolean' then
			return tostring(t)
		elseif type(t) == 'string' then
			return str_to_str(t)
		end
	end
end
