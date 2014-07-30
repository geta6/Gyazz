#
# png.coffeのテスト
# どこかに移動すべき
#

fs  = require 'fs'
PNG = require './png'

png = new PNG

data = [
  [[0, 0, 0], [100, 100, 100], [200, 200, 200], [255, 255, 255]],
  [[0, 0, 0], [100, 100, 100], [200, 200, 200], [255, 255, 255]],
  [[0, 0, 0], [100, 100, 100], [200, 200, 200], [255, 255, 255]]
  ]

png.png data, (res) ->
  fs.writeFile 'coffee.png', res, { encoding:'ascii' }, (err) ->
    if err
      return
    console.log "saved"


