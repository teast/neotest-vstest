local lib = require("neotest.lib")
local logger = require("neotest.logging")

local M = {}

---@class LineDirective
---@field reference_file string
---@field reference_line number

---@class LineDirectiveMap
---@field reference_file string
---@field generated_to_reference { [number]: number }
---@field reference_to_generated { [number]: number }
---@field generated_file string?

--- Parses #line directives from C# source code
--- Returns a table mapping generated file lines to reference file lines
--- and the reference file name
---@param source string C# source code
---@return LineDirectiveMap?
function M.parse_line_directives(source)
  local lines = vim.split(source, "\n", { trimempty = true })
  local reference_file = nil
  local generated_to_reference = {}
  local reference_to_generated = {}

  local current_reference_line = 1

  for i, line in ipairs(lines) do
    local directive_match = line:match("^%s*#line%s+(%d+)")
    if directive_match then
      current_reference_line = tonumber(directive_match)
    else
      generated_to_reference[i] = current_reference_line
      -- Only set if not already set (first occurrence wins)
      if not reference_to_generated[current_reference_line] then
        reference_to_generated[current_reference_line] = i
      end
    end

    local ref_file_match = line:match('^%s*#line%s+%d+%s+"(.+)"')
    if ref_file_match then
      reference_file = ref_file_match
    end
  end

  if not reference_file then
    return nil
  end

  return {
    reference_file = reference_file,
    generated_to_reference = generated_to_reference,
    reference_to_generated = reference_to_generated,
    generated_file = nil,  -- Will be set by dotnet_utils.cache_line_directives
  }
end

--- Translates a line number from the generated file to the reference file
---@param line_number number Line number in the generated file (1-indexed)
---@param directive_map LineDirectiveMap
---@return number? Translated line number in the reference file, or nil if not found
function M.translate_generated_to_reference(line_number, directive_map)
  local mapping = directive_map.generated_to_reference[line_number]
  if mapping then
    return mapping
  end
  return nil
end

--- Translates a line number from the reference file to the generated file
---@param line_number number Line number in the reference file (1-indexed)
---@param directive_map LineDirectiveMap
---@return number? Translated line number in the generated file, or nil if not found
function M.translate_reference_to_generated(line_number, directive_map)
  local mapping = directive_map.reference_to_generated[line_number]
  if mapping then
    return mapping
  end
  return nil
end

return M
