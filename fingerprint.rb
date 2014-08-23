class Fingerprint
  for str in 'A'..'Z'
    eval("attr_accessor :#{str}")
  end
  attr_accessor :id
  @@array = Array.new
  def initialize(id)
    @id = id
    @@array << self
  end
  def self.array
    @@array
  end
end

# Fingerprint NULL: Sets all instructions to reflect.
#
begin
  NULL = Fingerprint.new 0x4e554c4c
  ('A'..'Z').each do |letter|
    eval("NULL.#{letter} = lambda {|ip| ip.delta = ip.delta.map {|i| -i}}")
  end
end

# Fingerprint ROMA: Roman numerals.
#
begin
  ROMA = Fingerprint.new 0x524f4d41
  ROMA.I = lambda {|ip| ip.push 1}
  ROMA.V = lambda {|ip| ip.push 5}
  ROMA.X = lambda {|ip| ip.push 10}
  ROMA.L = lambda {|ip| ip.push 50}
  ROMA.C = lambda {|ip| ip.push 100}
  ROMA.D = lambda {|ip| ip.push 500}
  ROMA.M = lambda {|ip| ip.push 1000}
end

# Fingerprint BOOL: Boolean functions.
#
begin
  BOOL = Fingerprint.new 0x424f4f4c
  # A performs a bitwise AND on two popped operands.
  BOOL.A = lambda {|ip| ip.push(ip.pop & ip.pop)}
  # O performs a bitwise OR on two popped operands.
  BOOL.O = lambda {|ip| ip.push(ip.pop | ip.pop)}
  # N performs a bitwise negation on one popped operand.
  BOOL.N = lambda {|ip| ip.push(~ip.pop)}
  # X performs a bitwise XOR on two popped operands.
  BOOL.X = lambda {|ip| ip.push(ip.pop ^ ip.pop)}
end

# Fingerprint BASE: Base conversion.
#
begin
  BASE = Fingerprint.new 0x42415345
  # B outputs the binary value of a popped number.
  BASE.B = lambda {|ip| a = ip.pop.to_s(2) + ' '; print a; $outbuffer += a}
  # H outputs the hex value of a popped number.
  BASE.H = lambda {|ip| a = ip.pop.to_s(16) + ' '; print a; $outbuffer += a}
  # I reads a number from input in a popped base.
  BASE.I = lambda do |ip|
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
    end
  end
  # N outputs a popped value in a popped base.
  BASE.N = lambda do |ip|
    base = ip.pop
    begin
      a = ip.pop
      print a.to_s(base) + ' '
      $outbuffer += a.to_s(base) + ' '
    rescue ArgumentError
      if base == 1
        if a.to_s.include? '-'
          print "#{'-' + '0'*a.abs} "
          $outbuffer += "#{'-' + '0'*a.abs} "
        else
          print "#{'0'*a} "
          $outbuffer += "#{'0'*a} "
        end
      else
        ip.delta = ip.delta.map {|i| -i}
      end
    end
  end
  # O outputs the octal value of a popped number.
  BASE.O = lambda {|ip| a = ip.pop.to_s(8) + ' '; print a; $outbuffer += a}
end

# Fingerprint MODU: Modulus instructions.
#
begin
  MODU = Fingerprint.new 0x4d4f4455
  # M does a normal modulus.
  MODU.M = lambda do |ip|
    a = ip.pop
    b = ip.pop
    if a == 0
      ip.push 0
    else
      ip.push b % a
    end
  end
  # R does a normal modulus, except it retains the left operand's sign.
  MODU.R = lambda do |ip|
    a = ip.pop
    b = ip.pop
    if a == 0
      ip.push 0
    else
      ip.push b > 0 ? (b % a.abs) : -(b % a.abs)
    end
  end
  # U does an unsigned modulus.
  MODU.U = lambda do |ip|
    a = ip.pop
    b = ip.pop
    if a == 0
      ip.push 0
    else
      ip.push (b % a).abs
    end
  end
end

# Fingerprint MODE: Standard modes.
#
begin
  MODE = Fingerprint.new 0x4d4f4445
  # H toggles hovermode. In hovermode, arrows accelerate the IP instead of changing its direction.
  MODE.H = lambda {|ip| ip.hovermode = !(ip.hovermode)}
  # I toggles invertmode. In invertmode, values are pushed to the bottom of the stack.
  MODE.I = lambda {|ip| ip.invertmode = !(ip.invertmode)}
  # Q toggles queuemode. In queuemode, values are popped from the bottom of the stack.
  MODE.Q = lambda {|ip| ip.queuemode = !(ip.queuemode)}
  # S toggles switchmode. In switchmode, brackets - () [] {} - are switched to their counterpart after execution.
  MODE.S = lambda {|ip| ip.switchmode = !(ip.switchmode)}
end

