local history_str = ""
local history_oo = ""
local history_ii = ""
local history_uu = 1
local pydb = ReverseDb("build/pinyin_simp_9key.reverse.bin")
local pymap = {a=2, b=2, c=2, d=3, e=3, f=3, g=4, h=4, i=4, j=5, k=5, l=5, m=6, n=6, o=6, p=7, q=7, r=7, s=7, t=8, u=8, v=8, w=9, x=9, y =9, z=9 }

local function get_pinyin_match_9key(pinyin, input)
  local l = string.len(pinyin)
  if string.len(input) < l then
    l = string.len(input)
  end
  local i = 1
  local b = 0
  while i<=l do
    b = string.byte(input, i)
    if pymap[string.sub(pinyin, i, i)] ~= b - 48 and  string.byte(pinyin, i) ~=  b then
      --i = i-1
      break
    end
    i=i+1
  end
  return string.sub(pinyin, 1, i-1)
end

-- 获取用户目录
local function getCurrentDir()
  function sum(a, b)
    return a + b
  end
  local info = debug.getinfo(sum)
  local path = info.source
  path = string.sub(path, 2, -1) -- 去掉开头的"@"
  path = string.match(path, "^(.*[\\/])") -- 捕获目录路径
  local spacer = string.match(path,"[\\/]")
  path=string.gsub(path,'[\\/]',spacer)  .. ".." .. spacer 
  return path
end

-- 打印日志到用户目录
local function save_log(str)
  local lpath = getCurrentDir() .. "lua_log.txt"
  local file = io.open(lpath,"a")
  file:write(tostring(os.clock()) .. " " .. str)
  file:close()
end


-- 输出日期、ooii、词尾输入--保存词条到英文用户词库
local function get_date(input, seg, env)
  if (init_tran) then
