# Cute-cat
Have you ever wanted cats in your Neovim config ?

If your answer was, "omg yes!" then you're at the right place. If not, try it, might be fun, he might even help you a bit.

## Commands
Status cat is automatically launched when neovim is launched.

Otherwise do :Cat and look for completion!

`:CatStatusOff`
`:CatStatusOn`
`:CatWalk` or `:CatWalk N`
`:CatTeleport` or `CatTeleport N`
`:CatDismiss` : dismisses all walking and teleporting cats, don't do this, cats are cute.

## Status cat
- Cool cat when you're just in normal mode.
- Moving cat when you are in insert mode.
- Visual cat when you are in visual mode.
- Angry cat when you have errors in your file (according to your LSP).

## Walking cat
Try `:CatWalk N` (if no N is submitted it will put only 1 more cat on your screen), and look at all these cool cats on your screen! They'll help you code for sure (no guarantee)
`:CatDismiss` to get rid of all the cats in your Neovim.

## Teleporting cat
I prefer walking cats, but too each their own! You also have teleporting cats!

`:CatTeleport N`

## Install
Using lazy:
```
  {"Panda-d3v/cute-cat.nvim",
    config = function()
        require("cute-cat")
    end
  },
```


## Required (version/dependencies)
Neovim 0.8+ : needs floating windows (nvim_open_win), timers (vim.fn.timer_start), and Lua API (vim.api).
If you’re on 0.9+, you also get zindex support for layering cats.
#### Recommended :
An LSP client configured so you can see the angry bad_cat when errors are present.


## Disclaimer
This is a purely fun project, performance issues were no concern when creating this. Any security/memory/performance issue are welcome to be reported, but there is no garanty they will be adressed.

Thank you for understanding.

## One more thing
Have fun with your little Neovim companion !