# Fingerprint ORTH: Instructions from Orthogonal programming language
#
begin
  ORTH = Fingerprint.new 0x4f525448
  # A performs a bitwise AND on two popped operands.
  ORTH.A = lambda {|ip| ip.push ip.pop & ip.pop}
  # E performs a bitwise XOR on two popped operands.
  ORTH.E = lambda {|ip| ip.push ip.pop ^ ip.pop}
  # G works the same as g, but the x and y values are popped in reverse order.
  ORTH.G = lambda do |ip|
    x = ip.pop
    y = ip.pop
    ip.push $prog[y+$origin[1]+ip.storeoffset[1]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]]
  end
  # O performs a bitwise OR on two popped operands.
  ORTH.O = lambda {|ip| ip.push ip.pop | ip.pop}
  # P works the same as p, but the x and y values are popped in reverse order.
  ORTH.P = lambda do |ip|
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
    $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]] = c
  end
  # S outputs a null-terminated string (0"gnirts")
  ORTH.S = lambda do |ip|
    a = ip.pop
    s = ''
    while a != 0
      s += a < 0xffff ? a.chr('UTF-8') : ' '
      a = ip.pop
    end
    print s
    $outbuffer += s
  end
  # V changes the X portion of the delta to a popped value.
  ORTH.V = lambda {|ip| ip.delta[0] = ip.pop}
  # X changes the X coordinate of the IP to a popped value.
  ORTH.X = lambda {|ip| ip.x = ip.pop+$origin[0]}
  # Z skips the next instruction if a popped value is 0.
  ORTH.Z = lambda do |ip|
    if ip.pop == 0
      ip.move $bounds
    end
  end
  # W changes the Y portion of the delta to a popped value
  ORTH.W = lambda {|ip| ip.delta[1] = ip.pop}
  # Y changes the Y coordinate of the IP to a popped value.
  ORTH.Y = lambda {|ip| ip.y = ip.pop+$origin[1]}
end

# Fingerprint CPLI: complex integer math.
#
begin
  CPLI = Fingerprint.new 0x43504c49
  # A adds two popped complex integers.
  CPLI.A = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1+c2).real; ip.push (c1+c2).imag
  end
  # D divides two popped complex integers.
  CPLI.D = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1/c2).real.to_i; ip.push (c1/c2).imag.to_i
  end
  # M multiplies two popped complex integers.
  CPLI.M = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1*c2).real.to_i; ip.push (c1*c2).imag.to_i
  end
  # O outputs a complex integer.
  CPLI.O = lambda do |ip|
    b = ip.pop
    a = ip.pop
    print "#{Complex(a, b)} "
    $outbuffer += "#{Complex(a, b)} "
  end
  # S subtracts two popped complex integers.
  CPLI.S = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1-c2).real.to_i; ip.push (c1-c2).imag.to_i
  end
  # V pushes the absolute value of a complex integer.
  CPLI.V = lambda do |ip|
    b = ip.pop
    a = ip.pop
    ip.push Complex(a, b).abs.to_i
  end
end

# Fingerprint FIXP: Fixed-point math.
#
begin
  # Fixed-point numbers are represented in Funge-cells as integers 10000 times smaller than the number.
  FIXP = Fingerprint.new 0x46495850
  # A performs a bitwise AND on two popped operands
  FIXP.A = lambda {|ip| ip.push ip.pop & ip.pop}
  # B calculates the arc cosine of a popped fixed-point number.
  FIXP.B = lambda do |ip|
    n = ip.pop / 10000.0
    begin
      ip.push ((Math.acos(n) / (Math::PI / 180)) * 10000).round.to_i
    rescue ArgumentError
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # C calculates the cosine of a popped fixed-point number.
  FIXP.C = lambda do |ip|
    n = ip.pop / 10000.0
    n *= (Math::PI / 180)
    ip.push (Math.cos(n) * 10000).round.to_i
  end
  # D pushes a random number between 0 and a popped value, or between -1 and a popped value if that value is negative.
  FIXP.D = lambda do |ip|
    n = ip.pop
    r = n >= 0 ? rand(0..n-1) : rand(n..-1)
    ip.push r
  end
  # I calculates the sine of a popped fixed-point number.
  FIXP.I = lambda do |ip|
    n = ip.pop / 10000.0
    n *= (Math::PI / 180)
    ip.push (Math.sin(n) * 10000).round.to_i
  end
  # J calculates the arc sine of a popped fixed-point number.
  FIXP.J = lambda do |ip|
    n = ip.pop / 10000.0
    begin
      ip.push ((Math.asin(n) / (Math::PI / 180)) * 10000).round.to_i
    rescue Math::DomainError
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # N negates a popped number.
  FIXP.N = lambda {|ip| ip.push -ip.pop}
  # O performs a bitwise OR.
  FIXP.O = lambda {|ip| ip.push ip.pop | ip.pop}
  # P multiplies a number by pi.
  FIXP.P = lambda {|ip| ip.push (ip.pop * Math::PI).round.to_i}
  # Q calculates the square root of a popped number.
  FIXP.Q = lambda do |ip|
    n = ip.pop
    if n < 0
      ip.delta = ip.delta.map {|i| -i}
    else
      ip.push (Math.sqrt n).round.to_i
    end
  end
  # R raises a popped value to the power of another.
  FIXP.R = lambda do |ip|
    b = ip.pop
    a = ip.pop
    if a == 0 and b <= 0
      ip.delta = ip.delta.map {|i| -i}
    else
      ip.push (a ** b).round.to_i
    end
  end
  # S pushes the sign of a popped number
  FIXP.S = lambda {|ip| ip.push ip.pop <=> 0}
  # T calculates the tangent of a popped fixed-point number.
  FIXP.T = lambda do |ip|
    n = ip.pop / 10000.0
    n *= (Math::PI / 180)
    ip.push (Math.tan(n) * 10000).round.to_i
  end
  # U calculates the arc tangent of a popped fixed-point number.
  FIXP.U = lambda do |ip|
    n = ip.pop / 10000.0
    begin
      ip.push ((Math.atan(n) / (Math::PI / 180)) * 10000).round.to_i
    rescue Math::DomainError
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # V pushes the absolute value of a popped number.
  FIXP.V = lambda {|ip| ip.push ip.pop.abs}
  # X performs a bitwise XOR.
  FIXP.X = lambda {|ip| ip.push ip.pop ^ ip.pop}
