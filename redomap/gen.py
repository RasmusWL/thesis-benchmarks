#!/usr/bin/env python2

def wraps(base):
    res = ",".join(base)
    if len(base) > 1:
        res = "(" + res + ")"
    return res

def wrap(base, n=1):
    res = ",".join([base] * n)
    if n > 1:
        res = "(" + res + ")"
    return res

################################################################################

# Intensive

intensive_segreduce_fmt = """
import "futlib/math"

fun redop (x:f32) (y:f32) : f32 =
  {redop_body}

entry main (xss : [m][n]f32) : [m]f32 =
  map (\\xs -> {reduce} redop 0.0f32 xs) xss
"""

def intensive__(fmt, comm, n):
    op = '+' if comm else '-'

    redop_body = ''
    if n == 0:
        redop_body += 'let foo = 0\n'
    for i in range(n):
        redop_body += 'let xx = x*x\n'
        redop_body += 'let x = f32.sqrt(xx)\n'
        redop_body += '\n'

    redop_body += 'in ' + 'x' + op + 'y'

    reduce = 'reduceComm' if comm else 'reduce'

    return fmt.format(**locals())

intensive_loopinmap_fmt = """
import "futlib/math"

fun redop (x:f32) (y:f32) : f32 =
  {redop_body}

entry main (xss : [m][n]f32) : [m]f32 =
  if m < 64
  then replicate (m) 0.0f32
  else
  map (\\xs ->
         loop (acc = 0.0f32) = for i < n do
              redop acc xs[i]
         in acc
      ) xss
"""



intensive_reduce_fmt = """
import "futlib/math"

fun redop (x:f32) (y:f32) : f32 =
  {redop_body}

entry main (xs : [n]f32) : f32 =
  {reduce} redop 0.0f32 xs

"""

def intensive_segreduce(comm, n):
    return intensive__(intensive_segreduce_fmt, comm, n)

def intensive_loopinmap(n):
    return intensive__(intensive_loopinmap_fmt, True, n)

def intensive_reduce(comm, n):
    return intensive__(intensive_reduce_fmt, comm, n)

for n in range(0, 8):
    for comm in (True, False):
        name = 'intensive-seg-' + ('comm' if comm else 'nocomm') + '-' + str(n) + '.fut'
        with open(name, 'w') as outfile:
            outfile.write( intensive_segreduce(comm, n) )

        name = 'intensive-loop-' + str(n) + '.fut'
        with open(name, 'w') as outfile:
            outfile.write( intensive_loopinmap(n) )

        name = 'intensive-1d-' + ('comm' if comm else 'nocomm') + '-' + str(n) + '.fut'
        with open(name, 'w') as outfile:
            outfile.write( intensive_reduce(comm, n) )

################################################################################

# Map-part output

# Multituple reduce

multituple_segreduce_fmt = """
fun f (x : f32) : {f_out} =
  {f_body}

fun redop ({red_in1}) ({red_in2}) : {red_out} =
  {redop_body}

entry main (xss : [m][n]f32) : {main_out} =
  {unzip} ( map (\\xs -> {reduce} redop {ne} (map f xs)) xss )
"""

def multituple_segreduce(comm, n):
    f_out = wrap('f32', n)
    red_out = f_out
    main_out = wrap('[m]f32', n)

    foo = []
    for i in range(n):
        foo.append('x+'+str(i+1)+'.0f32')
    f_body = wraps(foo)

    op = '+' if comm else '-'

    in1 = []
    in2 = []
    red_body = []
    for i in range(n):
        in1.append('x'+str(i) + ':f32')
        in2.append('y'+str(i) + ':f32')
        red_body.append( 'x'+str(i) +op+ 'y'+str(i) )
    red_in1 = ','.join(in1)
    red_in2 = ','.join(in2)
    redop_body = wraps(red_body)

    reduce = 'reduceComm' if comm else 'reduce'

    unzip = 'unzip' if n > 1 else ''

    ne = wrap('0.0f32', n)

    return multituple_segreduce_fmt.format(**locals())

################################################################################

multituple_loopinmap_fmt = """
fun f (x : f32) : {f_out} =
  {f_body}

fun redop ({red_in1}) ({red_in2}) : {red_out} =
  {redop_body}

entry main (xss : [m][n]f32) : {main_out} =
  {unzip} (
  if m < 64
  then replicate (m) {ne}
  else
  map (\\xs ->
         loop ({acc} = {ne}) = for i < n do
              redop {acc} (f xs[i])
         in {acc}
      ) xss
  )
"""

def multituple_loopinmap(n):
    f_out = wrap('f32', n)
    red_out = f_out
    main_out = wrap('[m]f32', n)

    foo = []
    for i in range(n):
        foo.append('x+'+str(i+1)+'.0f32')
    f_body = wraps(foo)

    op = '+'

    in1 = []
    in2 = []
    red_body = []
    acc_ = []
    for i in range(n):
        in1.append('x'+str(i) + ':f32')
        in2.append('y'+str(i) + ':f32')
        red_body.append( 'x'+str(i) +op+ 'y'+str(i) )
        acc_.append('x'+str(i))
    red_in1 = ','.join(in1)
    red_in2 = ','.join(in2)
    redop_body = wraps(red_body)
    acc = wraps(acc_)

    unzip = 'unzip' if n > 1 else ''

    ne = wrap('0.0f32', n)

    return multituple_loopinmap_fmt.format(**locals())

################################################################################

multituple_reduce_fmt = """
fun f (x : f32) : {f_out} =
  {f_body}

fun redop ({red_in1}) ({red_in2}) : {red_out} =
  {redop_body}

entry main (xs : [n]f32) : {main_out} =
  {reduce} redop {ne} (map f xs)
"""

def multituple_reduce(comm, n):
    f_out = wrap('f32', n)
    red_out = f_out
    main_out = f_out

    foo = []
    for i in range(n):
        foo.append('x+'+str(i+1)+'.0f32')
    f_body = wraps(foo)

    op = '+' if comm else '-'

    in1 = []
    in2 = []
    red_body = []
    for i in range(n):
        in1.append('x'+str(i) + ':f32')
        in2.append('y'+str(i) + ':f32')
        red_body.append( 'x'+str(i) +op+ 'y'+str(i) )
    red_in1 = ','.join(in1)
    red_in2 = ','.join(in2)
    redop_body = wraps(red_body)

    reduce = 'reduceComm' if comm else 'reduce'

    ne = wrap('0.0f32', n)

    return multituple_reduce_fmt.format(**locals())

for n in range(1, 8):
    for comm in (True, False):
        name = 'multi-seg-' + ('comm' if comm else 'nocomm') + '-' + str(n) + '.fut'
        with open(name, 'w') as outfile:
            outfile.write( multituple_segreduce(comm, n) )

        # Bug prevents us from using this right now
        # if n < 5:
        #     name = 'multi-loop-' + str(n) + '.fut'
        #     with open(name, 'w') as outfile:
        #         outfile.write( multituple_loopinmap(n) )

        name = 'multi-1d-' + ('comm' if comm else 'nocomm') + '-' + str(n) + '.fut'
        with open(name, 'w') as outfile:
            outfile.write( multituple_reduce(comm, n) )

# Multituple input
