local testip = "1.1.1.1"
local cip = ngx.var.arg_cip

rip = headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"

if cip == nil then
  --ngx.say("cip nil")
else
  --ngx.say("cip not nil")
  local IPYes = IPType[GetIPType(cip)]
  if IPYes == "IPv4"  then
    --ngx.say("Yes ipv4")
    rip = cip or headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
  elseif IPYes == "IPv6"  then
    --ngx.say("Yes ipv6")
    rip = cip or headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
  else
    ngx.say("illegal ip! use client ip!!")
    ---local rip = headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
  end
end


local geoip = io.popen ('curl -s  https://api.ip.sb/geoip/' .. rip)
local data = geoip:read("*all")

JSON = (loadfile "JSON.lua")()
local json =  JSON:decode(data)

ngx.say(json["ip"])
ngx.say(json["country_code"], " / ", json["country"])
ngx.say("AS",json["asn"], " / ", json["asn_organization"])
ngx.say(headers["user-agent"])
--ngx.say("</pre>")

return ngx.exit(200)