end

# Fingerprint IMTH: integer math.
#
begin
  class Array
    def sum
      inject(:+).to_f
    end

    def average
      sum / size
    end
  end
  IMTH = Fingerprint.new 0x494d5448
  # A calculates the avarage of a popped amount of popped numbers.
  IMTH.A = lambda do |ip|
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
    end
  end
  # B pushes the absolute value of a number.
  IMTH.B = lambda {|ip| ip.push ip.pop.abs}
  # C pushes a number multiplied by 100.
  IMTH.C = lambda {|ip| ip.push 100*ip.pop}
  # D decrements a number towards 0.
  IMTH.D = lambda {|ip| a = ip.pop; ip.push a - (a<=>0)}
  # E pushes a number multiplied by 10000.
  IMTH.E = lambda {|ip| ip.push 10000*ip.pop}
  # F pushes the factorial of a popped number. Strangely, it pushes 0 if the number is 0.
  # This is kept in for compatibility with other interpreters.
  IMTH.F = lambda do |ip|
    a = ip.pop
    if a < 0
      ip.delta = ip.delta.map {|i| -i}
    else
      ip.push (a == 0 ? 0 : (1..a).to_a.inject(:*))
    end
  end
  # G pushes a number's sign.
  IMTH.G = lambda {|ip| ip.push ip.pop<=>0}
  # H pushes a number multiplied by 1000.
  IMTH.H = lambda {|ip| ip.push 1000*ip.pop}
  # I increments a number away from 0.
  IMTH.I = lambda {|ip| a = ip.pop; ip.push a + (a <=> 0)}
  # L performs a left shift.
  IMTH.L = lambda {|ip| c = ip.pop; a = ip.pop; ip.push a << c}
  # N pushes the minimum value of a popped amount of popped values.
  IMTH.N = lambda do |ip|
    n = ip.pop
    if n <= 0
      ip.delta = ip.delta.map {|i| -i}
    else
      arr = []
      n.times do
        arr << ip.pop
      end
      ip.push arr.min
    end
  end
  # R performs a right shift.
  IMTH.R = lambda {|ip| c = ip.pop; ip.push ip.pop >> c}
  # S pushes the sum of a popped number of popped values.
  IMTH.S = lambda do |ip|
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
      ip.push arr.sum.to_i
    end
  end
  # T pushes a value multiplied by 10.
  IMTH.T = lambda {|ip| ip.push 10*ip.pop}
  # U outputs the absolute value of a number.
  IMTH.U = lambda {|ip| print "#{ip.pop.abs} "}
  # X pushes the maximum value of a popped amount of popped values.
  IMTH.X = lambda do |ip|
    n = ip.pop
    if n <= 0
      ip.delta = ip.delta.map {|i| -i}
    else
      arr = []
      n.times do
        arr << ip.pop
      end
      ip.push arr.max
    end
  end
  # Z negates a popped number.
  IMTH.Z = lambda {|ip| ip.push -ip.pop}
end

# IIPC fingerprint: Inter-IP communication.
#
begin
  IIPC = Fingerprint.new 0x49495043
  # A pushes the IP's parent's ID.
  IIPC.A = lambda {|ip| ip.push ip.parent}
  # D puts the IP to sleep (dormancy), rendering it unable to move until another IP awakens it.
  IIPC.D = lambda {|ip| ip.sleep = true}
  # G pushes a value popped from the stack of the IP with the popped ID, awakening that IP if it is asleep.
  IIPC.G = lambda do |ip|
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
    end
  end
  # I pushes the IP's ID.
  IIPC.I = lambda {|ip| ip.push ip.id}
  # L pushes a value from the top of the stack of the IP with the popped ID. This does not awaken that IP.
  IIPC.L = lambda do |ip|
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
    end
  end
  # P pushes a popped value onto the stack of the IP with the popped ID, waking that IP up if it is asleep.
  IIPC.P = lambda do |ip|
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
    end
  end
end
