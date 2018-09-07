--[[
converts a given nested table to a string formatted for a monospaced, left aligned font
currently only supports the first nested table. all items must be able to be treated as strings.

usage: tabletostring(table, width of a column in spaces, space between columns in spaces)

if you want to use a full row for one item, make the first item in the nested table "_single"
ex: {"_single","YOUR HEADER HERE"}

example:

local t = {
		{"_single","PEOPLE & WEIGHT IN LBS"};
		{"===NAME===";"==WEIGHT=="};
		{"ANNA";143};
		{"JAKE";169};
		{"EMILY";122};
		{"KYLE";90};
		{"CONNOR";157};
		{"SAVANNAH";118};
		{"MITTENS";9};
}
print(nestedtabletostring(t,10,2))
--]]

function nestedtabletostring(t,columnwidth,columnspacing)
	result = ""
	for rownum,row in ipairs(t) do
		result = (rownum ~= 1 and result.."\n" or result)
		if row[1] == "_single" then
			result = result..row[2]
		else
			for column,item in ipairs(row) do
				local chars = string.len(item)
				if chars < columnwidth then
					for _=1,columnwidth-chars do
						item = " "..item
					end
				elseif chars > columnwidth then
					item = string.sub(item,1,columnwidth-2)..".."
				end
				result = result..item
				for _=1,columnspacing do
					result = result.." "
				end
			end
		end
	end
	return result
end

return nestedtabletostring