--- Python-style string library. <p>
-- see 3.6.1 of the Python reference. <p>
-- If you want to make these available as string methods, then say
-- <code>stringx.import()</code> to bring them into the standard <code>string</code>
-- table.
-- @class module
-- @name pl.stringx
local string = string
local find = string.find
local type,setmetatable,getmetatable,ipairs,unpack = type,setmetatable,getmetatable,ipairs,unpack
local error,tostring = error,tostring
local gsub = string.gsub
local rep = string.rep
local sub = string.sub
local concat = table.concat
local utils = require 'pl.utils'
local escape = utils.escape
local ceil = math.ceil
local _G = _G
local assert_arg,usplit,list_MT = utils.assert_arg,utils.split,utils.stdmt.List

local function assert_string (n,s)
    assert_arg(n,s,'string')
end

local function non_empty(s)
    return #s > 0
end

local function assert_nonempty_string(n,s)
    assert_arg(n,s,'string',non_empty,'must be a non-empty string')
end

--[[
module ('pl.stringx',utils._module)
]]

local stringx = {}

--- does s only contain alphabetic characters?.
function stringx.isalpha(s)
    assert_string(1,s)
    return find(s,'^%a+$') == 1
end

--- does s only contain digits?.
function stringx.isdigit(s)
    assert_string(1,s)
    return find(s,'^%d+$') == 1
end

--- does s only contain alphanumeric characters?.
function stringx.isalnum(s)
    assert_string(1,s)
    return find(s,'^%w+$') == 1
end

--- does s only contain spaces?.
function stringx.isspace(s)
    assert_string(1,s)
    return find(s,'^%s+$') == 1
end

--- does s only contain lower case characters?.
function stringx.islower(s)
    assert_string(1,s)
    return find(s,'^%l+$') == 1
end

--- does s only contain upper case characters?.
function stringx.isupper(s)
    assert_string(1,s)
    return find(s,'^%u+$') == 1
end

--- concatenate the strings using this string as a delimiter.
-- @param seq a table of strings or numbers
-- @usage (' '):join {1,2,3} == '1 2 3'
function stringx.join (self,seq)
    assert_string(1,self)
    return concat(seq,self)
end

--- does string start with the substring?.
-- @param s2 a string
function stringx.startswith(self,s2)
    assert_string(1,self)
    assert_string(2,s2)
    return find(self,s2,1,true) == 1
end

local function _find_all(s,sub,first,last)
    if sub == '' then return #s+1,#s end
    local i1,i2 = find(s,sub,first,true)
    local res
    local k = 0
    while i1 do
        res = i1
        k = k + 1
        i1,i2 = find(s,sub,i2+1,true)
        if last and i1 > last then break end
    end
    return res,k
end

--- does string end with the given substring?.
-- @param send a substring or a table of suffixes
function stringx.endswith(s,send)
    assert_string(1,s)
    if type(s) == 'string' then
        return #s >= #send and s:find(send, #s-#send+1, true) and true or false
    elseif type(send) == 'table' then
        for _,suffix in ipairs(send) do
            if stringx.endswith(s,suffix) then return true end
        end
        return false
    else
        utils.error('argument #2: either a substring or a table of suffixes expected')
    end
end

-- break string into a list of lines
function stringx.splitlines (self,keepends)
    assert_string(1,self)
    return setmetatable(usplit(self,'\n'),list_MT)
end

--- replace all tabs in s with n spaces. If not specified, n defaults to 8.
-- @param n number of spaces to expand each tab
function stringx.expandtabs(self,n)
    assert_string(1,self)
    n = n or 8
    local tab = (' '):rep(n)
    return (gsub(self,'\t',tab))
end

--- find index of first instance of sub in s from the left.
-- @param sub substring
-- @param  i1 start index
function stringx.lfind(self,sub,i1)
    assert_string(1,self)
    assert_string(2,sub)
    local idx = find(self,sub,i1,true)
    if idx then return idx else return nil end
end

--- find index of first instance of sub in s from the right.
-- @param sub substring
-- @param first first index
-- @param last last index
function stringx.rfind(self,sub,first,last)
    assert_string(1,self)
    assert_string(2,sub)
    local idx = _find_all(self,sub,first,last)
    if idx then return idx else return nil end
end

--- replace up to n instances of old by new in the string s.
-- if n is not present, replace all instances.
-- @param s the string
-- @param old the target substring
-- @param new the substitution
-- @param n optional maximum number of substitutions
-- @return result string
-- @return the number of substitutions
function stringx.replace(s,old,new,n)
    assert_string(1,s)
    assert_string(1,old)
    return (gsub(s,escape(old),new:gsub('%%','%%%%'),n))
end

--- split a string into a list of strings using a pattern.
-- @class function
-- @name split
-- @param self the string
-- @param re a Lua string pattern (defaults to whitespace)
-- @usage #(('one two'):split()) == 2
function stringx.split(self,re)
	return setmetatable(usplit(self,re),list_MT)
end

