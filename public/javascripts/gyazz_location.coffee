frac = (v) ->
  v - Math.floor v

val2loc = (v) -> # 35.5 => 35.30.0.0
  negative = v < 0
  v = Math.abs v
  deg = Math.floor v
  v = frac(v) * 60.0
  min = Math.floor v
  v = frac(v) * 60.0
  sec = Math.floor v
  v = frac(v) * 100.0
  sec2 = Math.floor v
  "#{ if negative then "-" else ''}#{deg}.#{min}.#{sec}.#{sec2}"

loc2val = (loc) ->  # '35.30.00.00' ⇒ 35.5
  negative = loc.match /^\-/
  a = loc.split /\./
  v = parseInt(a[0]) + parseInt(a[1])/60.0 +
  	parseInt(a[2])/60.0/60.0 + parseInt(a[3])/60.0/60.0/100.0
  if negative then -v else v

window.parseloc = (s) -> # 'E130.43.19.70N31.47.47.34Z2' => {130.7221, 31.79648, 2}
  o = 
    zoom: 1
    lat:  0.0
    lng: 0.0
  console.log o
  while a = s.match /^([EWNSZ])([1-9][0-9\.]*)(.*)$/
   	v = if a[2].match /\..*\./ then loc2val(a[2]) else parseFloat(a[2])
    switch a[1]
    	when 'E' then o.lng  = v
    	when 'W' then o.lng  = -v
    	when 'N' then o.lat  = v
    	when 'S' then o.lat  = -v
    	when 'Z' then o.zoom = v
    s = a[3]
  o

window.locstr = (o) -> # {130.7221, 31.79648, 2} => 'E130.43.19.70N31.47.47.34Z2'
  ew = if o.lng > 0 then  'E'+val2loc(o.lng) else 'W'+val2loc(-o.lng)
  ns = if o.lat > 0 then  'N'+val2loc(o.lat) else 'S'+val2loc(-o.lat)
  "#{ew}#{ns}Z#{o.zoom}"

# s = 'E130.43.19.70N31.47.47.34Z10';
# console.log s
# obj = parseloc(s);
# console.log obj.lng
# console.log obj.lat
# console.log obj.zoom
# console.log locstr(obj)
# 
# v = 35.12345
# console.log v
# s = val2loc v
# console.log s
# v = loc2val s
# console.log v



