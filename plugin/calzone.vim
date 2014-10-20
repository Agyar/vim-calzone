" calzone.vim
" Benjamin Lorendeau
"
" This will hilight part of the line number section depending on 
" matching pattern. 

if !has('signs')
  finish
endif

if !has('python')
  finish
endif 

if exists("g:loaded_calzone") 
  finish 
endif 

function! s:ClearSigns()
  sign unplace *
endfunction 

function! s:ToggleCalzone()
  if exists("g:calzone_is_on_the_table") && g:calzone_is_on_the_table 
    "call s:ClearSigns()
    call s:ClearCalzones()
    let g:calzone_is_on_the_table = 0
  else
    call s:DeliverCalzone()
  endif
endfunction

python << endpython
import vim 
#!/usr/bin/env python 
import sys 
import os
import re
import linecache

def clear_calzones():
    curr_calzones={}
    curr_buffer = vim.current.buffer.name
    curr_calzones_list = get_current_calzones(curr_buffer)

    for line in curr_calzones_list:
        
        if '=' not in line:
            continue

        tokens = line.split()
        variables = dict(token.split('=') for token in tokens)
        # print variables
        # so vim has french version ... fuck it
        line = variables['ligne']
        curr_calzones[line] = variables['nom']
    
    for line, name in curr_calzones.iteritems():
        if name >= 'calzones':
            vim.command(':sign unplace %i' % int(line))

def get_current_calzones(current_file):
    vim.command('redir => s:calzones_sign_list')
    vim.command('silent sign place file=%s' % current_file)
    vim.command('redir END')

    sign_list = vim.eval('s:calzones_sign_list')
    lines = [line.strip() for line in sign_list.split('\n')]
    return lines

def make_calzones(filename=None, code=None):
    if code:
        filename = code
    
    curr_buffer = vim.current.buffer.name
    filename = curr_buffer

    # parse code and determines zone of #ifdef #else #endif
    calzones = CalzonesParser(filename).Parse()
    # separate #ifdef and #else zones
    # this is objectively NOT really useful since they are meant to interlace
    calzones_if = [ k for k,v in calzones.items() if v == 'IF' ]
    calzones_else = [ k for k,v in calzones.items() if v == 'ELSE' ]
    # place signs on code
    for zone_intervale in calzones_if:
        for line in range(zone_intervale[0], zone_intervale[1]+1):
            vim.command(':sign place %i line=%i name=%s file=%s' %
                        ( line, line, 'calzones_if', curr_buffer))
    for zone_intervale in calzones_else:
        for line in range(zone_intervale[0], zone_intervale[1]+1):
            vim.command(':sign place %i line=%i name=%s file=%s' %
                        ( line, line, 'calzones_else', curr_buffer))

    vim.command('redir => s:calzones_sign_list')
    vim.command('silent sign place file=%s' % curr_buffer)
    vim.command('redir END')
            
class CalzonesParser:

    def __init__(self, code):
        # define patterns to match 
        self.code = code
        self._if  = re.compile(".*#if")
        self._ifd = re.compile(".*#ifd")
        self._els = re.compile(".*#else")
        self._end = re.compile(".*#end")
        self.calzones = {} # dictionnary of calzones by {(start, end) : type}

    def Parse(self):
        lineno = 1 

        while True:
            line = linecache.getline(self.code, lineno)
            if line == '':
                if lineno == 1:
                  vim.command(":q")
                break

            calzone = self._ifd.match(line)
            if calzone: 
                SFC, lineno_e = self.SearchForBranch(lineno + 1, self.code)
                zone_if = ( lineno, lineno_e )
                self.calzones[zone_if] = 'IF'

                if SFC:
                    lineno_d = self.SearchForClosure(lineno_e + 1, self.code)
                    zone_else = ( lineno_e + 1, lineno_d )
                    self.calzones[zone_else] = 'ELSE'
                    lineno = lineno_d
                else:
                    lineno = lineno_e

            lineno = lineno + 1
        return self.calzones

    def SearchForBranch(self, lineno, code):
        inner_loop = 0
        els = 0
        while True:
            line = linecache.getline(code, lineno)
            if line == '':
                return els, lineno
    
            calzonif = self._if.match(line)
            calzonelse = self._els.match(line)
            calzonend = self._end.match(line)

            if (calzonelse or calzonend):
                if calzonelse and not inner_loop:
                    els = 1
                if inner_loop == 0:
                    return els, lineno
                else:
                    inner_loop = inner_loop - 1
            elif calzonif:
                inner_loop = inner_loop + 1
                
            lineno = lineno + 1

    def SearchForClosure(self, lineno, code):
        inner_loop = 0
        while True:
            line = linecache.getline(code, lineno)
            if line == '':
                return lineno

            calzonend = self._end.match(line)
            calzonif = self._if.match(line)
            if calzonend:
                if inner_loop == 0:
                    return lineno 
                else:
                    inner_loop = inner_loop - 1
            elif calzonif:
                inner_loop = inner_loop + 1
            lineno = lineno + 1

def main():
    if sys.stdin.isatty() and len(sys.argv) < 2:
        print "Missing filename"
        return 
    
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        content = None 
    else: 
        filename = None 
        content = sys.stdin.read() 

    try: 
        make_calzones(filename, content)
    except: 
        pass
    
if __name__ == '__main__':
    if 'vim' not in globals():
        main()
endpython

function! s:ClearCalzones()
    python << CCEND
clear_calzones()
CCEND
endfunction

function! s:DeliverCalzone()
    python << END
make_calzones()
END
  let g:calzone_is_on_the_table = 1
endfunction

hi SignColumn guifg=fg guibg=bg
hi calzones_else ctermfg=6 ctermbg=6
hi calzones_if ctermfg=2 ctermbg=2
sign define calzones_if text=XX texthl=calzones_if
sign define calzones_else text=XX texthl=calzones_else

command! Calzone call s:ToggleCalzone()
