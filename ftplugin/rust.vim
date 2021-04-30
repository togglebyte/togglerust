if exists('g:florp_loaded')
    finish
endif
let g:florp_loaded = 1 

" -----------------------------------------------------------------------------
"     - Rust help -
" -----------------------------------------------------------------------------
function! RustDocs()
    let l:word = expand("<cword>")
    :call RustMan(word)
endfunction

function! RustMan(word)
    if has('nvim')
        let l:command  = ':term rusty-man ' . a:word
    else
        let l:command  = ':term ++close rusty-man ' . a:word
    endif

    execute command
endfunction

:command! -nargs=1 Rman call RustMan(<f-args>)

" -----------------------------------------------------------------------------
"     - Compiling -
" -----------------------------------------------------------------------------
function! CompileSomeRust()
    echo "compiling..."
    silent make! check
    redraw!

    let qflist = getqflist()
    let l:error_count = 0
    if len(qflist) > 0
        " Check for type W
        " Ignore everything until we get an E
        let l:collect_err = 0
        let l:new_qf_list = []
        for i in qflist 
            if i.type == "W"
                let l:collect_err = 0
            endif

            if i.type == "E"
                let l:collect_err = 1
                let l:error_count = l:error_count + 1
            endif

            " Add errors to the new quickfix list
            if l:collect_err 
                call add(new_qf_list, i)
            endif

        endfor

        call setqflist(new_qf_list)

        if l:error_count > 0
            copen
        else
            echo "no errors..."
        endif
    else
        echo "no errors..."
    endif
endfunction

:command! Compile call CompileSomeRust()


" -----------------------------------------------------------------------------
"     - Debug stuff -
" -----------------------------------------------------------------------------
let termdebugger="rust-gdb"

" " Find rust function name
" " Taken from rust.vim (https://github.com/rust-lang/rust.vim)
" let g:vebugger_path_gdb = 'rust-gdb'
" function! FindTestFunctionNameUnderCursor() abort
"     let cursor_line = line('.')

"     " Find #[test] attribute
"     if search('\m\C#\[test\]', 'bcW') is 0
"         return ''
"     endif

"     " Move to an opening brace of the test function
"     let test_func_line = search('\m\C^\s*fn\s\+\h\w*\s*(.\+{$', 'eW')
"     if test_func_line is 0
"         return ''
"     endif

"     " Search the end of test function (closing brace) to ensure that the
"     " cursor position is within function definition
"     normal! %
"     if line('.') < cursor_line
"         return ''
"     endif

"     return matchstr(getline(test_func_line), '\m\C^\s*fn\s\+\zs\h\w*')
" endfunction

" function FindTestExecutable(test_func_name) abort
"     let l:command = 'cargo test ' . a:test_func_name . ' -v'
"     let l:test_output = system(command)
"     let l:lines = reverse(split(test_output, '\n'))

"     let l:use_next=0
"     for line in lines
"         if (line=~'Running')
"             let l:fragments = split(line)

"             " Use this line to get the path to the executable
"             if l:use_next > 0 
"                 let l:test_exec = split(fragments[1], '`')[0]
"                 if len(fragments) < 3
"                     return test_exec
"                 endif
"                 let l:test_name = split(fragments[2], '`')[0]
"                 return test_exec
"             endif

"             " If there was more than zero tests run
"             " use the next available executable
"             if str2nr(fragments[1]) > 0
"                 let l:use_next = 1
"             endif
"         endif
"     endfor 

"     return ''
" endfunction

" " function RunDebuggerFromTest()
" function RunDebugger()
"     let l:test_func_name = FindTestFunctionNameUnderCursor()
"     echo l:test_func_name

"     if len(l:test_func_name)
"         let l:test_bin_path = FindTestExecutable(l:test_func_name)
"         call vebugger#gdb#start(l:test_bin_path , {'args': [l:test_func_name], 'entry':l:test_func_name})
"     else
"         call RunDebuggerFromMain()
"     endif

" endfunction

" function DebugProject()
"     let l:path_fragments = split(getcwd(), '/')
"     let l:project_name = path_fragments[-1]
"     let l:bin_dir = 'target/debug/'
"     let l:bin_path = bin_dir . project_name
"     if filereadable(bin_path)
"         let l:command = ':VBGstartGDB ' . bin_path
"         execute command
"     endif
" endfunction

" function RunDebuggerFromMain()
"     echo "building ..."
"     " Build project to ensure we have target/debug
"     let l:command = 'cargo build'
"     let l:output = system(command)
"     call DebugProject()
" endfunction
