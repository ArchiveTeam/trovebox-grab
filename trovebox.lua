dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local downloaded = {}
local addedtolist = {}

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  
  if downloaded[url] == true or addedtolist[url] == true then
    return false
  end
  
  if item_type == "site" and (downloaded[url] ~= true and addedtolist[url] ~= true) then
    if string.match(url, item_value) then
      return verdict
    elseif html == 0 then
      return verdict
    else
      return false
    end
  end
  
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  
  local function check(url)
    if (downloaded[url] ~= true and addedtolist[url] ~= true) then
      table.insert(urls, { url=url })
      addedtolist[url] = true
    end
  end

  if item_type == "site" then
    if string.match(url, "%?") then
      local newurl = string.match(url, "(https://[^%?]+)%?")
      check(newurl)
    end
    if string.match(url, "https?://[^%.]+%.trovebox%.com") and not string.match(url, "%.jpg") then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "\/") then
          local newnewurl = string.gsub(newurl, "\/", "/")
          check(newnewurl)
        elseif string.match(newurl, item_value) or string.match(newurl, "%.jpg") or string.match(newurl, "%.png") or string.match(url, "%.cloudfront%.com") then
          check(newurl)
        end
      end
      for newurl2 in string.gmatch(html, '"(%?[^"]+)"') do
        if string.match(url, "%?") then
          local newurl1 = string.match(url, "(https?://[^%?]+)%?")
        elseif not string.match(url, "%?") then
          local newurl1 = url
        local newurl = newurl1..newurl2
        check(newurl)
      end
      for newurl2 in string.gmatch(html, '"(/[^"]+)"') do
        if not string.match(newurl2, "%%") and not string.match(newurl2, "%%25") then
          local newurl1 = string.match(url, "(https?://[^/]+)/")
          local newurl = newurl1..newurl2
          check(newurl)
        end
      end
      if string.match(url, "%.trovebox%.com/p/[0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z]") then
        local photoid = string.match(url, "%.trovebox%.com/p/([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])")
        for newphotoid in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])"') do
          local newurl = "https://"..item_value..".trovebox.com/p/"..newphotoid
          check(newurl)
        end
      end
      if string.match(url, "%.trovebox%.com/albums/") then
        for newalbum in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z])"') do
          local newurl = "https://"..item_value..".trovebox.com/photos/album-"..newalbum.."/list"
          check(newurl)
        end
      end
      if string.match(url, "%.trovebox%.com/photos/album%-[0-9a-zA-Z][0-9a-zA-Z]/list") then
        local albumid = string.match(url, "%.trovebox%.com/photos/album%-([0-9a-zA-Z][0-9a-zA-Z])")
        for photoid in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])"') do
          local newurl = "https://"..item_value..".trovebox.com/p/"..photoid.."/album-"..albumid
          local newurl0 = "https://"..item_value..".trovebox.com/p/"..photoid
          local newurl1 = "https://"..item_value..".trovebox.com/p/"..photoid.."/album-"..albumid.."?sortBy=dateTaken,asc"
          local newurl2 = "https://"..item_value..".trovebox.com/p/"..photoid.."/album-"..albumid.."?sortBy=dateTaken,desc"
          local newurl3 = "https://"..item_value..".trovebox.com/p/"..photoid.."/album-"..albumid.."?sortBy=dateUploaded,asc"
          local newurl4 = "https://"..item_value..".trovebox.com/p/"..photoid.."/album-"..albumid.."?sortBy=dateUploaded,desc"
          check(newurl)
          check(newurl0)
          check(newurl1)
          check(newurl2)
          check(newurl3)
          check(newurl4)
        end
      end
    end
  end
  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  last_http_statcode = status_code
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()
  
  if (status_code >= 200 and status_code <= 399) then
    if string.match(url["url"], "https://") then
      local newurl = string.gsub(url["url"], "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url["url"]] = true
    end
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 5")

    tries = tries + 1

    if tries >= 20 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 10 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(500, 5000) / 100.0)
  local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
