local Utils = {}
Utils.__index = Utils

-- Finds an element in the array by name.
-- @param array: table[] -- Array of tables, each containing a 'name' field
-- @param name: string -- The name to search for
-- @return table|nil -- The table with the matching name, or nil if not found
function Utils:findByName(array, name)
  if array == nil then
    return nil
  end

  for i = 1, #array do
    if array[i].name == name then
      return array[i]
    end
  end
  return nil
end

-- Merge stages method
-- @param default_stages table<string, any> A table of default stages
-- @param custom_stages table<string, any> A table of custom stages to merge into default_stages
-- @return table The resulting table after merging custom_stages into default_stages
function Utils:mergeStages(default_stages, custom_stages)
  local result = default_stages
  for key, value in pairs(custom_stages) do
    result[key] = value
  end
  return result
end

--- Saves an array of strings to a file.
-- @param filename string: The name of the file to which data will be appended.
-- @param data table: An array of strings to be written to the file. Each element of the array should be a string.
function Utils:saveToFile(filename, data)
  local file = io.open(filename, "a")
  if file then
    for _, line in ipairs(data) do
      if line ~= {} then
        file:write(line .. "\n")
      end
    end
    file:close()
  end
end

return Utils
