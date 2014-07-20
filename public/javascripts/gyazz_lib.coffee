hex2 = (v) ->
  v = Math.floor(v)
  v = 255 if v >= 256
  ("0" + v.toString(16)).slice(-2)

