## vim-calzone

A Vim plugin which colorizes #ifdef zones in the sign column. No more, no less.

### Behavior

For now, this plugin just use matching patterns to define two zones to be colored on the actual buffer. 
Patterns match this way:

\\#ifdef SECTION 
\\|
\\| Zone 1
\\|
\\#else
\\|
\\| Zone 2
\\|
\\#endif 

### Installation

Before installation, please check your Vim supports signs by running `:echo has('signs')`.  `1` means you're all set; `0` means you need to install a Vim with signs support.  If you're compiling Vim yourself you need the 'big' or 'huge' feature set.  [MacVim][] supports signs.

If you don't have a preferred installation method, I recommend installing [Pathogen], and then simply copy and paste:

```
cd ~/.vim/bundle
git clone git://github.com/Agyar/vim-calzone.git
```

Or for [Vundle](https://github.com/gmarik/vundle) users:

Add `Plugin 'Agyar/vim-calzone'` to your `~/.vimrc` and then:

* either within Vim: `:PluginInstall`
* or in your shell: `vim +PluginInstall +qall`

### Screenshot

![screenshot](https://raw.github.com/Agyar/vim-calzone/master/screenshot.png)

In the screenshot above you can see:

* Blue column shows Zone 1 
* Green column shows Zone 2
* Use of inner #if #else #end in zones is correctly handled

### Usage and customisation

Call :Calzone to enable

The call may feels laggy due to activation of the vim SignColumn. This can be alleviated by launching it by default. You can add theses lines:

```
function! ShowSignColumn()
  sign define dummy
  execute 'sign place 9999 line=1 name=dummy buffer=' . bufnr('') 
endfunc 
au BufRead,BufNewFile * call ShowSignColumn()
```

Colors can be personalized simply by digging the calzone.vim file. 
Default color of the vim SignColumn can be controlled by your colorscheme by adding something like this:
```
hi SignColumn ctermbg=0 ctermfg=0
```

### TODO and limits

* No bindings offered yet
* No regex personalisation offered yet
* Handles only on couple of regex 
* Toggling is not perfect
* Performances ??
