if !has("ruby") && !has("ruby/dyn")
    finish
endif

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

fun! terraformcomplete#GetProviderAndResource()
    let a:curr_pos = getcurpos()
    execute '?resource'
    let a:provider = split(split(substitute(getline(getcurpos()[1]),'"', '', ''))[1], "_")[0]
	let a:resource = substitute(split(split(getline(getcurpos()[1]))[1], a:provider . "_")[1], '"','','')
    let a:test_pos = getcurpos()
    call setpos(".", a:curr_pos)
	return [a:provider, a:resource]
endfun

function! terraformcomplete#rubyComplete(ins, provider, resource)
    let a:res = []
  ruby << EOF
require 'json'

def terraform_complete(provider, resource)
    if provider == "digitalocean" then
      provider = "do"
    end

    begin
        data = ''
        File.open("#{VIM::evaluate('s:path')}/../provider_json/#{provider}.json", "r") do |f|
          f.each_line do |line|
            data = line
          end
        end
        return JSON.generate(JSON.parse(data)[resource]["words"])
    rescue 
        return []
    end
end

class TerraformComplete
  def initialize()
    @buffer = Vim::Buffer.current
    result = terraform_complete(VIM::evaluate('a:provider'), VIM::evaluate('a:resource'))
    Vim::command("let a:res = #{result}")
  end
end
gem = TerraformComplete.new()
EOF
return a:res
endfunction

fun! terraformcomplete#Complete(findstart, base)
    if a:findstart
        " locate the start of the word
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '\a'
            let start -= 1
        endwhile
        return start
    else
        let res = []
		try
			let a:result = terraformcomplete#GetProviderAndResource() 
		catch
			let a:result = ['', '']
		endtry

        let a:provider = a:result[0]
        let a:resource = a:result[1]
        for m in terraformcomplete#rubyComplete(a:base, a:provider, a:resource)
            if m.word =~ '^' . a:base
                call add(res, m)
            endif
        endfor
        return res
    endif
endfun

