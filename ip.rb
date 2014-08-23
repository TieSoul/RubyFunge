require_relative 'fingerprint'

class BefungeIP
  attr_accessor :id, :parent, :delta, :coords, :stackstack, :storeoffset, :prevhash, :fingerhash, :parent, :hovermode, :switchmode, :stringmode, :queuemode, :invertmode, :sleep
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
  # Fingerprint loading.
  def load(val)
    fing = Fingerprint.array.detect {|fing| fing.id == val}
    if fing.class != Fingerprint
      @delta = @delta.map {|i| -i}
    else
      (:@A..:@Z).to_a.each do |letter|
        if fing.instance_variable_defined? letter
          @prevhash[letter.to_s[-1]] = @fingerhash[letter.to_s[-1]].clone
          @fingerhash[letter.to_s[-1]] = fing.instance_variable_get letter
        end
      end
      push val
      push 1
    end
  end
  # Fingerprint unloading.
  def unload(val)
    fing = Fingerprint.array.detect {|fing| fing.id == val}
    if fing.class != Fingerprint
      @delta = @delta.map {|i| -i}
    else
      (:@A..:@Z).to_a.each do |letter|
        if fing.instance_variable_defined? letter
          letter = letter.to_s[-1]
          @fingerhash[letter] = @prevhash[letter].clone
          @prevhash[letter] = lambda {|ip| ip.delta = ip.delta.map {|i| -i}; puts "Unloaded instruction #{$prog[ip.y][ip.x].chr} encountered at #{[ip.x-$origin[0], ip.y-$origin[1]]}"}
        end
      end
    end
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
end