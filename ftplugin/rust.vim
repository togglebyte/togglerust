if exists('g:ft_togglerust_loaded')
    finish
endif
let g:ft_togglerust_loaded = 1 

" -----------------------------------------------------------------------------
"     - Highlight groups -
" -----------------------------------------------------------------------------
highlight ToggleRustErr ctermbg=0 ctermfg=1
highlight ToggleRustWarn ctermbg=0 ctermfg=3

" -----------------------------------------------------------------------------
"     - Rust help -
" -----------------------------------------------------------------------------
" function! RustDocs()
"     let l:word = expand("<cword>")
"     :call RustMan(word)
" endfunction

" function! RustMan(word)
"     if has('nvim')
"         let l:command  = ':term rusty-man ' . a:word
"     else
"         let l:command  = ':term ++close rusty-man ' . a:word
"     endif

"     execute command
" endfunction

" :command! -nargs=1 Rman call RustMan(<f-args>)

" -----------------------------------------------------------------------------
"     - Compiling -
" -----------------------------------------------------------------------------
function! CompileSomeRust()
    echo "cargo check..."
    silent make! check
    redraw!

    let qflist = getqflist()
    let l:error_count = 0
    let l:warning_count = 0
    if len(qflist) > 0
        " Check for type W
        " Ignore everything until we get an E
        let l:collect_err = 0
        let l:new_qf_list = []
        for i in qflist 

            " Count number of warnings
            if i.type == "W" && i.text !~ ".*generated\\s\\d*\\swarning"
            " if i.type == "W"
                let l:warning_count += 1
                let l:collect_err = 0
            endif

            " Count errors
            if i.type == "E"
                let l:collect_err = 1
                let l:error_count += 1
            endif

            " Add errors to the new quickfix list
            if l:collect_err 
                call add(new_qf_list, i)
            endif

        endfor

        call setqflist(new_qf_list)

    endif

    " If we have errors then open the quickfix window
    " otherwise display the number of warnings
    if l:error_count > 0
        if tabpagewinnr(tabpagenr(), '$') > 1
            botright copen 6
        else
            copen 6
        endif
        wincmd p
	cfirst
    else
        cclose
    endif

    let l:err_out = "echo 'E: " . error_count . "'"
    if l:error_count > 0 
        let l:err_out = "echohl ToggleRustErr | echo 'E: " . error_count . "' | echohl None"
    endif

    let l:warn_out = " | echon ' | W: " . warning_count . "'"
    if l:warning_count > 0 
        let l:warn_out = "| echon ' | ' | echohl ToggleRustWarn | echon 'W: " . warning_count . "' | echohl None"
    endif

    " if l:error_count == 0 && l:warning_count == 0
    "     let l:err_out = "echo '- 💖 -'"
    "     let l:warn_out = ''
    " endif

    exec err_out . warn_out

endfunction

:command! Compile call CompileSomeRust()


" -----------------------------------------------------------------------------
"     - Debug stuff -
" -----------------------------------------------------------------------------
let g:termdebugger="rust-gdb"
let g:termdebug_useFloatingHover = 0


" Find rust function name
" Taken from rust.vim (https://github.com/rust-lang/rust.vim)
function! FindTestFunctionNameUnderCursor() abort
    let cursor_line = line('.')

    " Find #[test] attribute
    if search('\m\C#\[test\]', 'bcW') is 0
        return ''
    endif

    " Move to an opening brace of the test function
    let test_func_line = search('\m\C^\s*fn\s\+\h\w*\s*(.\+{$', 'eW')
    if test_func_line is 0
        return ''
    endif

    " Search the end of test function (closing brace) to ensure that the
    " cursor position is within function definition
    normal! %
    if line('.') < cursor_line
        return ''
    endif

    return matchstr(getline(test_func_line), '\m\C^\s*fn\s\+\zs\h\w*')
endfunction

function FindTestExecutable(test_func_name) abort
    let l:command = 'cargo test --all-features ' . a:test_func_name . ' -v'
    let l:test_output = system(command)
    let l:lines = reverse(split(test_output, '\n'))

    let l:use_next=0
    for line in lines
        if (line=~'Running')
            let l:fragments = split(line)

            " Use this line to get the path to the executable
            if l:use_next > 0 
                let l:test_exec = split(fragments[1], '`')[0]
                if len(fragments) < 3
                    return test_exec
                endif
                let l:test_name = split(fragments[2], '`')[0]
                return test_exec
            endif

            " If there was more than zero tests run
            " use the next available executable
            if str2nr(fragments[1]) > 0
                let l:use_next = 1
            endif
        endif
    endfor 

    return ''
endfunction

function RunDebugger()
    let l:line_nr = line(".")
    let l:test_func_name = FindTestFunctionNameUnderCursor()
    echo "Debugging: " . l:test_func_name

    if len(l:test_func_name)
        let l:test_bin_path = FindTestExecutable(l:test_func_name)
        let l:command = ':Termdebug ' . test_bin_path
        exec command
    else
        call RunDebuggerFromMain()
    endif

    wincmd p
    normal k
    " jump to the line nr where the debug was called from
    let l:jump_command = ':' . line_nr
    exec jump_command
    :Break
    :Program
    :hide
    :Run
endfunction

function DebugProject()
    let l:path_fragments = split(getcwd(), '/')
    let l:project_name = path_fragments[-1]
    let l:bin_dir = 'target/debug/'
    let l:bin_path = bin_dir . project_name


    " If there is no 'target/debug' perhaps this is a workspace?
    " Try the parent dir
    if !filereadable(bin_dir . project_name)
       let l:bin_path = '../target/debug/' . project_name
    endif

    if filereadable(bin_path)
        let l:command = ':Termdebug ' . bin_path
        exec command

        wincmd p
    endif
endfunction

function RunDebuggerFromMain()
    echo "building ..."
    " Build project to ensure we have target/debug
    let l:command = 'cargo build'
    let l:output = system(command)
    call DebugProject()
endfunction


function RunDebugAndBreak()
    " Set a breakpoint if the debugger is running
    " otherwise start the debugger and then set the breakpoint
    if g:TermDebugging > 0
        exec ':Break'
    else
        call RunDebuggerFromMain()
        :Break
        :Run
    endif
endfunction

:command! DebugTest call RunDebugger()
:command! DebugMain call RunDebuggerFromMain()
:command! DebugAndBreak call RunDebugAndBreak()
