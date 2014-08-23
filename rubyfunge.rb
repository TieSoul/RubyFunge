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
  # Pad all lines to an equal size.
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
    # @ kills the IP, terminating the program if all IPs are dead.
    when '@'.ord
      $iparr -= [ip]
      if $iparr == []
        $stop = true
      end
    # . outputs a popped value as a number.
    when '.'.ord
      a = ip.pop; print "#{a} "; $outbuffer += "#{a} "
    # , outputs a popped value as a UTF-8 character, outputting a space if the value is bigger than 0xffff, the maximum
    # UTF-8 value.
    when ','.ord
      a = ip.pop; a = a <= 0xffff ? a.chr('UTF-8') : ' '; print a; $outbuffer += a
    # 0-f pushes the hexadecimal value it represents.
    when 'a'.ord..'f'.ord, '0'.ord..'9'.ord
      ip.push char.chr.to_i(16)
    # > makes the IP go right. More information about hovermode can be found in the fingerprints section of ip.rb.
    when '>'.ord
      if ip.hovermode
        ip.delta[0] += 1
      else
        ip.delta = [1, 0]
      end
    # < makes the IP go left.
    when '<'.ord
      if ip.hovermode
        ip.delta[0] -= 1
      else
        ip.delta = [-1, 0]
      end
    # ^ makes the IP go up.
    when '^'.ord
      if ip.hovermode
        ip.delta[1] -= 1
      else
        ip.delta = [0, -1]
      end
    # v makes the IP go down.
    when 'v'.ord
      if ip.hovermode
        ip.delta[1] += 1
      else
        ip.delta = [0, 1]
      end
    # ? makes the IP go in a random cardinal direction.
    when '?'.ord
      ip.delta = [[1, 0], [-1, 0], [0, 1], [0, -1]].sample
    # _ pops a value. If that value is 0, it makes the IP go right, else, it makes the IP go left.
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
    # | pops a value. If that value is 0, it makes the IP go down, else, it makes the IP go up.
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
    # [ turns the IP 90 degrees to the left. More information about switchmode can be found in the fingerprint section
    # of ip.rb.
    when '['.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = ']'.ord
      end
      ip.delta = [ip.delta[1], -ip.delta[0]]
    # ] turns the IP 90 degrees to the right.
    when ']'.ord
      if ip.switchmode
        $prog[ip.y][ip.x] = '['.ord
      end
      ip.delta = [-ip.delta[1], ip.delta[0]]
    # w pops two values. If the first value is greater than the second, turns the IP 90 degrees to the left, else turns
    # the IP 90 degrees to the right if the first value is less than the second. Does nothing if the values are the same.
    when 'w'.ord
      b, a = ip.pop, ip.pop
      ip.delta = if b > a
                   [ip.delta[1], -ip.delta[0]]
                 else
                   (b < a) ? [-ip.delta[1], ip.delta[0]] : ip.delta
                 end
    # ` pops two values and returns whether the second value is smaller than the first.
    when '`'.ord
      ip.push ip.pop <= ip.pop ? 1 : 0
    # + pops two values from the stack and pushes the sum.
    when '+'.ord
      ip.push ip.pop + ip.pop
    # * pops two values and multiplies them.
    when '*'.ord
      ip.push ip.pop * ip.pop
    # - pops two values and subtracts the first from the second.
    when '-'.ord
      ip.push -ip.pop + ip.pop
    # / pops two values and divides the second by the first. Division by 0 returns 0.
    when '/'.ord
      b, a = ip.pop, ip.pop
      ip.push b == 0 ? 0 : (a / b).to_i
    # % pops two values and returns (second value mod first value). x mod 0 returns 0.
    when '%'.ord
      b, a = ip.pop, ip.pop
      ip.push b == 0 ? 0 : a % b
    # ! pops a value and pushes 0 if that value isn't 0, and else 1.
    when '!'.ord
      ip.push ip.pop != 0 ? 0 : 1
    # # moves the IP forward, skipping the next instruction.
    when '#'.ord
      ip.move $bounds
    # j moves the IP forward a popped amount of times, skipping several instructions.
    # If the popped value is negative, moves the IP back |value| amount of times.
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
    # : duplicates the top of the stack.
    when ':'.ord
      a = ip.pop
      ip.push a; ip.push a
    # " engages stringmode, in which characters are pushed to the stack rather than executed until the next " is encountered.
    when '"'.ord
      ip.stringmode = true
    # t splits the IP, resulting in two IPs, one moving forward, the other backward.
    when 't'.ord
      $newips = [BefungeIP.new(ip, $bounds)] + $newips;
    # ' pushes the value of the next character to be executed to the stack and skips it.
    when "'".ord
      ip.move $bounds
      ip.push $prog[ip.y][ip.x]
    # s pops a value, sets it to the next executed coordinate in space, and skips it.
    when 's'.ord
      ip.move $bounds
      $prog[ip.y][ip.x] = ip.pop
    # \ swaps the top 2 values.
    when "\\".ord
      a, b = ip.pop, ip.pop
      ip.push a; ip.push b
    # $ discards the top of the stack.
    when '$'.ord
      ip.pop
    # n clears the stack.
    when 'n'.ord
      ip.stackstack[-1] = []
    # x pops a y value, then an x value, and sets the IP traveling with that delta.
    when 'x'.ord
      y = ip.pop
      x = ip.pop
      ip.delta = [x, y]
    # TODO: add documentation.
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
    # r turns back the IP.
    when 'r'.ord
      ip.delta = ip.delta.map {|i| -i}
    # g gets a value from popped coordinates in space.
    when 'g'.ord
      y = ip.pop
      x = ip.pop
      ip.push $prog[y+$origin[1]+ip.storeoffset[1]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]]
    # p sets a value in popped coordinates to a popped value.
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
    # Fingerprint instructions; see ip.rb.
    when 'A'.ord..'Z'.ord
      ip.fingerhash[char.chr].call ip
    # ( loads a fingerprint.
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
    # ) unloads a fingerprint.
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
    # k executes the following cmomand a popped number of times.
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
    # z is an explicit noop
    when 'z'.ord
    # q exits the program with a popped return value.
    when 'q'.ord
      exit ip.pop
    # y pushes system info, see ip.rb.
    when 'y'.ord
      ip.sysinfo ip.pop
    # ~ pushes a character from input.
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
    # & gets a number from input.
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
      # Unknown instructions function like r and get a warning message.
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
          puts "Rows surrounding IP: \n#{rows.map {|i| i.map {|j| j <= 0xffff && j > 9 ? begin; j.chr('UTF-8'); rescue RangeError; ' '; end : ' '}.join('')}.join("\n")}"
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

def main
  filename = ''
  debug = false
  parse = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"
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
end

if __FILE__ == $0
  main
end