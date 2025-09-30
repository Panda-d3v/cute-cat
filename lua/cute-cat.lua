-- cats.lua — cozy cats for Neovim
-- partner's herd: status cat, wander cat, walk cat

local api, fn = vim.api, vim.fn

-- =====================================================
-- Art
-- =====================================================
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

local normal3_face = {
  [[ /\_/   ]],
  [[( o.o ) ]],
  [[ > ˇ >  ]],
}

local normal4_face = {
  [[ /\_/   ]],
  [[( o.o ) ]],
  [[ < ˇ >  ]],
}

local relax_face = {
  [[|\__/,|   (`\ ]],
  [[|• . •|   ) ) ]],
  [[(  ‹  )o ("(  ]],
}


local relax2_face = {
  [[|\__/,|   /`) ]],
  [[|• . •|   ( ( ]],
  [[(  ›  )o ("(  ]],
}


local relax3_face = {
  [[|\__/,|   /`) ]],
  [[| . |   ( ( ]],
  [[(  -  )o ("(  ]],
}

local teleport_face = {
  [[ /\_/\  ]],
  [[( @.@ ) ]],
  [[ > ~ <  ]],
}


local visual_face = {
  [[ /\_/\  ]],
  [[( o.o ) ]],
  [[ > ° <  ]],
}

local visual2_face = {
  [[ /\_/\  ]],
  [[( o.o ) ]],
  [[>> o << ]],
}

local bad_face = {
  [[ /\_/\  ]],
  [[( -.- ) ]],
  [[ > ^ <  ]],
}

local bad2_face = {
  [[ /\_/\  ]],
  [[( >.< ) ]],
  [[ > - <  ]],
}

local bad3_face = {
  [[ /\_/\  ]],
  [[( ¬.¬ ) ]],
  [[ > - <  ]],
}

local bad4_face = {
  [[ /\_/\  ]],
  [[( x.x ) ]],
  [[ > o <  ]],
}

local bad5_face = {
  [[ /\_/\  ]],
  [[( π.π ) ]],
  [[ > - <  ]],
}

local funny_face = {
  [[ /\_/\  ]],
  [[( >.< ) ]],
  [[ > u <  ]],
}


local frames_normal_cat = { normal_face, normal2_face, normal3_face, normal4_face}
local frames_relax_cat = {relax_face, relax2_face}
local frames_visual_cat = {visual_face, visual2_face}
local frames_bad_cat = {bad_face, bad2_face, bad3_face, bad4_face, bad5_face}

-- =====================================================
-- Utils
-- =====================================================
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

-- =====================================================
-- Status Cat (edge of screen, reacts to mode + diagnostics)
-- =====================================================
local status = {
  buf = nil,
  win = nil,
  timer = nil,
  active = true, -- toggle with :CatStatusOn / :CatStatusOff
}

-- places the top right corner cat
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

local function status_insert_anim(frames)
  if not status.active then return end
  local i = 1
  if status.timer then fn.timer_stop(status.timer) end
  status_show(frames[i])
  i = i % #frames + 1
  status.timer = fn.timer_start(600, function()
    vim.schedule(function()
      if not status.active then return end
      if math.random() < 0.001 then status_show(funny_face) -- Congrats! You found an easter egg
      else
        status_show(frames[i])
      end
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
    status_insert_anim(frames_normal_cat)
  end,
})

api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    if not status.active then return end
    if has_errors() then status_insert_anim(frames_bad_cat) else status_insert_anim(frames_relax_cat) end
  end,
})

-- Entered any Visual mode: v, V, or Ctrl-V (\x16)
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:[vV\x16]",
  callback = function()
    if not status.active then return end
    if has_errors() then
      status_insert_anim(frames_bad_cat)
    else
      status_insert_anim(frames_visual_cat)
    end
  end,
})

-- Left Visual mode (to anything else)
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "[vV\x16]:*",
  callback = function()
    if not status.active then return end
    if has_errors() then
      status_insert_anim(frames_bad_cat)
    else
      local m = vim.fn.mode()
      if m:match("i") then
        status_insert_anim(frames_normal_cat)   -- if you landed in insert, keep the wiggle
      else
        status_insert_anim(frames_relax_cat)  -- otherwise chill in normal
      end
    end
  end,
})

-- insert ; errors ; visual ; else relax
api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    if not status.active then return end
    local m = fn.mode()
    if m:match("i") then
      status_insert_anim(frames_normal_cat)
    elseif has_errors() then
      status_insert_anim(frames_bad_cat)
    elseif m:match("[vV\22]") then
      status_set(visual_face)
    else
      status_insert_anim(frames_relax_cat)
    end
  end,
})

-- start relaxed by default
-- where the program starts
vim.schedule(function() status_insert_anim(frames_relax_cat) end)

api.nvim_create_user_command("CatStatusOff", function()
  status.active = false
  close_state(status)
end, {})

api.nvim_create_user_command("CatStatusOn", function()
  status.active = true
  status_insert_anim(frames_relax_cat)
end, {})

-- ========================================================================
-- Teleport Cat (teleports every 2s)
-- ========================================================================

local all_teleportCats = {}

local function start_teleportCat()

  local teleportCat = { buf = nil, win = nil, timer = nil, shown = false }

  if teleportCat.timer then
    print("Wander cat already active 🐈")
    return
  end
  -- create once at random place, then move window
  local max_row = math.max(0, vim.o.lines - 3)
  local max_col = math.max(0, vim.o.columns - 7)
  local row = math.random(0, max_row)
  local col = math.random(0, max_col)
  ensure_buf_win(teleportCat, normal_face, { row = row, col = col })

  local function loop()
    if not (teleportCat.win and api.nvim_win_is_valid(teleportCat.win)) then return end
      max_row = math.max(0, vim.o.lines - 3)
      max_col = math.max(0, vim.o.columns - 7)
      row = math.random(0, max_row)
      col = math.random(0, max_col)
      api.nvim_win_set_config(teleportCat.win, {
        relative = "editor",
        row = row,
        col = col,
        width = 7,
        height = 3,
      })
      set_lines(teleportCat, teleport_face)
      local delay = math.random(1000, 1600)
      teleportCat.timer = vim.fn.timer_start(delay, function() vim.schedule(loop) end)
  end
  loop()
  table.insert(all_teleportCats, teleportCat)
end



local function wander_stop()
  for _, w in ipairs(all_teleportCats) do
    close_state(w)
  end
  all_teleportCats = {}

end


local function spawn_teleportCats(n)
  n = tonumber(n) or 1
  for _ = 1, n do
    start_teleportCat()
  end
end


-- ========================================================================
-- Walk Cat (natural: slows, speeds, pauses)
-- ========================================================================

local all_walkers = {}

local function start_walker()
  local max_r = math.max(0,vim.o.lines - 3)
  local max_c = math.max(0,vim.o.columns - 7)

  local walk = {
    row = math.random(0,max_r),
    col = math.random(0,max_c),
    vx = (math.random() < 0.5) and 1 or -1,
    vy = 0,
    frame = 1,
  }
  local frames = frames_normal_cat

  ensure_buf_win(walk, frames[walk.frame], {row = walk.row, col = walk.col})

  local function loop()
    if not (walk.win and api.nvim_win_is_valid(walk.win)) then return end
    local delay = 0
    -- random pause
    if math.random() < 0.15 then
      -- still animate while paused
      walk.frame = walk.frame % #frames + 1
      set_lines(walk, frames[walk.frame])
      delay = math.random(400, 1000)
    else

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
      walk.frame = walk.frame % #frames + 1
      set_lines(walk, frames[walk.frame])

      -- Reschedule with random interval
      delay = math.random(150, 600)

    end
    walk.timer = vim.fn.timer_start(delay, function() vim.schedule(loop) end)
  end

  loop()
  table.insert(all_walkers, walk)
end


local function spawn_walkers(n)
  n = tonumber(n) or 1
  for _ = 1, n do
    start_walker()
  end
end

-- ========================================================================
-- ========================================================================
-- Commands
-- ========================================================================
-- ========================================================================

api.nvim_create_user_command("CatTeleport", function(opts) spawn_teleportCats(opts.args) end, { nargs = "?"})

-- Make plenty of cats able to walk
api.nvim_create_user_command("CatWalk", function(opts) spawn_walkers(opts.args) end, { nargs= "?"})

-- Dismisses all cat
api.nvim_create_user_command("CatDismiss", function()
  for _, w in ipairs(all_walkers) do
    close_state(w)
  end
  all_walkers = {}
  wander_stop()
  print("All your cats went to sleep 😴")
end, {})

