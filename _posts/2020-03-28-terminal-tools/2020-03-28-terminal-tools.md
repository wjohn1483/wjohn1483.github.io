---
title: Terminal小工具
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax: true
mathjax_autoNumber: true
published: true
---

這篇記錄一下我在terminal裡面常使用的一些小工具們。

<!--more-->

## Terminal

Terminal又稱為終端機，是一個可以用指令跟電腦做溝通、操縱的介面，是個絕大多數工程師都曾使用過的東西，如果你的電腦使用的是Linux系統的話，原生就有terminal了，底下稍微介紹一下在各個系統安裝terminal的方法。

### Cygwin

在Windows系統上原生也有一個`命令提示字元`，雖然它外表跟terminal長得蠻像的，但裡面的指令跟大多數的terminal有蠻大的差異，如果你想要在windows系統上也能夠使用terminal的話，我推薦安裝[Cygwin](https://www.cygwin.com/)，只需要去其網站上下載[setup-x86_64](https://www.cygwin.com/setup-x86_64.exe)，照著步驟做應該就能安裝好了。

如果想要安裝其他套件，像是vim、git等等，可以再次執行[setup-x86_64](https://www.cygwin.com/setup-x86_64.exe)，並在裡面勾選，或是安裝`apt-cyg`，在裡面用指令來安裝。

#### 安裝apt-cyg

```bash
wget https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg
chmod +x apt-cyg
mv apt-cyg /usr/local/bin
```

安裝完成以後就能夠使用底下的指令來安裝其他的套件了。

```bash
apt-cyg install nano
apt-cyg install git
```

### iTerm

在Mac裡面也有原生的`終端機`，但蠻多人都推薦在Mac上使用[iTerm2](https://www.iterm2.com/)，你可以使用[Homebrew](https://brew.sh/index_zh-tw.html)來安裝。

1. 安裝Homebrew

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    ```

2. 安裝iTerm2

    ```bash
brew cask install iterm2
    ```
    
    

## Bash

如果你的系統上面只能允許你使用bash的話，我自己個人會建議將底下的東西放入你的**~/.bashrc**檔裡。

```bash
export TERM=xterm-256color
export PS1="[\u@\h \W]\\$ \[$(tput sgr0)\]"
```

上面的動作可以使你的terminal能顯示256色，可以透過[這個script](http://www.robmeerman.co.uk/_media/unix/256colors2.pl)，搭配底下的指令

```bash
perl 256colors2.pl
```

來檢驗你的terminal是否有支援256色，於此同時將命令列調整成

```bash
[使用者名稱@電腦名稱 當前目錄]$ 
```

比較易於使用。

## ZSH

若你的環境允許你安裝其他東西的話，會建議將原生的bash替換成zsh，安裝方法如下

#### Cygwin

```bash
apt-cyg install zsh curl git
```

#### iTerm

```bash
brew install zsh zsh-completions
```

#### 切換預設的shell

若想要將預設的bash換成zsh的話，可以利用底下的指令

```bash
chsh -s $(which zsh)
```

並利用

```bash
echo $SHELL
```

來確認是否有切換成功。

### oh-my-zsh

[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)是一個管理zsh的框架，提供了蠻多套件和主題可以使用，只需要打上底下的指令就能安裝好了。

```bash
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### zsh-autosuggestions

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)是一個zsh的套件，可以根據你以前打過的指令去猜測你現在要打的指令，安裝方法如下

1. 下載zsh-autosuggestions

    ```bash
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    ```

2. 修改**~/.zshrc**，找到設定檔中`plugins=(git)`的部分，將之修改成以下

    ```bash
plugins=(
        git
        zsh-autosuggestions
)
    ```

3. 重新載入zsh

    ```bash
source ~/.zshrc
    ```

### zsh-syntax-highlighting

[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)是個在zsh裡面幫你highlight一些指令、路徑等參數的套件，安裝方法如下

1. 下載zsh-syntax-highlighting

    ```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    ```

2. 修改**~/.zshrc**，找到設定檔中`plugins=(git)`的部分，將之修改成以下

    ```bash
    # If you had installed zsh-autosuggestions
    plugins=(
        git
        zsh-autosuggestions
        zsh-syntax-highlighting
    )
    # If you only want to install zsh-syntax-highlighting
    plugins=(
        git
        zsh-syntax-highlighting
    )
    ```

3. 重新載入zsh

    ```bash
    source ~/.zshrc
    ```

## Tools

### fzf

[fzf](https://github.com/junegunn/fzf)是一個命令列的工具，使你可以fuzzy search你之前下過的指令或者是當前目錄底下的檔案，詳細的使用情形可以參考[這個影片](https://www.youtube.com/watch?v=qgG5Jhi_Els)，其安裝方式如下

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

在安裝完成了以後，可以隨時在命令列按下`<Ctrl+R>`來搜尋之前下過的指令、按下`<Ctrl+T>`來搜尋當前目錄底下的檔案，這個工具好用的地方是，在搜尋的時候並不需要打上完全一樣的字串，只需要打上相似的字串就可以直接幫你動態地尋找指令和命令了。

### hadoop-bash-completion

當你需要在命令列上面操作一些在hadoop filesystem上面的檔案的時候，你可能會希望hadoop也可以支援像一般bash的路徑自動完成的功能，這時你可以參考[hadoop-bash-completion](https://github.com/lensesio/hadoop-bash-completion)，使用的方法很簡單，只需要將repo裡面的[hadoop-completion.sh](https://github.com/lensesio/hadoop-bash-completion/blob/master/hadoop-completion.sh)下載下來，並source它就行了

```bash
source hadoop-completion.sh
```

之後每當你打上hadoop相關指令或是路徑的時候，按下`<tab>`就會自動完成了。

## 參考資料

1. [透過在 Mac 上安裝iTerm2 活潑你的終端機](https://dustinhsiao21.com/2019/04/09/%E9%80%8F%E9%81%8E%E5%9C%A8-mac-%E4%B8%8A%E5%AE%89%E8%A3%9Diterm2-%E6%B4%BB%E6%BD%91%E4%BD%A0%E7%9A%84%E7%B5%82%E7%AB%AF%E6%A9%9F/)