--    tran_init(env)
  end
  if ( input == "guid" or input == "uuid") then
    yield(Candidate("UUID", seg.start, seg._end, guid(), " -V4"))
  elseif ( input == "date") then
    yield(Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d"), " -"))
  elseif ( input == "time"  or  input == "date---") then
    yield(Candidate("time", seg.start, seg._end, os.date("%H:%M"), " -"))
    yield(Candidate("time", seg.start, seg._end, os.date("%H:%M:%S"), " -"))
    yield(Candidate("time", seg.start, seg._end, os.date("%H%M%S"), " -"))
  elseif input == "oo" and string.len(history_oo)>0 then
    yield(Candidate("oo", seg.start, seg._end, history_oo, "get oo"))
  elseif input == "ii" and string.len(history_ii)>0 then
    yield(Candidate("oo", seg.start, seg._end, history_ii, "get ii"))
  elseif ( string.sub(input,-1)  == "-") then
    if ( input == "date-"  or  input == "time--") then
      yield(Candidate("date", seg.start, seg._end, os.date("%m/%d"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y/%m/%d"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y.%m.%d"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y%m%d"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%B %d"), ""))
      yield(Candidate("date", seg.start, seg._end,  string.gsub(os.date("%Y年%m月%d日"),"([年月])0","%1"), ""))
    elseif ( input == "time-" or  input == "date--") then
      yield(Candidate("date", seg.start, seg._end, os.date("%m/%d %H:%M"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y/%m/%d %H:%M"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d %H:%M"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y.%m.%d %H:%M"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%Y%m%d%H%M%S"), ""))
      yield(Candidate("date", seg.start, seg._end, os.date("%B %d %H:%M"), ""))
      yield(Candidate("date", seg.start, seg._end,  string.gsub(os.date("%Y年%m月%d日 %H:%M"),"([年月])0","%1"), ""))
      yield(Candidate("date", seg.start, seg._end, os.time() , "-秒"))
    else
      local inpu = string.gsub(input,"[-]+$","")
      if (string.len(inpu) > 1 and string.sub(input,1,1) ~= "-") then
        if ( string.sub(input,-2)  == "--") then
--          file = io.open("C:\\Users\\Yazii\\AppData\\Roaming\\Rime\\pinyin_simp_pin.txt", "a")
--          user_path = (rime_api ~= nil and rime_api.get_user_data_dir ~= nil and {rime_api:get_user_data_dir()} or {'%appdata%\\Rime'})[1]
          ppath = getCurrentDir() .. "melt_eng_custom.dict.yaml"
--          yield(Candidate("pin", seg.start, seg._end, ppath , ""))
          local file = io.open(ppath,"a")
          file:write("\n" .. inpu .. "\t" .. inpu .. "\t100")
          file:close()
          yield(Candidate("pin", seg.start, seg._end, inpu , " 已保存"))
        else
          yield(Candidate("pin", seg.start, seg._end, inpu , " -保存"))
        end
	  end
    end
  end
end


-- 假名滤镜。
local function jpcharset_filter(input, env)
  sw =  env.engine.context:get_option("jpcharset_filter")
  if( env.engine.context:get_option("jpcharset_c")) then
    for cand in input:iter() do
      local text = cand.text
      for i in utf8.codes(text) do
         local c = utf8.codepoint(text, i)
         if (c< 0x3041 or c> 0x30FF) then
            yield(cand)
--            yield(Candidate("pin", seg.start, seg._end, text , string.format("%x %c",c,c)))
            break
         end
      end
    end
  elseif( env.engine.context:get_option("jpcharset_j")) then
    for cand in input:iter() do
      local text = cand.text
      for i in utf8.codes(text) do
         local c = utf8.codepoint(text, i)
         if (c>= 0x3041 and c<= 0x30FF) then
            yield(cand)
            break
         end
      end
    end
  else
    for cand in input:iter() do
      yield(cand)
    end
  end
end

-- 输入的内容大写前2个字符，自动转小写词条为全词大写；大写第一个字符，自动转写小写词条为首字母大写
local function autocap_filter(input, env)
  if true then
--  if( env.engine.context:get_option("autocap_filter")) then
    for cand in input:iter() do
      local text = cand.text
      local commit = env.engine.context:get_commit_text()
      if (string.find(text, "^%l%l.*") and string.find(commit, "^%u%u.*")) then
        if(string.len(text) == 2) then
          yield(Candidate("cap", 0, 2, commit , "+" ))
        else
          yield(Candidate("cap", 0, string.len(commit), string.upper(text) , "+" .. string.sub(cand.comment, 2)))
        end
        --[[ 修改候选的注释 `cand.comment`
            因复杂类型候选项的注释不能被直接修改，
            因此使用 `get_genuine()` 得到其对应真实的候选项
            cand:get_genuine().comment = cand.comment .. " " .. s
        --]]
      elseif (string.find(text, "^%l+$") and string.find(commit, "^%u+")) then
        local suffix = string.sub(text,string.len(commit)+1)
        yield(Candidate("cap", 0, string.len(commit), commit .. suffix , "+" .. suffix))
      else
        yield(cand)
      end
    end
  else
    for cand in input:iter() do
      yield(cand)
    end
  end
end

-- 长词优先（从后方移动2个英文候选和3个中文长词，提前为第2-6候选；当后方候选长度全部不超过第一候选词时，不产生作用）
local function long_word_filter(input)
  local l = {}
  -- 记录第一个候选词的长度，提前的候选词至少要比第一个候选词长
  local length = 0
  -- 记录筛选了多少个英语词条(只提升3个词的权重，并且对comment长度过长的候选进行过滤)
  local s1 = 0
  -- 记录筛选了多少个汉语词条(只提升3个词的权重)
  local s2 = 0
  for cand in input:iter() do
    leng = utf8.len(cand.text)
    if(length < 1 ) then
      length = leng
      yield(cand)
    elseif #table > 30 then
      table.insert(l, cand)
    elseif ((leng > length) and (s1 <2)) and(string.find(cand.text, "^[%w%p%s]+$")) then
      s1=s1+1
      if( string.len(cand.text)/ string.len(cand.comment) > 1.5) then 
        yield(cand)
      end
    elseif ((leng > length) and (s2 <3)) and(string.find(cand.text, "^[%w%p%s]+$")==nil) then
      yield(cand)
      s2=s2+1
    else
      table.insert(l, cand)
    end
  end
  for i, cand in ipairs(l) do
    yield(cand)
  end
end


function guid()
    local seed={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    local tb={}
    for i=1,32 do
        table.insert(tb,seed[math.random(1,16)])
    end
    local sid=table.concat(tb)
    return string.format('%s-%s-%s-%s-%s',
        string.sub(sid,1,8),
        string.sub(sid,9,12),
        string.sub(sid,13,16),
        string.sub(sid,17,20),
        string.sub(sid,21,32)
    )
end

local s=0
local start_time=os.clock()
while s<50000 do
    s=s+1
    print(s,guid())
end
print('execute_time='..tostring(os.clock()-start_time))


-- 获取子字符串。根据UTF8编码规则，避免了末位输出乱码
local function get_sub_string(str, length)
  if string.len(str)<length then
    return str
  end

  local ch = string.byte(str, length)
  while( ch<=191 and ch >= 128)
  do
    length = length-1
    ch = string.byte(str, length)
  end
  return string.sub(str,1,length-1)
end

-- 获取子字符串。根据UTF8编码规则，避免了末位输出乱码,length要比实际大1
local function get_sub_string_more(str, length)
  if string.len(str)<length then
    return str
  end

  local ch = string.byte(str, length)
  while( ch <= 192 and ch >= 128)
  do
    length = length+1
    ch = string.byte(str, length)
    if string.len(str)<length then break end
  end
  return string.sub(str,1,length-1)
end


-- Windows 小狼毫输出\r\n会崩溃，故需判断系统为Windows则只输出\r
local next_line = "\n"
if package.config:sub(1,1) == "\\" then
  next_line = "\r"
end

-- 获取开关状态
local function get_option_bool(env, opt)
  return env.engine.schema.config:get_bool(opt)
end

-- 切换开关函数
local function apply_switch(env, keyword, target_state)
  local ctx = env.engine.context
  local swt = env.switcher
  local conf = swt.user_config
  ctx:set_option(keyword, target_state)
  -- 如果设置了自动保存，则需相应的配置
  if swt:is_auto_save(keyword) and conf ~= nil then
    conf:set_bool("var/option/" .. keyword, target_state)
  end
end

-- 包含3个功能：把Oo转换为变量值, <br>转换为换行, 过长的内容切分并缓存,在候选栏仅提供预览（节约屏幕空间的同时避免输入法崩溃）
local oo_buffer= {}

local function pinyin_9et_filter(input,env)
  oo_buffer= {}
  local input_len = string.len(env.engine.context.input)
  local commit = env.engine.context:get_commit_text()
  if string.len(history_oo)>0 then
    for cand in input:iter() do
      local text= string.gsub(cand.text,"<br>",next_line)
      text= string.gsub(text,"&nbsp"," ")
      local comment = cand.comment
      
      if string.find(text, "Oo")~=nil then
        text = string.gsub(text,"Oo",history_oo)
        if string.len(history_ii)>0 then
          text = string.gsub(text,"Xx",history_ii)
        end
        comment =  "=" .. history_oo
      end
      
      if string.len(text)>120 then
        local key = get_sub_string(text,100)
--        local key = string.sub(text,0,100)
        oo_buffer[key] = text
        yield(Candidate(cand.type, 0,input_len, key, "..." ..  comment ))
      elseif text ~= cand.text then
        yield(Candidate(cand.type, 0,input_len, text, comment ))
      else
        yield(cand)
      end
    end
  else
    for cand in input:iter() do
      local text = cand.text
      if string.len(text)>110 then
        text= string.gsub(text,"&nbsp"," ")
        local key = get_sub_string(text,100)
--        local key = string.sub(text,0,100)
        text= string.gsub(text,"<br>",next_line)
        oo_buffer[key] = text
        yield(Candidate(cand.type, 0,input_len, key, "..." .. cand.comment ))
      else
        yield(cand)
      end
    end
  end
end

-- keycode 96 = KP_0
-- keycode 97 = KP_1
-- keycode 98 = KP_2
-- keycode 99 = KP_3
-- keycode 100 = KP_4
-- keycode 101 = KP_5
-- keycode 102 = KP_6
-- keycode 103 = KP_7
-- keycode 104 = KP_8
-- keycode 105 = KP_9 
-- keycode 106 = KP_* KP_Multiply
-- keycode 107 = KP_+ KP_Add
-- keycode 108 = KP_Enter KP_Separator
-- keycode 109 = KP_- KP_Subtract
-- keycode 110 = KP_. KP_Decimal
-- keycode 111 = KP_/ KP_Divide 


local pos_approve = 0
local input_last = ""
local sw_9key_filter = false

-- 包含2个功能，输入 值=oo 设置 history_oo，输入数字完成长候选词取值上屏
local function pinyin_9key_processor(key, env)
  local context = env.engine.context
  local ch = key.keycode
  local engine=env.engine
  local composition = context.composition
  local segment = composition:back()
  local selector = -1
  sw_9key_filter = false
  local reset = true
  if key:ctrl() or key:alt() or key:release() or key:super() then return 2 end
  if  context:has_menu() and ch~= nil then
    save_log( tostring(ch) .. "\tinput=" ..  context.input ..  "\n")
    if ch <=90 and ch >= 65 then
      return 2
    elseif ch == 45 then
      save_log(  "get '-'\tinput=" .. context.input .. "\n")
      if  string.match(context.input , ".+\\-$") then
        sw_9key_filter = true
      end
      
      save_log(  "switch\tstate=" .. tostring(sw_9key_filter) .. "\n")
      --context.input = "test"  ..  context.input
      return 2
    --elseif ch == 118 then
    --  context.input = "test"  ..  context.input
    --  save_log(  "get 'v'\tinput=" .. context.input .. "\n")
    --  return 1
    --elseif ch >= 98 and ch <= 123 then
    --  save_log(  "get 'abc'\tinput=" .. context.input .. "\n")
    --  sw_9key_filter = true
    --  return 2
    elseif key.keycode == 32 and sw_9key_filter then
      -- 空格
      selector = segment.selected_index
    elseif ch <58 and ch>48 and sw_9key_filter  then
      -- 数字
      local page_size = env.engine.schema.config:get_int('menu/page_size')
      selector = segment.selected_index / page_size * page_size + ch - 48
    end
  else
    sw_9key_filter = false
  end
  
  --- local ctx = env.engine.context
  --- local comp = ctx.composition
  --- local selected_index = comp:back().selected_index
  if selector >=0 then
    local preedit =  env.engine.context:get_preedit()
    local select_text = segment:get_candidate_at(selector).text 
    context.input = string.sub(context.input, 1,  preedit.sel_start +1) .. select_text ..   string.sub(context.input,  preedit.sel_start +1 + string.len(select_text), string.len(context.input)-1)
    sw_9key_filter = false
    return 1
  end
  
  
  return 2
end

local function reverse_lookup_filter(input, keys)
  -- 反查
  local arr = {}
  for cand in input:iter() do
    local str = pydb:lookup(get_sub_string_more(cand.text, 2))
    for w in string.gmatch(str, "%S+") do
      local c = arr[w]
      if c ~= nil then
        arr[w] = c+1
      else
        arr[w] = 1
      end
    end
  end
  
  -- 候选字的编码和输入的编码进行匹配
  local arr2 = {}  
  for i, v in pairs(arr) do
    local m = get_pinyin_match_9key(i, keys)
    --save_log("pinyin=\t" .. i  ..  "\tcount=" .. v .. "\tkeys=" .. keys .. "\tm=" .. m .. "\n")
    if string.len(m) < 1 then
      m = "_"
    end
    if arr2[m] ~= nil then
      arr2[m] = arr2[m] + v
    else
      arr2[m] = v
    end
  end
  -- 按照拼音排序
  local key_test ={}
  for i in pairs(arr2) do
     table.insert(key_test,i)   --提取test1中的键值插入到key_test表中
  end
  table.sort(key_test)
  -- 插入候选选项
  for i,v in pairs(key_test) do
    yield(Candidate("9key_py", 0, string.len(v),  v, arr2[v]))
  end
end

--[[
如下，filter 除 `input` 外，可以有第二个参数 `env`。
--]]
local function pinyin_9key_filter(input, env)
  if sw_9key_filter then    
    local preedit =  env.engine.context:get_preedit()
    -- 匹配一段未处理的正常编码
    for w in string.gmatch(string.sub(preedit.text , preedit.sel_start+1, preedit.sel_end +1), "%w+") do
      local commit = env.engine.context:get_commit_text()
      --save_log("commit=\t" .. commit .. "\tpreedit=" .. preedit.text .. "\tw=" .. w .. "\n")
      reverse_lookup_filter(input, w)
      return
    end
  end
  -- 兜底
  for cand in input:iter() do
    yield(cand)
  end
  
end



return {  pinyin_9key__processor=pinyin_9key_processor, pinyin_9key__filter = pinyin_9key_filter}