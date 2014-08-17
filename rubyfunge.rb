require 'optparse'
require_relative 'ip'
def convert(prog)
  # Turn a string into an array representation of a program
  prog = prog.gsub /\r\n?/, "\n"
  prog = prog.lines.to_a
  prog.each_index do |i|
    prog[i] = prog[i].split('')
    prog[i].each_index do |char|; prog[i][char] = prog[i][char].ord; end
    # Remove all form feeds, because Befunge should ignore them.
    prog[i] -= [12]; prog[i] -= [10]
  end
  size = prog.max_by(&:size).size
  prog.each do |row|
    while row.length < size
      row << 32
    end
  end
  prog
end

def charexec(ip, char)
  case char
    when '@'.ord
      $iparr -= [ip]
      if $iparr == []
        $stop = true
      end
    when '.'.ord
      a = ip.pop; print "#{a} "; $outbuffer += "#{a} "
    when ','.ord
      a = ip.pop; a = a <= 0xffff ? a.chr('UTF-8') : ' '; print a; $outbuffer += a
    when 'a'.ord..'f'.ord, '0'.ord..'9'.ord
      ip.push char.chr.to_i(16)
    when '>'.ord
      if ip.hovermode
        ip.delta[0] += 1
      else
        ip.delta = [1, 0]
      end
    when '<'.ord
      if ip.hovermode
        ip.delta[0] -= 1
      else
        ip.delta = [-1, 0]
      end
    when '^'.ord
      if ip.hovermode
        ip.delta[1] -= 1
      else
        ip.delta = [0, -1]
      end
    when 'v'.ord
      if ip.hovermode
        ip.delta[1] += 1
      else
        ip.delta = [0, 1]
      end
    when '?'.ord
      ip.delta = [[1, 0], [-1, 0], [0, 1], [0, -1]].sample
    when '_'.ord
      if ip.pop == 0
        if ip.hovermode
          ip.delta[0] += 1
        else
          ip.delta = [1, 0]
        end
      else
        if ip.hovermode
          ip.delta[0] -= 1
        else
          ip.delta = [-1, 0]
        end
      end
    when '|'.ord
      if ip.pop == 0
        if ip.hovermode
          ip.delta[1] += 1
        else
          ip.delta = [0, 1]
        end
      else
        if ip.hovermode
          ip.delta[1] -= 1
        else
          ip.delta = [0, -1]
        end
      end
    when '['.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = ']'.ord
      end
      ip.delta = [ip.delta[1], -ip.delta[0]]
    when ']'.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = '['.ord
      end
      ip.delta = [-ip.delta[1], ip.delta[0]]
    when 'w'.ord
      b, a = ip.pop, ip.pop
      ip.delta = if b > a
                   [ip.delta[1], -ip.delta[0]]
                 else
                   (b < a) ? [-ip.delta[1], ip.delta[0]] : ip.delta
                 end
    when '`'.ord
      ip.push ip.pop <= ip.pop ? 1 : 0
    when '+'.ord
      ip.push ip.pop + ip.pop
    when '*'.ord
      ip.push ip.pop * ip.pop
    when '-'.ord
      ip.push -ip.pop + ip.pop
    when '/'.ord
      b, a = ip.pop, ip.pop
      ip.push b == 0 ? 0 : (a / b).to_i
    when '%'.ord
      b, a = ip.pop, ip.pop
      ip.push b == 0 ? 0 : a % b
    when '!'.ord
      ip.push ip.pop != 0 ? 0 : 1
    when '#'.ord
      ip.move $bounds
    when 'j'.ord
      a = ip.pop
      if a > 0
        a.times do
          ip.move $bounds
        end
      elsif a < 0
        ip.delta = ip.delta.map {|i| -i}
        a.abs.times do
          ip.move $bounds
        end
        ip.delta = ip.delta.map {|i| -i}
      end
    when ':'.ord
      a = ip.pop
      ip.push a; ip.push a
    when '"'.ord
      ip.stringmode = true
    when 't'.ord
      $newips = [BefungeIP.new(ip, $bounds)] + $newips;
    when "'".ord
      ip.move $bounds
      ip.push $prog[ip.y][ip.x]
    when 's'.ord
      ip.move $bounds
      $prog[ip.y][ip.x] = ip.pop
    when "\\".ord
      a, b = ip.pop, ip.pop
      ip.push a; ip.push b
    when '$'.ord
      ip.pop
    when 'n'.ord
      ip.stackstack[-1] = []
    when 'x'.ord
      y = ip.pop
      x = ip.pop
      ip.delta = [x, y]
    when '{'.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = '}'.ord
      end
      n = ip.pop
      ip.stackstack << []
      if n > 0 and n < ip.stackstack[-2].length
        elements = ip.stackstack[-2][-n..ip.stackstack[-2].length]
        ip.stackstack[-1] += elements
        ip.stackstack[-2] = ip.stackstack[-2][0..-n-1]
      elsif n > 0
        ip.stackstack[-1] = ip.stackstack[-2].clone
        n-ip.stackstack[-2].length.times do
          ip.stackstack[-1] = [0] + ip.stackstack[-1]
        end
        ip.stackstack[-2] = []
      elsif n < 0
        n.abs.times do
          ip.stackstack[-2] << 0
        end
      end
      ip.stackstack[-2] << ip.storeoffset[0]
      ip.stackstack[-2] << ip.storeoffset[1]
      ip.move $bounds
      ip.storeoffset = [ip.x-$origin[0], ip.y-$origin[1]]
      ip.delta = ip.delta.map {|i| -i}
      ip.move $bounds
      ip.delta = ip.delta.map {|i| -i}
    when '}'.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = '{'.ord
      end
      if ip.stackstack.length < 2
        ip.delta = ip.delta.map {|i| -i}
      else
        n = ip.pop
        ip.storeoffset[1] = ip.stackstack[-2] == [] ? 0 : ip.stackstack[-2].pop
        ip.storeoffset[0] = ip.stackstack[-2] == [] ? 0 : ip.stackstack[-2].pop
        if n > 0 and n <= ip.stackstack[-1].length
          elements = ip.stackstack[-1][-n..ip.stackstack[-1].length]
          ip.stackstack[-2] += elements
        elsif n > 0
          elements = ip.stackstack[-1].clone
          (n-ip.stackstack[-1].length).times do
            elements = [0] + elements
          end
          ip.stackstack[-2] += elements
        elsif n < 0
          n.abs.times do
            ip.stackstack[-2].pop
          end
        end
        ip.stackstack.pop
      end
    when 'u'.ord
      if ip.stackstack.length < 2
        ip.delta = ip.delta.map {|i| -i}
      else
        count = ip.pop
        if count > 0
          count.times do
            ip.push ip.stackstack[-2].pop
          end
        elsif count < 0
          count.abs.times do
            ip.stackstack[-2] << ip.pop
          end
        end
      end
    when 'r'.ord
      ip.delta = ip.delta.map {|i| -i}
    when 'g'.ord
      y = ip.pop
      x = ip.pop
      ip.push $prog[y+$origin[1]+ip.storeoffset[1]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]]
    when 'p'.ord
      y = ip.pop
      x = ip.pop
      c = ip.pop
      while y+$origin[1]+ip.storeoffset[1] < 0
        $prog = [[32]*$prog[0].length] + $prog
        $origin[1] += 1
        ip.y += 1
        $bounds[1] += 1
      end
      while x+$origin[0]+ip.storeoffset[0] < 0
        $prog.each_index do |line|
          $prog[line] = [32] + $prog[line]
        end
        $origin[0] += 1
        ip.x += 1
        $bounds[0] += 1
      end
      while y+$origin[1]+ip.storeoffset[1] >= $bounds[1]
        $prog << [32]*$prog[0].length
        $bounds[1] += 1
      end
      while x+$origin[0]+ip.storeoffset[0] >= $bounds[0]
        $prog.each do |line|
          line << 32
        end
        $bounds[0] += 1
      end
      $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]] = c
    when 'A'.ord..'Z'.ord
      ip.fingerhash[char.chr].call ip
    when '('.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = ')'.ord
      end
      count = ip.pop
      num = 0
      count.times do
        new = ip.pop
        num *= 256
        num += new
      end
      ip.load num
    when ')'.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = '('.ord
      end
      count = ip.pop
      num = 0
      count.times do
        new = ip.pop
        num *= 256
        num += new
      end
      ip.unload num
    when 'k'.ord
      a = ip.pop
      if a == 0
        ip.move $bounds
        ip.move $bounds
      elsif a > 0
        tempcoords = ip.coords.clone
        ip.move $bounds
        while $prog[ip.y][ip.x] == ' '.ord or $prog[ip.y][ip.x] == ';'.ord
          if $prog[ip.y][ip.x] == ' '.ord
            ip.move $bounds
          else
            ip.move $bounds
            while $prog[ip.y][ip.x] != ';'.ord
              ip.move $bounds
            end
            ip.move $bounds
          end
        end
        x = ip.x
        y = ip.y
        ip.coords = tempcoords.clone
        tempdelta = ip.delta.clone
        a.times do
          ip.delta = tempdelta.clone
          charexec ip,$prog[y][x]
        end
      end
    when 'z'.ord

    when 'q'.ord
      exit ip.pop
    when 'y'.ord
      ip.sysinfo ip.pop
    when '~'.ord
      while $inbuffer == ''
        $inbuffer = gets.chomp
      end
      ip.push $inbuffer[0].ord
      $inbuffer = $inbuffer[1..$inbuffer.length]
      if $inbuffer.nil?
        $inbuffer = ''
      end
      STDIN.flush
    when '&'.ord
      good = false
      until good
        while $inbuffer == ''
          $inbuffer = gets.chomp
        end
        if '-0123456789'.split('').include? $inbuffer[0]
          good = true
          numstr = $inbuffer[0]
          $inbuffer = $inbuffer[1..$inbuffer.length]
          if $inbuffer.nil?
            $inbuffer = ''
          end
          while '0123456789'.split('').include? $inbuffer[0]
            numstr += $inbuffer[0]
            $inbuffer = $inbuffer[1..$inbuffer.length]
            if $inbuffer.nil?
              $inbuffer = ''
            end
          end
          num = numstr.to_i
          ip.push num
        else
          $inbuffer = $inbuffer[1..$inbuffer.length]
          if $inbuffer.nil?
            $inbuffer = ''
          end
        end
      end
    else
      ip.delta = ip.delta.map {|i| -i}
      puts "Unknown instruction #{char <= 0xffff ? char.chr('UTF-8') : char} found at #{[ip.coords[0]-$origin[0], ip.coords[1]-$origin[1]]}"
  end
