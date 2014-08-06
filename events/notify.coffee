#
# webhookによるPage更新通知
#

debug    = require('debug')('gyazz:events:notify')
mongoose = require 'mongoose'
request  = require 'request'

Page  = mongoose.model 'Page'

module.exports = (app) ->

  app.on 'page saved', (page) ->
    Page.findByName page.wiki, ".通知", {}, (err, notify_page) ->
      if err
        debug "get #{wiki}::.通知 Error - #{err}"
        return
      if notify_page
        for url in notify_page.text.split(/[\r\n]+/)
          do (url) ->
            url = url.trim()
            unless /^https?:\/\/.+/.test url
              return
            request
              url: url
              method: 'POST'
              json:
                url: process.env.GYAZZ_URL?.replace(/\/$/,'')
                wiki: page.wiki
                title: page.title
                text: page.text
                timestamp: Math.floor(page.timestamp/1000)
            , (err, res, body) ->
              if err
                debug "#{url} notify Error - #{err}"
                return
              debug "#{url} notify success"
