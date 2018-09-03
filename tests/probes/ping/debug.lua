-- Helper Functions:

-- Resource: http://lua-users.org/wiki/TypeOf
function typeof(var)
    local _type = type(var);
    if(_type ~= "table" and _type ~= "userdata") then
        return _type;
    end
    local _meta = getmetatable(var);
    if(_meta ~= nil and _meta._NAME ~= nil) then
        return _meta._NAME;
    else
        return _type;
    end
end

-- Resource: https://gist.github.com/lunixbochs/5b0bb27861a396ab7a86
local function string(o)
    return '"' .. tostring(o) .. '"'
end
 
local function recurse(o, indent)
    if indent == nil then indent = '' end
    local indent2 = indent .. '  '
    if type(o) == 'table' then
        local s = indent .. '{' .. '\n'
        local first = true
        for k,v in pairs(o) do
            if first == false then s = s .. ', \n' end
            if type(k) ~= 'number' then k = string(k) end
            s = s .. indent2 .. '[' .. k .. '] = ' .. recurse(v, indent2)
            first = false
        end
        return s .. '\n' .. indent .. '}'
    else
        return string(o)
    end
end
 
local function var_dump(...)
    local args = {...}
    if #args > 1 then
        var_dump(args)
    else
        print(recurse(args[1]))
    end
end

-- @end: Helper Functions

max_requests = 0
counter = 1

function setup(thread)
   thread:set("id", counter)
   
   counter = counter + 1
end

init = function(args)
  io.write("[init]\n")

  -- Check if arguments are set
  if not (next(args) == nil) then
    io.write("[init] Arguments\n")

    -- Loop through passed arguments
    for index, value in ipairs(args) do
      io.write("[init]  - " .. args[index] .. "\n")
    end
  end
end

done = function (summary, latency, requests)
   io.write("\nJSON Output\n")
   io.write("-----------\n\n")
   io.write("{\n")
   io.write(string.format("\t\"requests\": %d,\n", summary.requests))
   io.write(string.format("\t\"duration_in_microseconds\": %0.2f,\n", summary.duration))
   io.write(string.format("\t\"bytes\": %d,\n", summary.bytes))
   io.write(string.format("\t\"requests_per_sec\": %0.2f,\n", (summary.requests/summary.duration)*1e6))
   io.write(string.format("\t\"bytes_transfer_per_sec\": %0.2f,\n", (summary.bytes/summary.duration)*1e6))

   io.write("\t\"latency_distribution\": [\n")
   for _, p in pairs({ 50, 75, 90, 99, 99.999 }) do
      io.write("\t\t{\n")
      n = latency:percentile(p)
      io.write(string.format("\t\t\t\"percentile\": %g,\n\t\t\t\"latency_in_microseconds\": %d\n", p, n))
      if p == 99.999 then
          io.write("\t\t}\n")
      else
          io.write("\t\t},\n")
      end
   end
   io.write("\t]\n}\n")


  io.write("------------------------------\n")
  io.write("Requests\n")
  io.write("------------------------------\n")
  io.write(var_dump(latency))
  var_dump(requests)
  var_dump(summary)
  var_dump(latency)
  io.write(typeof(requests))
  io.write("Summary\n")
  io.write(typeof(summary))
  io.write("Latency\n")
  io.write(typeof(latency))


end
