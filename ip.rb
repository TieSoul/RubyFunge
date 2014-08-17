class Array
  def sum
    inject(:+).to_f
  end

  def average
    sum / size
  end
end

def factorial(num)
  i = num
  ans = 1
  while i > 0
    ans *= i
    i -= 1
  end
  ans
end

class BefungeIP
  def initialize(other = nil, bounds=[0, 0])
    if other
      @delta = other.delta.map {|i| -i}
      @coords = other.coords.clone
      @stackstack = other.stackstack.map {|i| i.clone}
      @storeoffset = other.storeoffset.clone
      @prevhash = other.prevhash.clone
      @fingerhash = other.fingerhash.clone
      @parent = other.id
      @id = $id + 1
      $id += 1
      @hovermode = other.hovermode
      @switchmode = other.switchmode
      @queuemode = other.queuemode
      @invertmode = other.invertmode
      move bounds
    else
      $id = 0
      @hovermode = false
      @switchmode = false
      @queuemode = false
      @invertmode = false
      @id = 0
      @delta = [1, 0]
      @coords = [0, 0]
      @stackstack = [[]]
      @storeoffset = [0, 0]
      @prevhash = Hash[*('A'..'Z').to_a.zip([lambda {|ip| ip.delta = ip.delta.map {|i| -i}; puts "Unloaded instruction #{$prog[ip.y][ip.x].chr} encountered at #{[ip.x-$origin[0], ip.y-$origin[1]]}"}] * 26).flatten]
      @fingerhash = Hash[*('A'..'Z').to_a.zip([lambda {|ip| ip.delta = ip.delta.map {|i| -i}; puts "Unloaded instruction #{$prog[ip.y][ip.x].chr} encountered at #{[ip.x-$origin[0], ip.y-$origin[1]]}"}] * 26).flatten]
    end
    @stringmode = false
  end
  def move(bounds)
    if x + delta[0] < bounds[0] and x + delta[0] >= 0 and y + delta[1] < bounds[1] and y + delta[1] >= 0
      @coords[0] += @delta[0]
      @coords[1] += @delta[1]
    else
      while x - delta[0] < bounds[0] and x - delta[0] >= 0 and y - delta[1] < bounds[1] and y - delta[1] >= 0
        @coords[0] -= @delta[0]
        @coords[1] -= @delta[1]
      end
    end
  end
  def coords
    @coords
  end
  def delta
    @delta
  end
  def coords=(val)
    @coords = val
  end
  def delta=(val)
    @delta = val
  end
  def x
    @coords[0]
  end
  def x=(val)
    @coords[0] = val
  end
  def y
    @coords[1]
  end
  def y=(val)
    @coords[1] = val
  end
  def stackstack
    @stackstack
  end
  def stackstack=(val)
    @stackstack = val
  end
  def push(x)
    unless @invertmode
      @stackstack[-1] << x
    else
      @stackstack[-1] = [x] + @stackstack[-1]
    end
  end
  def pop
    unless @queuemode
      @stackstack[-1] == [] ? 0 : @stackstack[-1].pop
    else
      if @stackstack[-1] == [] then
        0
      else
        a = @stackstack[-1][0]
        @stackstack[-1] = @stackstack[-1][1..@stackstack[-1].length]
        a
      end
    end
  end
  def storeoffset
    @storeoffset
  end
  def storeoffset=(val)
    @storeoffset = val
  end
  def stringmode
    @stringmode
  end
  def stringmode=(val)
    @stringmode = val
  end
  def fingerhash
    @fingerhash
  end
  def prevhash
    @prevhash
  end
  def hovermode
    @hovermode
  end
  def hovermode=(val)
    @hovermode = val
  end
  def invertmode
    @invertmode
  end
  def invertmode=(val)
    @invertmode = val
  end
  def queuemode
    @queuemode
  end
  def queuemode=(val)
    @queuemode = val
  end
  def switchmode
    @switchmode
  end
  def switchmode=(val)
    @switchmode=val
  end
  FINGERPRINTS = {0x4e554c4c => Hash[*('A'..'Z').to_a.zip([lambda {|ip| ip.delta = ip.delta.map {|i| -i}}] * 26).flatten],
                  0x424f4f4c => {'A' => lambda {|ip| ip.push(ip.pop & ip.pop)},
                                 'O' => lambda {|ip| ip.push(ip.pop | ip.pop)},
                                 'N' => lambda {|ip| ip.push(~ip.pop)},
                                 'X' => lambda {|ip| ip.push(ip.pop ^ ip.pop)}},
                  0x42415345 => {'B' => lambda {|ip| print ip.pop.to_s(2) + ' '},
                                 'H' => lambda {|ip| print ip.pop.to_s(16) + ' '},
                                 'I' => lambda {|ip|
                                                 good = false
                                                 base = ip.pop
                                                 until good
                                                   while $inbuffer == '' or $inbuffer.nil?
                                                     $inbuffer = gets.chomp
                                                   end
                                                   if '-0123456789abcdefghijklmnopqrstuvwxyz'[0..base].split('').include? $inbuffer[0].downcase
                                                     good = true
                                                     numstr = $inbuffer[0]
                                                     $inbuffer = $inbuffer[1..$inbuffer.length]
                                                     if $inbuffer.nil?
                                                       $inbuffer = ''
                                                     end
                                                     until $inbuffer == '' or not '0123456789abcdefghijklmnopqrstuvwxyz'[0..base-1].split('').include? $inbuffer[0].downcase
                                                       numstr += $inbuffer[0]
                                                       $inbuffer = $inbuffer[1..$inbuffer.length]
                                                       if $inbuffer.nil?
                                                         $inbuffer = ''
                                                       end
                                                     end
                                                     begin
                                                       num = numstr.to_i(base)
                                                       ip.push num
                                                     rescue ArgumentError
                                                       if base == 1
                                                         if numstr.split('').include? '-'
                                                           num = -numstr.length + 1
                                                         else
                                                           num = numstr.length
                                                         end
                                                         ip.push num
                                                       else
                                                         ip.delta = ip.delta.map {|i| -i}
                                                       end
                                                     end
                                                   else
                                                     $inbuffer = $inbuffer[1..$inbuffer.length]
                                                     if $inbuffer.nil?
                                                       $inbuffer = ''
                                                     end
                                                   end
                                                 end},
                                 'N' => lambda {|ip|
                                                base = ip.pop
                                                begin
                                                  a = ip.pop
                                                  print a.to_s(base) + ' '
                                                rescue ArgumentError
                                                  if base == 1
                                                    print "#{'0'*a} "
                                                  else
                                                    ip.delta = ip.delta.map {|i| -i}
                                                  end
                                                end},
                                 'O' => lambda {|ip| print ip.pop.to_s(8) + ' '}},
                  0x4d4f4455 => {'M' => lambda {|ip|
                                                a = ip.pop
                                                b = ip.pop
                                                if a == 0
                                                  ip.push 0
                                                else
                                                  ip.push b % a
                                                end},
                                 'R' => lambda {|ip|
                                                a = ip.pop
                                                b = ip.pop
                                                if a == 0
                                                  ip.push 0
                                                else
                                                  ip.push b > 0 ? (b % a.abs) : -(b % a.abs)
                                                end},
                                 'U' => lambda {|ip|
                                                a = ip.pop
                                                b = ip.pop
                                                if a == 0
                                                  ip.push 0
                                                else
                                                  ip.push (b % a).abs
                                                end}},
                  0x524f4d41 => {'I' => lambda {|ip|
                                                ip.push 1},
                                 'V' => lambda {|ip|
                                                ip.push 5},
                                 'X' => lambda {|ip|
                                                ip.push 10},
                                 'L' => lambda {|ip|
                                                ip.push 50},
                                 'C' => lambda {|ip|
                                                ip.push 100},
                                 'D' => lambda {|ip|
                                                ip.push 500},
                                 'M' => lambda {|ip|
                                                ip.push 1000}},
                  0x4d4f4445 => {'H' => lambda {|ip|
                                                ip.hovermode = !(ip.hovermode)},
                                 'I' => lambda {|ip|
                                                ip.invertmode = !(ip.invertmode)},
                                 'Q' => lambda {|ip|
                                                ip.queuemode = !(ip.queuemode)},
                                 'S' => lambda {|ip|
                                                ip.switchmode = !(ip.switchmode)}},
                  0x4f525448 => {'A' => lambda {|ip|
                                                ip.push ip.pop & ip.pop},
                                 'E' => lambda {|ip|
                                                ip.push ip.pop ^ ip.pop},
                                 'G' => lambda {|ip|
                                                x = ip.pop
                                                y = ip.pop
                                                ip.push $prog[y+$origin[1]+ip.storeoffset[1]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]]},
                                 'O' => lambda {|ip|
                                                ip.push ip.pop | ip.pop},
                                 'P' => lambda {|ip|
                                                 x = ip.pop
                                                 y = ip.pop
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
                                                 $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]] = c},
                                 'S' => lambda {|ip|
                                                a = ip.pop
                                                s = ''
                                                while a != 0
                                                  s += a < 0xffff ? a.chr('UTF-8') : ' '
                                                  a = ip.pop
                                                end
                                                print s
                                                $outbuffer += s},
                                 'V' => lambda {|ip|
                                                ip.delta[0] = ip.pop},
                                 'X' => lambda {|ip|
                                                ip.coords[0] = ip.pop+$origin[0]},
                                 'Z' => lambda {|ip|
                                                if ip.pop == 0
                                                  ip.move $bounds
                                                end},
                                 'W' => lambda {|ip|
                                                ip.delta[1] = ip.pop},
                                 'Y' => lambda {|ip|
                                                ip.coords[1] = ip.pop+$origin[1]}},
                  0x43504c49 => {'A' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1+c2).real; ip.push (c1+c2).imag},
                                'D' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1/c2).real.to_i; ip.push (c1/c2).imag.to_i},
                                'M' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1*c2).real.to_i; ip.push (c1*c2).imag.to_i},
                                'O' => lambda {|ip|
                                               b = ip.pop
                                               a = ip.pop
                                               print "#{Complex(a, b)} "
                                               $outbuffer += "#{Complex(a, b)} "},
                                'S' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1-c2).real.to_i; ip.push (c1-c2).imag.to_i},
                                'V' => lambda {|ip|
                                                b = ip.pop
                                                a = ip.pop
                                                ip.push Complex(a, b).abs.to_i}},
                  0x46495850=> {'A' => lambda {|ip| ip.push ip.pop & ip.pop},
                                'B' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               begin
                                                 ip.push ((Math.acos(n) / (Math::PI / 180)) * 10000).round.to_i
                                               rescue ArgumentError
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                'C' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               n *= (Math::PI / 180)
                                               ip.push (Math.cos(n) * 10000).round.to_i},
                                'D' => lambda {|ip|
                                               n = ip.pop
                                               r = n >= 0 ? rand(0..n-1) : rand(n..-1)
                                               ip.push r},
                                'I' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               n *= (Math::PI / 180)
                                               ip.push (Math.sin(n) * 10000).round.to_i},
                                'J' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               begin
                                                 ip.push ((Math.asin(n) / (Math::PI / 180)) * 10000).round.to_i
                                               rescue Math::DomainError
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                'N' => lambda {|ip| ip.push -ip.pop},
                                'O' => lambda {|ip| ip.push ip.pop | ip.pop},
                                'P' => lambda {|ip| ip.push (ip.pop * Math::PI).round.to_i},
                                'Q' => lambda {|ip|
                                               n = ip.pop
                                               if n < 0
                                                 ip.delta = ip.delta.map {|i| -i}
                                               else
                                                 ip.push (Math.sqrt n).round.to_i
                                               end},
                                'R' => lambda {|ip|
                                               b = ip.pop
                                               a = ip.pop
                                               if a == 0 and b <= 0
                                                 ip.delta = ip.delta.map {|i| -i}
                                               else
                                                 ip.push (a ** b).round.to_i
                                               end},
                                'S' => lambda {|ip|
                                               n = ip.pop
                                               ip.push n > 0 ? 1 : n < 0 ? -1 : 0},
                                'T' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               n *= (Math::PI / 180)
                                               ip.push (Math.tan(n) * 10000).round.to_i},
                                'U' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               begin
                                                 ip.push ((Math.atan(n) / (Math::PI / 180)) * 10000).round.to_i
                                               rescue Math::DomainError
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                'V' => lambda {|ip| ip.push ip.pop.abs},
                                'X' => lambda {|ip| ip.push ip.pop ^ ip.pop}},
                  0x494d5448 =>{'A' => lambda {|ip|
                                               n = ip.pop
                                               if n == 0
                                                 push 0
                                               elsif n < 0
                                                 ip.delta = ip.delta.map {|i| -i}
                                               else
                                                 arr = []
                                                 n.times do
                                                   arr << ip.pop
                                                 end
                                                 ip.push arr.average.round.to_i
                                               end},
                                'B' => lambda {|ip| ip.push ip.pop.abs},
                                'C' => lambda {|ip| ip.push ip.pop*100},
                                'D' => lambda {|ip| a = ip.pop; ip.push (a == 0 ? 0 : a > 0 ? a - 1 : a + 1)},
                                'E' => lambda {|ip| ip.push ip.pop*10000},
                                'F' => lambda {|ip| a = ip.pop; if a < 0; ip.delta = ip.delta.map {|i| -i}; else; ip.push (a == 0 ? 0 : factorial(a)); end},
                                'G' => lambda {|ip| a = ip.pop; ip.push (a == 0 ? 0 : a > 0 ? 1 : -1)},
                                'H' => lambda {|ip| ip.push ip.pop*1000},
                                'I' => lambda {|ip| a = ip.pop; ip.push (a == 0 ? 0 : a > 0 ? a + 1 : a - 1)},
                                'L' => lambda {|ip| c = ip.pop; a = ip.pop; ip.push a << c},
                                'N' => lambda {|ip|
                                               n = ip.pop
                                               if n <= 0; ip.delta = ip.delta.map {|i| -i}; else
                                                 arr = []
                                                 n.times do
                                                   arr << ip.pop
                                                 end
                                                 ip.push arr.min
                                               end},
                                'R' => lambda {|ip| c = ip.pop; ip.push ip.pop >> c},
                                'S' => lambda {|ip|
                                               n = ip.pop
                                               if n < 0
                                                 ip.delta = ip.delta.map {|i| -i}
                                               elsif n == 0
                                                 ip.push 0
                                               else
                                                 arr = []
                                                 n.times do
                                                   arr << ip.pop
                                                 end
                                                 ip.push arr.sum
                                               end},
                                'T' => lambda {|ip|
                                               ip.push ip.pop*10},
                                'U' => lambda {|ip|
                                               print ip.pop.abs; print ' '},
                                'X' => lambda {|ip|
                                               n = ip.pop
                                               if n <= 0
                                                 ip.delta = ip.delta.map {|i| -i}
                                               else
                                                 arr = []
                                                 n.times do
                                                   arr << ip.pop
                                                 end
                                                 ip.push arr.max
                                               end},
                                'Z' => lambda {|ip|
                                               ip.push -ip.pop}},
                  0x49495043 =>{'A' => lambda {|ip| ip.push ip.parent},
                                'D' => lambda {|ip| ip.sleep = true},
                                'G' => lambda {|ip|
                                               id = ip.pop
                                               found = false
                                               $iparr.each do |other|
                                                 if other.id == id
                                                   ip.push other.pop
                                                   if other.sleep; other.sleep = false; end
                                                   found = true
                                                   break
                                                 end
                                               end
                                               if not found
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                'I' => lambda {|ip|
                                               ip.push ip.id},
                                'L' => lambda {|ip|
                                               id = ip.pop
                                               found = false
                                               $iparr.each do |other|
                                                 if other.id == id
                                                   a = other.pop
                                                   other.push a
                                                   ip.push a
                                                   found = true
                                                   break
                                                 end
                                               end
                                               if not found
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                'P' => lambda {|ip|
                                               id = ip.pop
                                               val = ip.pop
                                               found = false
                                               $iparr.each do |other|
                                                 if other.id == id
                                                   other.push val
                                                   if other.sleep; other.sleep = false; end
                                                   found = true
                                                   break
                                                 end
                                               end
                                               if not found
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end}}}
  def load(val)
    fing = FINGERPRINTS[val]
    if fing.nil?
      @delta = @delta.map {|i| -i}
    else
      fing.each_key do |letter|
        @prevhash[letter] = @fingerhash[letter].clone
        @fingerhash[letter] = fing[letter].clone
      end
      push val
      push 1
    end
  end
  def unload(val)
    fing = FINGERPRINTS[val]
    if fing.nil?
      @delta = @delta.map {|i| -i}
    else
      fing.each_key do |letter|
        @fingerhash[letter] = @prevhash[letter].clone
        @prevhash[letter] = lambda {|ip| ip.delta = ip.delta.map {|i| -i}; puts "Unloaded instruction #{$prog[ip.y][ip.x].chr} encountered at #{[ip.x-$origin[0], ip.y-$origin[1]]}"}
      end
    end
  end
  def id
    @id
  end
  def sysinfo(num)
    tempstackstack = @stackstack.map {|i| i.clone}
    push 0
    ENV.each_key do |env|
      push 0
      ENV[env].reverse.each_char do |char|
        push char.ord
      end
      push '='.ord
      env.reverse.each_char do |char|
        push char.ord
      end
    end
    push 0
    push 0
    ARGV.reverse.each do |arg|
      push 0
      arg.reverse.each_char do |char|
        push char.ord
      end
    end
    tempstackstack.reverse.each do |stack|
      push stack.length
    end
    push tempstackstack.length
    time = Time.now
    push (time.sec + time.min * 256 + time.hour * 256 * 256)
    push (time.day + time.month * 256 + (time.year-1900) * 256 * 256)
    push $prog[0].length-1; push $prog.length-1
    push -$origin[0]; push -$origin[1]
    push @storeoffset[0]; push @storeoffset[1]
    push @delta[0]; push @delta[1]
    push x-$origin[0]; push y-$origin[1]
    push 0
    push @id
    push @delta.length
    push File.join([' ', ' '])[1].ord
    push 0
    push 105
    push 1381320277
    push -1
    push 0b00001
    if num > 0
      value = @stackstack[-1][-num]
      @stackstack = tempstackstack.map {|i| i.clone}
      push value
    end
  end
  def parent
    @parent
  end
  def sleep
    @sleep
  end
  def sleep=(val)
    @sleep = val
  end
end