end

def execute(prog, debug=false)
  $inbuffer = ''
  $prog = convert prog
  $bounds = [$prog[0].length, $prog.length]
  $iparr = [BefungeIP.new]
  $origin = [0, 0]
  $outbuffer = ''
  while true
    $newips = []
    $iparr.each do |ip|
      unless ip.sleep
        if $prog[ip.y][ip.x] == ' '.ord and ip.stringmode
          ip.push 32
        end
        while $prog[ip.y][ip.x] == ' '.ord or $prog[ip.y][ip.x] == ';'.ord and not ip.stringmode
          if $prog[ip.y][ip.x] == ' '.ord
            ip.move $bounds
          else
            ip.move $bounds
            while $prog[ip.y][ip.x] != ';'.ord
              ip.move $bounds
            end
            ip.move $bounds
          end
        end
        while $prog[ip.y][ip.x] == ' '.ord and ip.stringmode
          ip.move $bounds
        end
        $char = $prog[ip.y][ip.x]
        unless ip.stringmode
            charexec ip,$prog[ip.y][ip.x]
        else
          if $prog[ip.y][ip.x] == '"'.ord
            ip.stringmode = false
          else
            ip.push $prog[ip.y][ip.x]
          end
        end
        if debug
          puts
          puts "IP ##{$iparr.index(ip)}"
          puts "Output: #{$outbuffer}"
          puts "Coords: #{ip.coords}"
          puts "Delta: #{ip.delta}"
          puts "Stack: #{ip.stackstack[-1]}"
          puts "SOSS: #{ip.stackstack[-2]}"
          puts "Character executed: #{$char <= 0xffff ? $char.chr('UTF-8') : $char}"
          rows = $prog[[0, ip.y-2].max..[$bounds[1], ip.y+2].min]
          puts "Rows surrounding IP: \n#{rows.map {|i| i.map {|j| j <= 0xffff && j > 9 ? j.chr('UTF-8') : ' '}.join('')}.join("\n")}"
          gets
        end
        ip.move $bounds
      end
    end
    $iparr = $newips + $iparr
    if $stop
      $stop = nil
      return
    end
  end
end
filename = ''
debug = false
parse = OptionParser.new do |opts|
  opts.banner = 'Usage: rubyfunge.rb [options]'
  opts.on('-f FILENAME', '--file FILENAME') do |file|
    filename = file
  end
  opts.on('-d', '--debug') do
    debug = true
  end
end
parse.parse!
if File.file? filename and filename != ''
  execute File.open(filename).read, debug
elsif filename == ''
  print parse
else
  puts "File #{filename} not found."
end