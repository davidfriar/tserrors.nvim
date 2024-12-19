# TSErrors

Displays nicely formatted Typescript errors in a popup window.

## Introduction

This plugin is work in progress. Don't use it yet!

## Requirements

You will need to have the following installed:

- hexh250786313/pretty-ts-errors-markdown npm package
- MeanderingProgrammer/render-markdown.nvim plugin

## Features

## Installation

1. Install pretty-ts-errors-markdown globally:

```sh
npm install -g pretty-ts-errors-markdown
```

2. Install this plugin

Be sure that render-markdown.nvim is also loaded before the setup function of this plugin is called.
For example, if you are using Lazy.nvim as your plugin manager, do this:

```lua
{
  "davidfriar/tserrors.nvim",
  dependencies = {
    "MeanderingProgrammer/render-markdown.nvim",
  },
  --- @class (exact) tserrors.UserOptions
  opts = {}
}
```

Note that TSErrors requires that the setup function is called or it will not work (Lazy.nvim does this
automatically if you provide 'opts', which can be empty)

## Configuration

The default configuration is like this:

```lua
---@type  tserrors.Options
M.defaults = {
  file_type = "tserror",
  markdown_overrides = {
    code = {
      style = "normal",
      highlight = "RenderMarkDownErrorsCode",
      left_pad = 1,
      right_pad = 1,
    },
  },
  win_open_opts = {
    focusable = false,
    relative = "cursor",
    style = "minimal",
    row = 1,
    col = 0,
    border = "rounded",
  },
  window_options = {
    wrap = true,
    linebreak = true,
  },
  buffer_options = {
    readonly = true,
    modifiable = false,
  },
  max_width = 160,
  max_height = 50,
  padding = 1,
}
```

## API

## Commands

## Mappings

## Credit