--- split a string using a pattern. Note that at least one value will be returned!
-- @param self the string
-- @param re a Lua string pattern (defaults to whitespace)
-- @return the parts of the string
-- @usage  a,b = line:splitv('=')
function stringx.splitv (self,re)
    assert_string(1,self)
    return utils.splitv(self,re)
end

local function copy(self)
    return self..''
end

-- capitalize the string
function stringx.capitalize(self)
    assert_string(1,self)
    return self:sub(1,1):upper()..self:sub(2)
end

--- count all instances of substring in string.
-- @param sub substring
function stringx.count(self,sub)
    assert_string(1,self)
    local i,k = _find_all(self,sub,1)
    return k
end

local function _just(s,w,ch,left,right)
    local n = #s
    if w > n then
        if not ch then ch = ' ' end
        local f1,f2
        if left and right then
            local ln = ceil((w-n)/2)
            local rn = w - n - ln
            f1 = rep(ch,ln)
            f2 = rep(ch,rn)
        elseif right then
            f1 = rep(ch,w-n)
            f2 = ''
        else
            f2 = rep(ch,w-n)
            f1 = ''
        end
        return f1..s..f2
    else
        return copy(s)
    end
end

--- left-justify s with width w.
-- @param w width of justification
-- @param ch padding character, default ' '
function stringx.ljust(self,w,ch)
    assert_string(1,self)
    assert_arg(2,w,'number')
    return _just(self,w,ch,true,false)
end

--- right-justify s with width w.
-- @param w width of justification
-- @param ch padding character, default ' '
function stringx.rjust(s,w,ch)
    assert_string(1,s)
    assert_arg(2,w,'number')
    return _just(s,w,ch,false,true)
end

--- center-justify s with width w.
-- @param w width of justification
-- @param ch padding character, default ' '
function stringx.center(s,w,ch)
    assert_string(1,s)
    assert_arg(2,w,'number')
    return _just(s,w,ch,true,true)
end

local function _strip(s,left,right,chrs)
    if not chrs then
        chrs = '%s'
    else
        chrs = '['..escape(chrs)..']'
    end
    if left then
        local i1,i2 = find(s,'^'..chrs..'*')
        if i2 >= i1 then
            s = sub(s,i2+1)
        end
    end
    if right then
        local i1,i2 = find(s,chrs..'*$')
        if i2 >= i1 then
            s = sub(s,1,i1-1)
        end
    end
    return s
end

--- trim any whitespace on the left of s.
function stringx.lstrip(self,chrs)
    assert_string(1,self)
    return _strip(self,true,false,chrs)
end

--- trim any whitespace on the right of s.
function stringx.rstrip(s,chrs)
    assert_string(1,s)
    return _strip(s,false,true,chrs)
end

--- trim any whitespace on both left and right of s.
function stringx.strip(self,chrs)
    assert_string(1,self)
    return _strip(self,true,true,chrs)
end

-- The partition functions split a string  using a delimiter into three parts:
-- the part before, the delimiter itself, and the part afterwards
local function _partition(p,delim,fn)
    local i1,i2 = fn(p,delim)
    if not i1 or i1 == -1 then
        return p,'',''
    else
        if not i2 then i2 = i1 end
        return sub(p,1,i1-1),sub(p,i1,i2),sub(p,i2+1)
    end
end

--- partition the string using first occurance of a delimiter
-- @param ch delimiter
-- @return part before ch, ch, part after ch
function stringx.partition(self,ch)
    assert_string(1,self)
    assert_nonempty_string(2,ch)
    return _partition(self,ch,stringx.lfind)
end

--- partition the string p using last occurance of a delimiter
-- @param ch delimiter
-- @return part before ch, ch, part after ch
function stringx.rpartition(self,ch)
    assert_string(1,self)
    assert_nonempty_string(2,ch)
    return _partition(self,ch,stringx.rfind)
end

--- return the 'character' at the index.
-- @param self the string
-- @param idx an index (can be negative)
-- @return a substring of length 1 if successful, empty string otherwise.
function stringx.at(self,idx)
    assert_string(1,self)
    assert_arg(2,idx,'number')
    return sub(self,idx,idx)
end

--- return an interator over all lines in a string
-- @param self the string
-- @return an iterator
function stringx.lines (self)
    assert_string(1,self)
    local s = self
    if not s:find '\n$' then s = s..'\n' end
    return s:gmatch('([^\n]*)\n')
end

local elipsis = '...'
local n_elipsis = #elipsis

--- return a shorted version of a string.
-- @param self the string
-- @param sz the maxinum size allowed
-- @param tail true if we want to show the end of the string (head otherwise)
function stringx.shorten(self,sz,tail)
    if #self > sz then
        if sz < n_elipsis then return elipsis:sub(1,sz) end
        if tail then
            local i = #self - sz + 1 + n_elipsis
            return elipsis .. self:sub(i)
        else
            return self:sub(1,sz-n_elipsis) .. elipsis
        end
    end
    return self
end

function stringx.import(dont_overload)
    utils.import(stringx,string)
end

return stringx
