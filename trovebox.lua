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
    if string.match(url, "%%") or string.match(url, "%%25") or string.match(url, "//") or string.match(url, "%%3E") or string.match(url, ">") or string.match(url, "login%?r=/user/login%?r=") then
      return false
    elseif string.match(url, item_value) then
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
  
  local function check(newurl)
    if (downloaded[newurl] ~= true and addedtolist[newurl] ~= true) then
      if not (string.match(newurl, "%%") and string.match(newurl, "%%25") and string.match(newurl, "//") and string.match(newurl, "%%3E") and string.match(newurl, ">") and string.match(newurl, "login%?r=/user/login%?r=")) then
        table.insert(urls, { url=newurl })
        addedtolist[newurl] = true
      end
    end
  end

  if item_type == "site" then
    if string.match(url, "%?") then
      local newurl = string.match(url, "(https://[^%?]+)%?")
      check(newurl)
    end
    if string.match(url, "https?://[^%.]+%.trovebox%.com") and not string.match(url, "%.jpg") then
      html = read_file(file)
      if string.match(url, "/page%-") then
        local page = string.match(url, "/page%-([0-9]+)")
        if not (string.match(html, "<h4>This user hasn't uploaded any photos, yet%.</h4>") and string.match(url, "/p/")) then
          local newurl1 = string.match(url, "(https?://[^/]+/[^/]+/page%-)[0-9]+")
          local newurl2 = string.match(url, "https?://[^/]+/[^/]+/page%-[0-9]+(.+)")
          local newpage = page + 1
          local newurl = newurl1..newpage..newurl2
          check(newurl)
        end
      end
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, item_value) or string.match(newurl, "%.jpg") or string.match(newurl, "%.png") or string.match(url, "%.cloudfront%.com") then
          check(newurl)
        end
      end
      for newurl in string.gmatch(html, '"https?:....d1odebs29o9vbg%.[^%.]+.[a-z]+..[0-9a-zA-Z_%-]+..[0-9a-zA-Z_%-]+..[^%.]+%.[^"]+"') do
        local part1 = string.match(html, '"(https?:)....d1odebs29o9vbg%.[^%.]+%.[a-z]+..[0-9a-zA-Z_%-]+..[0-9a-zA-Z_%-]+..[^%.]+%.[^"]+"')
        local part2 = string.match(html, '"https?:....(d1odebs29o9vbg%.[^%.]+%.[a-z]+)..[0-9a-zA-Z_%-]+..[0-9a-zA-Z_%-]+..[^%.]+%.[^"]+"')
        local part3 = string.match(html, '"https?:....d1odebs29o9vbg%.[^%.]+%.[a-z]+..([0-9a-zA-Z_%-]+)..[0-9a-zA-Z_%-]+..[^%.]+%.[^"]+"')
        local part4 = string.match(html, '"https?:....d1odebs29o9vbg%.[^%.]+%.[a-z]+..[0-9a-zA-Z_%-]+..([0-9a-zA-Z_%-]+)..[^%.]+%.[^"]+"')
        local part5 = string.match(html, '"https?:....d1odebs29o9vbg%.[^%.]+%.[a-z]+..[0-9a-zA-Z_%-]+..[0-9a-zA-Z_%-]+..([^%.]+%.[^"]+)"')
        local newurl2 = part1.."//"..part2.."/"..part3.."/"..part4.."/"..part5
        io.stdout:write("1 "..newurl2.."\n")
        io.stdout:flush()
        check(newurl2)
      end
      for newurl2 in string.gmatch(html, '"(%?[^"]+)"') do
        if string.match(url, "https?://[^%?]+%?") then
          local newurl1 = string.match(url, "(https?://[^%?]+)%?")
          local newurl = newurl1..newurl2
          check(newurl)
        elseif not string.match(url, "https?://[^%?]+%?") then
          local newurl1 = url
          local newurl = newurl1..newurl2
          check(newurl)
        end
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
        local newurl = "https://"..item_value..".trovebox.com/photo/"..photoid.."/download"
        local newurl3 = "https://"..item_value..".trovebox.com/p/"..photoid
        check(newurl)
        check(newurl3)
        for newphotoid in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])"') do
          local newurl1 = "https://"..item_value..".trovebox.com/p/"..newphotoid
          local newurl2 = "https://"..item_value..".trovebox.com/photo/"..newphotoid.."/download"
          check(newurl1)
          check(newurl2)
        end
      end
      if string.match(url, "%.trovebox%.com/albums/") then
        for newalbum in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z])"') do
          local newurl = "https://"..item_value..".trovebox.com/photos/album-"..newalbum.."/list"
          local newurl1 = "https://"..item_value..".trovebox.com/photos/page-0/album-"..newalbum.."/list"
          local newurl2 = "https://"..item_value..".trovebox.com/photos/album-"..newalbum.."/list?sortBy=dateUploaded,asc"
          local newurl3 = "https://"..item_value..".trovebox.com/photos/album-"..newalbum.."/list?sortBy=dateUploaded,asc"
          local newurl4 = "https://"..item_value..".trovebox.com/photos/album-"..newalbum.."/list?sortBy=dateTaken,asc"
          local newurl5 = "https://"..item_value..".trovebox.com/photos/album-"..newalbum.."/list?sortBy=dateTaken,desc"
          local newurl6 = "https://"..item_value..".trovebox.com/photos/page-0/album-"..newalbum.."/list?sortBy=dateUploaded,asc"
          local newurl7 = "https://"..item_value..".trovebox.com/photos/page-0/album-"..newalbum.."/list?sortBy=dateUploaded,asc"
          local newurl8 = "https://"..item_value..".trovebox.com/photos/page-0/album-"..newalbum.."/list?sortBy=dateTaken,asc"
          local newurl9 = "https://"..item_value..".trovebox.com/photos/page-0/album-"..newalbum.."/list?sortBy=dateTaken,desc"
          check(newurl)
          check(newurl1)
          check(newurl2)
          check(newurl3)
          check(newurl4)
          check(newurl5)
          check(newurl6)
          check(newurl7)
          check(newurl8)
          check(newurl9)
        end
      end
      if string.match(url, "%.trovebox%.com/photos/tags%-.+") then
        local part2 = string.match(url, "%.trovebox%.com/photos/tags%-(.+)")
        local newurl10 = "https://"..item_value..".trovebox.com/photos/page-0/tags-"..part2
        io.stdout:write("2 "..newurl10.."\n")
        io.stdout:flush()
        check(newurl10)
        local tag = string.match(url, "tags%-([^/]+)")
        if string.match(url, "/page%-") then
          local tags1 = string.match(url, "%.trovebox%.com/photos/(page%-[0-9]+/tags.+)")
          local tags = string.gsub(albumid1, "/list", "")
          for photoid in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])"') do
            local newurl = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags
            local newurl0 = "https://"..item_value..".trovebox.com/p/"..photoid
            local newurl1 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateTaken,asc"
            local newurl2 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateTaken,desc"
            local newurl3 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateUploaded,asc"
            local newurl4 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateUploaded,desc"
            local newurl5 = "https://"..item_value..".trovebox.com/photo/"..photoid.."/download"
            io.stdout:write("3 "..newurl.."\n")
            io.stdout:flush()
            check(newurl)
            check(newurl0)
            check(newurl1)
            check(newurl2)
            check(newurl3)
            check(newurl4)
            check(newurl5)
          end
        elseif not string.match(url, "/page%-") then
          local tags1 = string.match(url, "%.trovebox%.com/photos/(tags.+)")
          local tags = string.gsub(albumid1, "/list", "")
          for photoid in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])"') do
            local newurl = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags
            local newurl0 = "https://"..item_value..".trovebox.com/p/"..photoid
            local newurl1 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateTaken,asc"
            local newurl2 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateTaken,desc"
            local newurl3 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateUploaded,asc"
            local newurl4 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..tags.."?sortBy=dateUploaded,desc"
            local newurl5 = "https://"..item_value..".trovebox.com/photo/"..photoid.."/download"
            io.stdout:write("4 "..newurl.."\n")
            io.stdout:flush()
            check(newurl)
            check(newurl0)
            check(newurl1)
            check(newurl2)
            check(newurl3)
            check(newurl4)
            check(newurl5)
          end
        end
      end
      if string.match(url, "%.trovebox%.com/photos/album%-[0-9a-zA-Z][0-9a-zA-Z]/list") or string.match(url, "%.trovebox%.com/photos/page%-[0-9]+/album%-[0-9a-zA-Z][0-9a-zA-Z]/list") then
        if string.match(url, "/page%-") then
          local albumid1 = string.match(url, "%.trovebox%.com/photos/(page%-[0-9]+/album%-[0-9a-zA-Z][0-9a-zA-Z])")
          local albumid = string.gsub(albumid1, "/list", "")
          for photoid in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])"') do
            local newurl = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid
            local newurl0 = "https://"..item_value..".trovebox.com/p/"..photoid
            local newurl1 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateTaken,asc"
            local newurl2 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateTaken,desc"
            local newurl3 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateUploaded,asc"
            local newurl4 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateUploaded,desc"
            local newurl5 = "https://"..item_value..".trovebox.com/photo/"..photoid.."/download"
            check(newurl)
            check(newurl0)
            check(newurl1)
            check(newurl2)
            check(newurl3)
            check(newurl4)
            check(newurl5)
          end
        elseif not string.match(url, "/page%-") then
          local albumid1 = string.match(url, "%.trovebox%.com/photos/(album%-[0-9a-zA-Z][0-9a-zA-Z])")
          local albumid = string.gsub(albumid1, "/list", "")
          for photoid in string.gmatch(html, '"id":"([0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z])"') do
            local newurl = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid
            local newurl0 = "https://"..item_value..".trovebox.com/p/"..photoid
            local newurl1 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateTaken,asc"
            local newurl2 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateTaken,desc"
            local newurl3 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateUploaded,asc"
            local newurl4 = "https://"..item_value..".trovebox.com/p/"..photoid.."/"..albumid.."?sortBy=dateUploaded,desc"
            local newurl5 = "https://"..item_value..".trovebox.com/photo/"..photoid.."/download"
            check(newurl)
            check(newurl0)
            check(newurl1)
            check(newurl2)
            check(newurl3)
            check(newurl4)
            check(newurl5)
          end
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
  
  if status_code == 500 then
    io.stdout:write("Server returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 5")

    tries = tries + 1

    if tries >= 3 then
      io.stdout:write("Skip this url...\n")
      io.stdout:flush()
      return wget.actions.EXIT
    else
      return wget.actions.CONTINUE
    end
  elseif (status_code >= 400 and status_code ~= 404) then
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
