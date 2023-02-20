local cjson = require "cjson"

local cache = ngx.shared.pic_cache

local category = ngx.var.arg_category
local filename
local cachename
if category == "default" then
    filename = "/opt/txt/defaultURL.txt"
    cachename = "defaultURL.txt"
else
    filename = "/opt/txt/coverURL.txt"
    cachename = "coverURL.txt"
end

local pics = cache:get(cachename)

if pics == nil then
    pics = {}
    local file = io.open(filename, "r")
    if file == nil then
        ngx.exit(ngx.HTTP_NOT_FOUND)
    end

    for line in file:lines() do
        if line ~= "" then
            table.insert(pics, line)
        end
    end
    cache:set(cachename, pics)
end

local pic = pics[math.random(#pics)]

local type = ngx.var.arg_type
if type == "json" then
    ngx.header["Content-Type"] = "application/json"
    ngx.print(cjson.encode({ pic = pic }))
else
    ngx.redirect(pic)
end
