-- helper.lua

-- Declare the helper table as local for encapsulation
Helper = {
  _VERSION = '__VERSION__',
  _DESCRIPTION = 'Helper module with enhanced styling capabilities.',
  _URL = 'https://github.com/gesslar/Helper',
}
---@diagnostic disable-next-line: lowercase-global
helper = Helper

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
  -- Resolve defaults + caller styles once; reused for every style tag below.
  local merged_styles = mergeStyles(styles) or {}
  -- Replacement function for gsub
  local function replacement(at, closing, name)
    if at == "@" then
      -- Resolve the namespaced function
      local ns, func = resolveFunction(name)

      if type(func) == "function" then
        -- Namespaced tags pass the namespace as 'self'; plain tags get no args.
        local status, result_text, result_styles
        if ns then
          status, result_text, result_styles = pcall(func, ns)
        else
          status, result_text, result_styles = pcall(func)
        end

        if status then
          local next_styles = styles
          if type(result_styles) == "table" then
            -- Layer caller's styles, then function's styles (function wins)
            next_styles = {}
            for k, v in pairs(styles) do next_styles[k] = v end
            for k, v in pairs(result_styles) do next_styles[k] = v end
          end

          return processText(result_text, next_styles)
        else
          -- Handle function execution errors gracefully
          return "<error executing " .. name .. ">"
        end
      else
        -- If function doesn't exist or isn't allowed, indicate it's invalid
        return "<invalid function " .. name .. ">"
      end
    else
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
function Helper.print(params)
  assert(type(params) == 'table', "Expected a table as parameter")
  local text = params.text or ""
  local styles = params.styles or {}

  -- Process the text to replace custom tags with Mudlet color tags
  local processedText = processText(text, styles)

  -- Print the styled text in Mudlet
  cecho(processedText .. "\n") -- Using cecho for colored output in Mudlet
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
  cecho(processedText .. "\n") -- Using cecho for colored output in Mudlet
end

-- Metatable for instances
local instanceMetatable = {
  __index = instanceMethods,
  __tostring = function(_)
    return string.format("Helper Instance - Version: %s", Helper._VERSION)
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

-- Make the helper table callable as a constructor
setmetatable(Helper, {
  __call = function(_)
    return newInstance()
  end,
})

return Helper
