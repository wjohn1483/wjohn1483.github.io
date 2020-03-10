---
title: Vim Plugins
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax: true
mathjax_autoNumber: true
---
這邊記錄一下我目前所使用的Vim plugin以及它們的功能。
<!--more-->

市面上有很多Integrated Development Environment (IDE)來幫助你開發，像是[Xcode](https://developer.apple.com/xcode/)、[Visual Studio](https://visualstudio.microsoft.com/zh-hant/)、[Intellij](https://www.jetbrains.com/idea/)、[Pycharm](https://www.jetbrains.com/pycharm/)、[Sublime](https://www.sublimetext.com/)等等，然而在終端機上的文字編輯器，應該大多都是用vim來開發，而vim本身也有很多神人開發的套件，讓你可以在vim裡面做到像上面IDE一樣的操作，底下介紹一下我目前所使用的一些套件。

目前我所使用的設定檔，原先是來自於[timss/vimconf](https://github.com/timss/vimconf)，看star數也蠻多人推薦[amix/vimrc](https://github.com/amix/vimrc)，你也可以去網路上找你心目中所屬的設定檔。

## Vundle

[Vundle](https://github.com/VundleVim/Vundle.vim)是一個vim套件的管理工具，使你可以直接打上vim plugin repo的名字就能安裝至你的vim上，像是

```bash
Plug 'gmarik/Vundle.vim'
```

在宣告好想要安裝的套件以後，打開vim，再打上`:PlugInstall`就會將宣告的套件安裝在**[user name]/.vim/bundle**裡面。如果想要移除某個套件，只需要在設定檔將套件的宣告移除，並在vim裡面打上`:PlugClean`，相當的方便。

## Plugins

接下來介紹一下我覺得好像不錯用的套件們，大多的套件只需要像底下這樣宣告，並且`:PlugInstall`就能安裝完成了。

```bash
Plug '[plugin name]'
```



### [ervandew/supertab](https://github.com/ervandew/supertab)

一個可以讓你用tab自動完成各種東西的套件，可以用tab完成function、variable等等。

### [ycm-core/YouCompleteMe](https://github.com/ycm-core/YouCompleteMe)

也是一個自動完成各種東西的套件，只是安裝起來沒有像supertab那樣簡單，不僅需要宣告在設定檔裡，還需要安裝其他程式語言，像是go、nodejs等，詳細的安裝流程可以參考官方的GitHub。

### [itchyny/lightline.vim](https://github.com/itchyny/lightline.vim)

讓vim可以有status bar，讓你知道現在是處理什麼樣的檔案、在Normal mode、Visual mode還是Insert mode等。

### [bling/vim-bufferline](https://github.com/bling/vim-bufferline)

在status bar裡面顯示目前開啟的所有檔案。

### [mbbill/undotree](https://github.com/mbbill/undotree)

undotree會紀錄你對這個檔案的操作，使你可以隨時退回先前的版本，有點像簡易版的git。

### [nanotech/jellybeans.vim](https://github.com/nanotech/jellybeans.vim)

vim的color schema。

### [tomtom/tcomment_vim](https://github.com/tomtom/tcomment_vim)

幫助你快速將程式碼comment起來的套件，在Visual mode選定好區塊以後，打上`:gc`便能將選取的區塊都comment起來，更多的使用方法可以參考上方連結裡面的文件。

### [somini/vim-autoclose](https://github.com/Townk/vim-autoclose)

自動幫你將括號或是其他該成雙成對的東西補齊的套件。

### [tpope/vim-eunuch](https://github.com/tpope/vim-eunuch)

讓你能在vim裡面直接使用Unix指令的套件，像是`:SudoEdit`、`:Rename`等等，詳細的指令可以參考上方連結。

### [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)

讓你能在vim裡面直接操作git指令的套件。

### [tpope/vim-surround](https://github.com/tpope/vim-surround)

使你可以快速改變括號的套件，像是將

```
"Hello world!"
```

迅速改成

```
'Hello world!'
```

更多的指令請參考上面連結。

### [junegunn/vim-easy-align](https://github.com/junegunn/vim-easy-align)

能迅速將`=`對齊的套件。

### [honza/vim-snippets](https://github.com/honza/vim-snippets) / [sirver/ultisnips](https://github.com/SirVer/ultisnips)

能快速補齊程式碼的套件，像是打上`def test[tab]`就會自動幫你將function的架構打出來。

### [mhinz/vim-startify](https://github.com/mhinz/vim-startify)

一個好看的vim開始畫面。

### [mhinz/vim-signify](https://github.com/mhinz/vim-signify)

顯示檔案裡面有哪些部分與git上的有所差異。

### [vim-syntastic/syntastic](https://github.com/vim-syntastic/syntastic)

幫你做語法檢查的套件，我自己會加上底下這行，令`<Leader>c`當作快捷鍵。

```bash
noremap <silent><Leader>c  :SyntasticCheck<CR>
```

### [majutsushi/tagbar](https://github.com/majutsushi/tagbar)

當你有使用ctags或cscope先對目錄底下的程式碼先做索引的話，可以使用tagbar在vim裡面顯示所有的tag。

### [mileszs/ack.vim](https://github.com/mileszs/ack.vim)

在vim裡面使用grep或是ag([The Silver Searcher](https://github.com/ggreer/the_silver_searcher))來搜尋特定字詞的套件，我自己會放以下的設定來建立快捷鍵，打上`ack[space]`會自動替換成`Ack!`，在Normal mode中打上`<Leader>a`會去搜尋游標當下所在的字詞。

```bash
if executable('ag')
    let g:ackprg = 'ag --vimgrep'
endif
cnoreabbrev ack Ack!
nnoremap <Leader>a :Ack!<CR>
```

### [scrooloose/nerdtree](https://github.com/preservim/nerdtree)

樹狀的檔案瀏覽器。

### [ctrlpvim/ctrlp.vim](https://github.com/kien/ctrlp.vim)

使你可以在vim裡面打上`Ctrl + p`便能搜尋目錄底下的檔案名稱。

### [junegunn/fzf](https://github.com/junegunn/fzf) / [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim)

功能與上面的**ctrlpvim/ctrlp.vim**幾乎雷同，只是底層是用fzf來做搜尋，我個人比較偏好這個套件，需要使用底下的設定來複寫`Ctrl + p`的預設快捷鍵。

```bash
if exists('g:plugs["fzf.vim"]')
    nmap <c-p> :FZF<CR>
endif
```

### [terryma/vim-expand-region](https://github.com/terryma/vim-expand-region)

讓你可以透過`+`和`_`來簡單的擴大或縮小選取的範圍，可以看連結內的demo。

### [godlygeek/tabular](https://github.com/godlygeek/tabular)

讓你可以方便的對齊你的程式碼，可以看這邊的[demo](http://vimcasts.org/episodes/aligning-text-with-tabular-vim/)，我自己會加上底下的設定來建立快捷鍵。

```bash
if exists('g:plugs["tabular"]')
    cnoreabbrev tab Tab
endif
```

### [terryma/vim-multiple-cursors](https://github.com/terryma/vim-multiple-cursors)

讓vim擁有像Sublime那樣的多個游標的功能。
