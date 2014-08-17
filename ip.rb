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
      # IPs inherit several values from their parents. In fact, the only thing it doesn't inherit is stringmode.
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
      # fingerhash is a hash containing currently loaded fingerprint instructions, and prevhash is a hash containing
      # previously loaded ones, for restoring.
      @prevhash = Hash[*('A'..'Z').to_a.zip([lambda {|ip| ip.delta = ip.delta.map {|i| -i}; puts "Unloaded instruction #{$prog[ip.y][ip.x].chr} encountered at #{[ip.x-$origin[0], ip.y-$origin[1]]}"}] * 26).flatten]
      @fingerhash = Hash[*('A'..'Z').to_a.zip([lambda {|ip| ip.delta = ip.delta.map {|i| -i}; puts "Unloaded instruction #{$prog[ip.y][ip.x].chr} encountered at #{[ip.x-$origin[0], ip.y-$origin[1]]}"}] * 26).flatten]
    end
    @stringmode = false
  end
  # Wrapping. The wrapping used by Befunge-98 is called same-line wrapping, or Lahey-Space wrapping.
  # If the edge of the file is reached, the IP reverses its direction and moves until another edge is reached.
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
      if @stackstack[-1] == []
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
  # Array of fingerprints.
  # Fingerprints are extensions to the Befunge-98 language.
  # TODO: This whole thing as one big literal is messy.
  FINGERPRINTS = {
                  # Fingerprint NULL: Sets all letters A-Z to reflect.
                  0x4e554c4c => Hash[*('A'..'Z').to_a.zip([lambda {|ip| ip.delta = ip.delta.map {|i| -i}}] * 26).flatten],
                  # Fingerprint BOOL: Boolean functions
                  0x424f4f4c => {
                                 # A pops two values and does a bitwise AND on them.
                                 'A' => lambda {|ip| ip.push(ip.pop & ip.pop)},
                                 # O pops two values and does a bitwise OR on them.
                                 'O' => lambda {|ip| ip.push(ip.pop | ip.pop)},
                                 # N pops one value and does a bitwise negation on it.
                                 'N' => lambda {|ip| ip.push(~ip.pop)},
                                 # X pops two values and does a bitwise XOR on them.
                                 'X' => lambda {|ip| ip.push(ip.pop ^ ip.pop)}},
                  # Fingerprint BASE: Base convertion
                  0x42415345 => {
                                 # B outputs the binary value of a popped number.
                                 'B' => lambda {|ip| print ip.pop.to_s(2) + ' '},
                                 # H outputs the hex value of a popped number.
                                 'H' => lambda {|ip| print ip.pop.to_s(16) + ' '},
                                 # I reads a number from input in a popped base.
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
                                                     # If an invalid base was entered, read base 1 normally or reflect if not base 1.
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
                                 # N outputs a popped value in a popped base.
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
                                 # O outputs a popped value in octal.
                                 'O' => lambda {|ip| print ip.pop.to_s(8) + ' '}},
                  # MODU fingerprint: Modulus instructions.
                  0x4d4f4455 => {
                                 # M does a normal modulus operation.
                                 'M' => lambda {|ip|
                                                a = ip.pop
                                                b = ip.pop
                                                if a == 0
                                                  ip.push 0
                                                else
                                                  ip.push b % a
                                                end},
                                 # R does normal modulus, except it ignores the right operand's sign.
                                 'R' => lambda {|ip|
                                                a = ip.pop
                                                b = ip.pop
                                                if a == 0
                                                  ip.push 0
                                                else
                                                  ip.push b > 0 ? (b % a.abs) : -(b % a.abs)
                                                end},
                                 # U does unsigned modulus.
                                 'U' => lambda {|ip|
                                                a = ip.pop
                                                b = ip.pop
                                                if a == 0
                                                  ip.push 0
                                                else
                                                  ip.push (b % a).abs
                                                end}},
                  # ROMA fingerprint: Roman numerals.
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
                  # MODE fingerprint: Standard modes.
                  0x4d4f4445 => {
                                 # H toggles hovermode. In hovermode, arrows accelerate the IP instead of changing
                                 # its direction.
                                 'H' => lambda {|ip|
                                                ip.hovermode = !(ip.hovermode)},
                                 # I toggles invertmode. In invertmode, values are pushed to the bottom of the stack.
                                 'I' => lambda {|ip|
                                                ip.invertmode = !(ip.invertmode)},
                                 # Q toggles queuemode. In queuemode, values are popped from the bottom of the stack.
                                 'Q' => lambda {|ip|
                                                ip.queuemode = !(ip.queuemode)},
                                 # S toggles switchmode. In switchmode, brackets, () [] {}, are switched to their
                                 # counterpart after execution.
                                 'S' => lambda {|ip|
                                                ip.switchmode = !(ip.switchmode)}},
                  # ORTH fingerprint: Instructions from the Orthogonal programming language.
                  0x4f525448 => {
                                 # A performs a bitwise AND.
                                 'A' => lambda {|ip|
                                                ip.push ip.pop & ip.pop},
                                 # E performs a bitwise XOR.
                                 'E' => lambda {|ip|
                                                ip.push ip.pop ^ ip.pop},
                                 # G works just like g, except the vector is popped in reverse order.
                                 'G' => lambda {|ip|
                                                x = ip.pop
                                                y = ip.pop
                                                ip.push $prog[y+$origin[1]+ip.storeoffset[1]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]]},
                                 # O performs a bitwise OR.
                                 'O' => lambda {|ip|
                                                ip.push ip.pop | ip.pop},
                                 # P works just like p, except the vector is popped in reverse order.
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
                                 # S outputs a null-terminated string (0"gnirts").
                                 'S' => lambda {|ip|
                                                a = ip.pop
                                                s = ''
                                                while a != 0
                                                  s += a < 0xffff ? a.chr('UTF-8') : ' '
                                                  a = ip.pop
                                                end
                                                print s
                                                $outbuffer += s},
                                 # V changes the X portion of the delta to a popped value.
                                 'V' => lambda {|ip|
                                                ip.delta[0] = ip.pop},
                                 # X changes the X coordinate of the IP to a popped value.
                                 'X' => lambda {|ip|
                                                ip.coords[0] = ip.pop+$origin[0]},
                                 # Z skips the next instruction if a popped value is 0.
                                 'Z' => lambda {|ip|
                                                if ip.pop == 0
                                                  ip.move $bounds
                                                end},
                                 # W changes the W portion of the delta to a popped value.
                                 'W' => lambda {|ip|
                                                ip.delta[1] = ip.pop},
                                 # Y changes the Y coordinate of the IP to a popped value.
                                 'Y' => lambda {|ip|
                                                ip.coords[1] = ip.pop+$origin[1]}},
                  # CPLI fingerprint: Complex integer math.
                  0x43504c49 => {
                                # A adds two popped complex integers.
                                'A' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1+c2).real; ip.push (c1+c2).imag},
                                # D divides two popped complex integers.
                                'D' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1/c2).real.to_i; ip.push (c1/c2).imag.to_i},
                                # M multiplies two popped complex integers.
                                'M' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1*c2).real.to_i; ip.push (c1*c2).imag.to_i},
                                # O outputs a complex integer.
                                'O' => lambda {|ip|
                                               b = ip.pop
                                               a = ip.pop
                                               print "#{Complex(a, b)} "
                                               $outbuffer += "#{Complex(a, b)} "},
                                # S subtracts two popped complex integers.
                                'S' => lambda {|ip|
                                                d = ip.pop
                                                c = ip.pop
                                                b = ip.pop
                                                a = ip.pop
                                                c1 = Complex(a, b)
                                                c2 = Complex(c, d)
                                                ip.push (c1-c2).real.to_i; ip.push (c1-c2).imag.to_i},
                                # V pushes the absolute value of a popped complex integer.
                                'V' => lambda {|ip|
                                                b = ip.pop
                                                a = ip.pop
                                                ip.push Complex(a, b).abs.to_i}},
                  # FIXP fingerprint: fixed point arithmetic.
                  0x46495850=> {
                                # A performs a bitwise AND.
                                'A' => lambda {|ip| ip.push ip.pop & ip.pop},
                                # B calculates the arc cosine of a popped value divided by 10000.
                                'B' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               begin
                                                 ip.push ((Math.acos(n) / (Math::PI / 180)) * 10000).round.to_i
                                               rescue ArgumentError
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                # C calculates the cosine of a popped value divided by 10000.
                                'C' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               n *= (Math::PI / 180)
                                               ip.push (Math.cos(n) * 10000).round.to_i},
                                # D pushes a random number between 0 and a popped value, or between -1 and a popped value
                                # if that value is negative.
                                'D' => lambda {|ip|
                                               n = ip.pop
                                               r = n >= 0 ? rand(0..n-1) : rand(n..-1)
                                               ip.push r},
                                # I calculates the sine of a popped number divided by 10000.
                                'I' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               n *= (Math::PI / 180)
                                               ip.push (Math.sin(n) * 10000).round.to_i},
                                # J calculates the arc sine of a popped number divided by 10000.
                                'J' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               begin
                                                 ip.push ((Math.asin(n) / (Math::PI / 180)) * 10000).round.to_i
                                               rescue Math::DomainError
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                # N negates a popped value.
                                'N' => lambda {|ip| ip.push -ip.pop},
                                # O performs a bitwise O.
                                'O' => lambda {|ip| ip.push ip.pop | ip.pop},
                                # P multiplies a value by pi.
                                'P' => lambda {|ip| ip.push (ip.pop * Math::PI).round.to_i},
                                # Q calculates the square root of a popped value.
                                'Q' => lambda {|ip|
                                               n = ip.pop
                                               if n < 0
                                                 ip.delta = ip.delta.map {|i| -i}
                                               else
                                                 ip.push (Math.sqrt n).round.to_i
                                               end},
                                # R raises a popped value to the power of another.
                                'R' => lambda {|ip|
                                               b = ip.pop
                                               a = ip.pop
                                               if a == 0 and b <= 0
                                                 ip.delta = ip.delta.map {|i| -i}
                                               else
                                                 ip.push (a ** b).round.to_i
                                               end},
                                # S pushes -1 if a popped value is lower than 0, else 0 if the value is 0, else 1.
                                'S' => lambda {|ip|
                                               n = ip.pop
                                               ip.push n <=> 0},
                                # T calculates the tangent of a popped value divided by 10000.
                                'T' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               n *= (Math::PI / 180)
                                               ip.push (Math.tan(n) * 10000).round.to_i},
                                # U calculates the arc tangent of a popped value divided by 10000.
                                'U' => lambda {|ip|
                                               n = ip.pop / 10000.0
                                               begin
                                                 ip.push ((Math.atan(n) / (Math::PI / 180)) * 10000).round.to_i
                                               rescue Math::DomainError
                                                 ip.delta = ip.delta.map {|i| -i}
                                               end},
                                # V pushes the absolute value of a popped number.
                                'V' => lambda {|ip| ip.push ip.pop.abs},
                                # X performs a bitwise XOR.
                                'X' => lambda {|ip| ip.push ip.pop ^ ip.pop}},
                  # IMTH fingerprint: integer math.
                  0x494d5448 =>{
                                # A pushes the avarage of a popped number of popped values.
                                'A' => lambda {|ip|
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
                                # B pushes the absolute value of a number.
                                'B' => lambda {|ip| ip.push ip.pop.abs},
                                # C pushes a number multiplied by 100.
                                'C' => lambda {|ip| ip.push ip.pop*100},
                                # D decrements a number towards 0.
                                'D' => lambda {|ip| a = ip.pop; ip.push (-(a <=> 0) + (a*(a<=>0)))},
                                # E pushes a number multiplied by 10000.
                                'E' => lambda {|ip| ip.push ip.pop*10000},
                                # F pushes the factorial of a popped number. Strangely, it pushes 0 if the number is 0.
                                # This is kept in for compatibility with other interpreters.
                                'F' => lambda {|ip| a = ip.pop; if a < 0; ip.delta = ip.delta.map {|i| -i}; else; ip.push (a == 0 ? 0 : factorial(a)); end},
                                # G pushes a number's sign; see FIXP:S.
                                'G' => lambda {|ip| a = ip.pop; ip.push a <=> 0},
                                # H pushes a number multiplied by 1000.
                                'H' => lambda {|ip| ip.push ip.pop*1000},
                                # I increments a number away from 0.
                                'I' => lambda {|ip| a = ip.pop; ip.push (a <=> 0 + (a * (a <=> 0)))},
                                # L performs a left shift.
                                'L' => lambda {|ip| c = ip.pop; a = ip.pop; ip.push a << c},
                                # N pushes the minimum value of a popped amount of popped values.
                                'N' => lambda {|ip|
                                               n = ip.pop
                                               if n <= 0; ip.delta = ip.delta.map {|i| -i}; else
                                                 arr = []
                                                 n.times do
                                                   arr << ip.pop
                                                 end
                                                 ip.push arr.min
                                               end},
                                # R performs a right shift.
                                'R' => lambda {|ip| c = ip.pop; ip.push ip.pop >> c},
                                # S pushes the sum of a popped number of popped values.
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
                                # T multiplies a value by 10.
                                'T' => lambda {|ip|
                                               ip.push ip.pop*10},
                                # U outputs the absolute value of a number.
                                'U' => lambda {|ip|
                                               print ip.pop.abs; print ' '},
                                # X pushes the maximum value of a popped amount of popped values.
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
                                # Z negates a popped value.
                                'Z' => lambda {|ip|
                                               ip.push -ip.pop}},
                  # IIPC fingerprint: Inter-IP communication.
                  0x49495043 =>{
                                # A pushes the ID of the IP's parent.
                                'A' => lambda {|ip| ip.push ip.parent},
                                # D puts the IP to sleep (dormancy), rendering it unable to move until another IP awakens it.
                                'D' => lambda {|ip| ip.sleep = true},
                                # G pushes a value popped from the stack of the IP with the popped ID, awakening that IP
                                # if it is asleep.
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
                                # I pushes the IP's ID.
                                'I' => lambda {|ip|
                                               ip.push ip.id},
                                # L pushes a value from the top of the stack of the IP with the popped ID. This does not
                                # awaken that IP.
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
                                # P pushes a popped value onto the stack of the IP with the popped ID, waking that IP up
                                # if it is asleep.
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
  # Pushes a bunch of system info to the stack for the 'y' instruction.
  #
  def sysinfo(num)
    tempstackstack = @stackstack.map {|i| i.clone}
    # Push environment variables to the stack, null-terminated.
    push 0
    # Make sure it gets pushed in alphabetical order.
    keys = ENV.keys.sort.reverse
    keys.each do |env|
      push 0
      ENV[env].reverse.each_char do |char|
        push char.ord
      end
      push '='.ord
      env.reverse.each_char do |char|
        push char.ord
      end
    end
    # Push command line arguments, double-null-terminated.
    push 0
    push 0
    ARGV.reverse.each do |arg|
      push 0
      arg.reverse.each_char do |char|
        push char.ord
      end
    end
    # Push lengths of stacks on the stack stack (before y started executing) in order from BOSS to TOSS.
    tempstackstack.reverse.each do |stack|
      push stack.length
    end
    # Length of the stack stack (amount of stacks)
    push tempstackstack.length
    time = Time.now
    # Time shenanigans
    push (time.sec + time.min * 256 + time.hour * 256 * 256)
    # Date shenanigans
    push (time.day + time.month * 256 + (time.year-1900) * 256 * 256)
    # Largest point in the program matrix.
    # TODO: Should be largest point that is not empty space.
    push $prog[0].length-1; push $prog.length-1
    # Least point in the program matrix.
    # TODO: Should be least point that is not empty space.
    push -$origin[0]; push -$origin[1]
    # Current storage offset.
    push @storeoffset[0]; push @storeoffset[1]
    # Current direction in Funge-Space.
    push @delta[0]; push @delta[1]
    # Current position in Funge-Space.
    push x-$origin[0]; push y-$origin[1]
    # IP team number; legacy, not important for this interpreter.
    push 0
    # IP's unique ID.
    push @id
    # Amount of dimensions. Obviously two.
    push @delta.length
    # Path separator.
    push File::SEPARATOR.ord
    # = instruction behaviour; 0 for unavailable.
    push 0
    # Interpreter version with dots omitted (v1.05)
    push 105
    # Interpreter handprint; RUFU encrypted.
    push 1381320277
    # Amount of bits per cell; functionally infinite (or very large), so -1 will do.
    push -1
    # Binary flags. Least significant one signifies concurrency (implemented),
    # Second least significant signifies file input (not implemented),
    # Third least significant signifies file output (not implemented),
    # Fourth least significant signifies unbuffered input (which is not in effect),
    # Most significant signifies = instruction (not implemented)
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