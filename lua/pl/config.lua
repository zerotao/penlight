--- reads configuration files into a Lua table. <p>
--  Understands INI files, classic Unix config files, and simple
-- delimited columns of values. <p>
-- <pre class=example>
--    # test.config
--    # Read timeout in seconds
--    read.timeout=10
--    # Write timeout in seconds
--    write.timeout=5
--    #acceptable ports
--    ports = 1002,1003,1004
--
--        -- readconfig.lua
--    require 'pl'
--    local t = config.read 'test.config'
--    print(pretty.write(t))
--    
--    ### output #####
--   {
--      ports = {
--        1002,
--        1003,
--        1004
--      },
--      write_timeout = 5,
--      read_timeout = 10
--    }    
-- </pre>
-- See the Guide for further <a href="../../index.html#config">discussion</a>
-- @class module
-- @name pl.config

local type,tonumber,ipairs,io = type,tonumber,ipairs,io

local function split(s,re)
    local res = {}
    local t_insert = table.insert
    re = '[^'..re..']+'
    for k in s:gmatch(re) do t_insert(res,k) end
    return res
end

local function strip(s)
    return s:gsub('^%s+',''):gsub('%s+$','')
end

--[[
module ('pl.config',utils._module)
]]

local config = {}

--- like io.lines(), but allows for lines to be continued with '\'.
-- @param file a file-like object (anything where read() returns the next line) or a filename.
-- Defaults to stardard input.
-- @return an iterator over the lines
function config.lines(file)
    local f,openf,err
    local line = ''
    if type(file) == 'string' then
        f,err = io.open(file,'r')
        if not f then return nil,err end
        openf = true
    else
        f = file or io.stdin
        if not file.read then return nil, 'not a file-like object' end
    end
    if not f then return nil, 'file is nil' end
    return function()
        local l = f:read()
        while l do
            -- does the line end with '\'?
            local i = l:find '\\%s*$'
            if i then -- if so,
                line = line..l:sub(1,i-1)
            elseif line == '' then
                return l
            else
                l = line..l
                line = ''
                return l
            end
            l = f:read()
        end
        if openf then f:close() end
    end
end

--- read a configuration file into a table
-- @param file either a file-like object or a string, which must be a filename
-- @param cnfg a configuration table that may contain these fields:
-- <ul>
-- <li> variablilize make names into valid Lua identifiers (default true)</li>
-- <li> convert_numbers try to convert values into numbers (default true)</li>
-- <li> trim_space ensure that there is no starting or trailing whitespace with values (default true)</li>
-- <li> list_delim delimiter to use when separating columns (default ',')</li>
-- </ul>
-- @return nil,error_msg in case of an error, otherwise a table containing items
function config.read(file,cnfg)
    local f,openf,err
    if not cnfg then
        cnfg = {variablilize = true, convert_numbers = true,
                trim_space = true, list_delim=','
                }
    end
    local t = {}
    local top_t = t
    local variablilize = cnfg.variablilize
    local list_delim = cnfg.list_delim
    local convert_numbers = cnfg.convert_numbers
    local trim_space = cnfg.trim_space

    local function process_name(key)
        if variablilize then
            key = key:gsub('[^%w]','_')
        end
        return key
    end

    local function process_value(value)
        if list_delim and value:find(list_delim) then
            value = split(value,list_delim)
            for i,v in ipairs(value) do
                value[i] = process_value(v)
            end
        elseif convert_numbers and value:find('^[%d%+%-]') then
            local val = tonumber(value)
            if val then value = val end
        end
        if trim_space and type(value) == 'string' then
            value = strip(value)
        end
        return value
    end

    local iter,err = config.lines(file)
    if not iter then return nil,err end
    for line in iter do
        -- strips comments
        local ci = line:find('%s*[#;]')
        if ci then line = line:sub(1,ci-1) end
        -- and ignore blank lines
        if  line:find('^%s*$') then
        elseif line:find('^%[') then -- section!
            local section = process_name(line:match('%[([^%]]+)%]'))
            t = top_t
            t[section] = {}
            t = t[section]
        else
            local i1,i2 = line:find('%s*=%s*')
            if i1 then -- key,value assignment
                local key = process_name(line:sub(1,i1-1))
                local value = process_value(line:sub(i2+1))
                t[key] = value
            else -- a plain list of values...
                t[#t+1] = process_value(line)
            end
        end
    end
    return top_t
end

return config
