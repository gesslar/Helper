-- helper.lua

-- Declare the helper table as local for encapsulation
helper = {
  _VERSION = '__VERSION__',
  _DESCRIPTION = 'Helper module with enhanced styling capabilities.',
  _URL = 'https://github.com/gesslar/Helper',
}

-- Module-level methods
local moduleMethods = {}

-- Default styles for headings
local defaultStyles = {
  h1 = "red",
  h2 = "blue",
  h3 = "yellow",
  h4 = "green",
  h5 = "magenta",
  h6 = "cyan",
}

-- Helper function to resolve namespaced functions
local function resolveFunction(namespacedName)
  local namespace, funcName = namespacedName:match("([^:]+):([^:]+)")
  if namespace and funcName then
    local ns = _G[namespace]
    if ns and type(ns[funcName]) == "function" then
      return ns, ns[funcName]
    end
  else
    -- If no namespace, attempt to get function from global scope
    return nil, _G[namespacedName]
  end
  return nil, nil -- Function not found
end

-- Function to merge user styles with default styles
local function mergeStyles(new_styles)
  local merged = table.deepcopy(defaultStyles)

  merged = table.update(merged, new_styles)

  return merged
end
-- Define the pattern to match style and function tags without arguments
local pattern = [[<(@?)(/?)([%w:]+)>]]

-- Function to process text and replace tags
local function processText(text, styles)
  styles = styles or {}
  -- Replacement function for gsub
  local function replacement(at, closing, name)
    if at == "@" then
      -- Resolve the namespaced function
      local ns, func = resolveFunction(name)

      if type(func) == "function" then
        -- Execute the function with or without 'self'
        local status, result_text, result_styles = pcall(func, ns)

        if status then
          if type(result_styles) == "table" then
            -- Merge existing styles with new styles
            local merged_styles = mergeStyles(result_styles)

            -- Recursively process the returned text with merged styles
            local processed_text = processText(result_text, merged_styles)

            return processed_text
          else
            -- No new styles; process the returned text with existing styles
            local processed_text = processText(result_text)
            return processed_text
          end
        else
          -- Handle function execution errors gracefully
          return "<error executing " .. name .. ">"
        end
      else
        -- If function doesn't exist or isn't allowed, indicate it's invalid
        return "<invalid function " .. name .. ">"
      end
    else
      local merged_styles = mergeStyles(styles) or {}

      -- Style tag processing
      if closing == "/" then
        return "<reset>"
      else
        return "<" .. (merged_styles[name:lower()] or name) .. ">"
      end
    end
  end

  -- Perform the replacement using gsub with the replacement function
  local new_text = text:gsub(pattern, replacement)

  return new_text
end

-- Enhanced print function using cecho for colored output in Mudlet
function moduleMethods.print(params)
  assert(type(params) == 'table', "Expected a table as parameter")
  local text = params.text or ""
  local styles = params.styles or {}

  -- Process the text to replace custom tags with Mudlet color tags
  local processedText = processText(text, styles)

  -- Print the styled text in Mudlet
  cecho(processedText .. "\n")   -- Using cecho for colored output in Mudlet
end

-- Existing module methods (format, capitalize, etc.)
function moduleMethods.format(params)
  assert(type(params) == 'table', "Expected a table as parameter")
  -- Example: Uppercase formatting
  return string.upper(params.text or "")
end

function moduleMethods.capitalize(params)
  assert(type(params) == 'table', "Expected a table as parameter")
  local text = params.text or ""
  return text:sub(1, 1):upper() .. text:sub(2)
end

-- Instance methods
local instanceMethods = {}

function instanceMethods:print(params)
  assert(type(params) == 'table', "Expected a table as parameter")
  local text = params.text or ""
  local styles = params.styles or {}

  -- Process the text to replace custom tags with Mudlet color tags
  local processedText = processText(text, styles)

  -- Print the styled text in Mudlet
  cecho(processedText .. "\n")   -- Using cecho for colored output in Mudlet
end

function instanceMethods:format(params)
  assert(type(params) == 'table', "Expected a table as parameter")
  -- Example: Lowercase formatting
  return string.lower(params.text or "")
end

function instanceMethods:reversePrint(params)
  assert(type(params) == 'table', "Expected a table as parameter")
  local text = params.text or ""
  local reversed = text:reverse()
  cecho(reversed .. "\n")   -- Using cecho for colored output in Mudlet
end

-- Metatable for instances
local instanceMetatable = {
  __index = instanceMethods,
  __tostring = function(self)
    return string.format("Helper Instance - Version: %s", helper._VERSION)
  end
}

-- Constructor for creating new instances
local function newInstance()
  local obj = {
    -- Initialize instance-specific fields if any
  }
  setmetatable(obj, instanceMetatable)
  return obj
end

-- Make the helper table callable
setmetatable(helper, {
  __call = function(_, ...)
    return newInstance(...)
  end,
  __index = moduleMethods   -- Redirect method lookups to moduleMethods
})

-- Assign module-level methods to helper table
for name, func in pairs(moduleMethods) do
  helper[name] = func
end

-- Local helper functions for text styling (colors)
local function resetTextStyle()
  cecho("<reset>")   -- Reset all styles in Mudlet
end

-- You can keep or remove additional styling functions as needed
-- For this implementation, processText handles styling

return helper
