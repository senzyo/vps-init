" 用于 neovim, 可追加到 /etc/xdg/nvim/sysinit.vim

set number                " 显示行号
set clipboard=unnamedplus " 默认使用系统剪贴板

" 启用 OSC 52 协议
lua << EOF
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}
EOF