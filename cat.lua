-- cats.lua — cozy cats for Neovim
-- partner's herd: status cat, wander cat, walk cat

local api, fn = vim.api, vim.fn

-- =========
-- Art
-- =========
local normal_face = {
  [[ /\_/\  ]],
  [[( o.o ) ]],
  [[ > ^ <  ]],
}

local normal2_face = {
  [[ /\_/\  ]],
  [[( o.o ) ]],
  [[ > ^ >  ]],
}

local relax_cat = {
  [[|\__/,|   (`\ ]],
  [[| . |   ) ) ]],
  [[(  -  )o ("(  ]],
}

local visual_face = {
  [[ /\_/\  ]],
  [[( o.o ) ]],
  [[ > ° <  ]],
}

local bad_cat = {
  [[ /\_/\  ]],
  [[( -.- ) ]],
  [[ > ^ <  ]],
}

-- =========
-- Utils
-- =========
local function measure(lines)
  local w = 0
  for _, s in ipairs(lines) do
    w = math.max(w, vim.fn.strdisplaywidth(s))
  end
  return w, #lines
end

local function ensure_buf_win(state, lines, cfg)
  if not (state.buf and api.nvim_buf_is_loaded(state.buf)) then
    state.buf = api.nvim_create_buf(false, true)
  end
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  if not (state.win and api.nvim_win_is_valid(state.win)) then
    local width, height = measure(lines)
    cfg = cfg or {}
    cfg.relative = cfg.relative or "editor"
    cfg.style = "minimal"
    cfg.focusable = false
    cfg.noautocmd = true
    cfg.width = cfg.width or width
    cfg.height = cfg.height or height
    state.win = api.nvim_open_win(state.buf, false, cfg)
  else
    -- resize if needed
    local width, height = measure(lines)
    local conf = api.nvim_win_get_config(state.win)
    conf.width, conf.height = width, height
    api.nvim_win_set_config(state.win, conf)
  end
end

local function set_lines(state, lines)
  if state.buf and api.nvim_buf_is_loaded(state.buf) then
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  end
end

local function close_state(state)
  if state.timer then
    fn.timer_stop(state.timer)
    state.timer = nil
  end
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end
  if state.buf and api.nvim_buf_is_loaded(state.buf) then
    pcall(api.nvim_buf_delete, state.buf, { force = true })
  end
  state.win, state.buf = nil, nil
end

-- =========
-- Status Cat (edge of screen, reacts to mode + diagnostics)
-- =========
local status = {
  buf = nil,
  win = nil,
  timer = nil,
  active = true, -- toggle with :CatStatusOn / :CatStatusOff
}

local function status_show(lines)
  if not status.active then return end
  ensure_buf_win(status, lines, {
    relative = "editor",
    anchor = "NE", --position of cat status
    --row = vim.o.lines - 2,
    -- col = vim.o.columns,
    row = 1,
    col = vim.o.columns - 1,
  })
  set_lines(status, lines)
end

local function status_set(face)
  if not status.active then return end
  if status.timer then fn.timer_stop(status.timer); status.timer = nil end
  status_show(face)
end

local function status_insert_anim()
  if not status.active then return end
  local frames = { normal_face, normal2_face }
  local i = 1
  if status.timer then fn.timer_stop(status.timer) end
  status.timer = fn.timer_start(600, function()
    vim.schedule(function()
      if not status.active then return end
      status_show(frames[i])
      i = i % #frames + 1
    end)
  end, { ['repeat'] = -1 })
end

local function has_errors()
  local diags = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  return #diags > 0
end

-- autocommands -> mode + diagnostics
api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    if not status.active then return end
    -- if has_errors() then status_set(bad_cat) else status_insert_anim() end
    status_insert_anim()
  end,
})

api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    if not status.active then return end
    if has_errors() then status_set(bad_cat) else status_set(relax_cat) end
  end,
})

-- Entered any Visual mode: v, V, or Ctrl-V (\x16)
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:[vV\x16]",
  callback = function()
    if not status.active then return end
    if has_errors() then
      status_set(bad_cat)
    else
      status_set(visual_face)
    end
  end,
})

-- Left Visual mode (to anything else)
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "[vV\x16]:*",
  callback = function()
    if not status.active then return end
    if has_errors() then
      status_set(bad_cat)
    else
      local m = vim.fn.mode()
      if m:match("i") then
        status_insert_anim()   -- if you landed in insert, keep the wiggle
      else
        status_set(relax_cat)  -- otherwise chill in normal
      end
    end
  end,
})

-- insert then errors then visual else relax
api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    if not status.active then return end
    local m = fn.mode()
    if m:match("i") then
      status_insert_anim()
    elseif has_errors() then
      status_set(bad_cat)
    elseif m:match("[vV\22]") then
      status_set(visual_face)
    else
      status_set(relax_cat)
    end
  end,
})

-- start relaxed by default
vim.schedule(function() status_set(relax_cat) end)

api.nvim_create_user_command("CatStatusOff", function()
  status.active = false
  close_state(status)
end, {})

api.nvim_create_user_command("CatStatusOn", function()
  status.active = true
  status_set(relax_cat)
end, {})

-- =========
-- Wander Cat (teleports every 2s)
-- =========
local wander = { buf = nil, win = nil, timer = nil, shown = false }

local function wander_start()
  if wander.timer then
    print("Wander cat already active 🐈")
    return
  end
  -- create once at random place, then move window
  local max_row = math.max(0, vim.o.lines - 3)
  local max_col = math.max(0, vim.o.columns - 7)
  local row = math.random(0, max_row)
  local col = math.random(0, max_col)
  ensure_buf_win(wander, normal_face, { row = row, col = col })

  wander.timer = fn.timer_start(2000, function()
    vim.schedule(function()
      if not (wander.win and api.nvim_win_is_valid(wander.win)) then return end
      local mr = math.max(0, vim.o.lines - 3)
      local mc = math.max(0, vim.o.columns - 7)
      local r = math.random(0, mr)
      local c = math.random(0, mc)
      api.nvim_win_set_config(wander.win, {
        relative = "editor",
        row = r,
        col = c,
        width = 7,
        height = 3,
      })
      -- playful blink on hop
      set_lines(wander, math.random() < 0.5 and normal_face or normal2_face)
    end)
  end, { ['repeat'] = -1 })
end

local function wander_stop()
  close_state(wander)
end


-- =========
-- Walk Cat (natural: slows, speeds, pauses)
-- =========
local walk = {
  buf = nil, win = nil, timer = nil,
  row = 0, col = 0,
  vx = 1, vy = 0,
  frame = 2,
}

local walk_frames = { normal_face, normal2_face }

local function walk_step()
  if not (walk.win and api.nvim_win_is_valid(walk.win)) then return end

  local max_r = math.max(0, vim.o.lines - 3)
  local max_c = math.max(0, vim.o.columns - 7)

  -- random pause
  if math.random() < 0.15 then
    -- still animate while paused
    walk.frame = walk.frame % #walk_frames + 1
    set_lines(walk, walk_frames[walk.frame])
    return math.random(400, 1000) -- pause duration
  end

  -- small chance to drift up/down
  if math.random() < 0.2 then
    walk.vy = walk.vy + (math.random(0,1) == 0 and -1 or 1)
  end

  -- keep vy small
  if walk.vy > 1 then walk.vy = 1 elseif walk.vy < -1 then walk.vy = -1 end

  -- move
  local new_row = math.max(0, math.min(max_r, walk.row + walk.vy))
  local new_col = math.max(0, math.min(max_c, walk.col + walk.vx))

  -- bounce at edges
  if new_col == 0 or new_col == max_c then
    walk.vx = -walk.vx
    new_row = math.random(0, max_r) -- hop to new lane
  end
  if new_row == 0 or new_row == max_r then
    walk.vy = -walk.vy
  end

  walk.row, walk.col = new_row, new_col

  api.nvim_win_set_config(walk.win, {
    relative = "editor",
    row = walk.row,
    col = walk.col,
    width = 7,
    height = 3,
  })

  -- animate cat frame
  walk.frame = walk.frame % #walk_frames + 1
  set_lines(walk, walk_frames[walk.frame])

  -- return next step interval
  return math.random(120, 600) -- ms: varies speed each tick
end

local function walk_loop()
  local delay = walk_step()
  walk.timer = vim.fn.timer_start(delay, function()
    vim.schedule(walk_loop)
  end)
end

local function walk_start()
  if walk.timer then
    print("Walk cat already active 🐈")
    return
  end
  walk.row = math.random(0, math.max(0, vim.o.lines - 3))
  walk.col = 0
  walk.vx, walk.vy = 1, 0
  walk.frame = 1
  ensure_buf_win(walk, walk_frames[walk.frame], { row = walk.row, col = walk.col })
  walk_loop()
end

local function walk_stop()
  close_state(walk)
end

-- =========
-- Commands
-- =========
api.nvim_create_user_command("CatSummon", function() wander_start() end, {})
api.nvim_create_user_command("CatWalk", function() walk_start() end, {})
api.nvim_create_user_command("CatDismiss", function()
  wander_stop()
  walk_stop()
  print("Cat(s) went to sleep 😴")
end, {})

