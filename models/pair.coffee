#
# リンク情報
#

debug    = require('debug')('gyazz:pair')
_        = require 'underscore'
mongoose = require 'mongoose'
async    = require 'async'

module.exports = (app) ->

  pairSchema = new mongoose.Schema
    wiki: String
    title1: String
    title2: String

  # pageに関連するページの配列を得る
  pairSchema.statics.related = (wiki, title, callback) ->
    debug "Pair.related"
    e = false
    related = {}
    @find {wiki:wiki, title1:title}, (err, results) =>
      e ||= err
      for pair in results
        related[pair.title2] = 1
      @find {wiki:wiki, title2:title}, (err, results) ->
        e ||= err
        for pair in results
          related[pair.title1] = 1
        
        callback e, _.keys(related)

  # あるページに関連するpairを全部消す
  pairSchema.statics.remove = (wiki, title) ->
    debug "Pair.remove"
    console.log "remove #{wiki}, #{title}"
    #
    # 何故か@remove が使えない
    # @remove {wiki:wiki, title1:title}, (err) ->
    #
    @find {wiki:wiki, title1:title}, (err, results) ->
      results.forEach (result) ->
        result.remove()
    @find {wiki:wiki, title2:title}, (err, results) ->
      results.forEach (result) ->
        result.remove()

  # # あるページに関連するpairを登録する
  pairSchema.statics.add = (wiki, title, relatedtitles) ->
    debug "Pair.add"
    relatedtitles.forEach (relatedtitle) =>
      console.log "wiki=#{wiki}, title1=#{title}, reelatedtitle=#{relatedtitle}"
      @update
        wiki:   wiki
        title1: title
        title2: relatedtitle
      , (err) ->
        if err
          console.log "Pair write error"
        else
          console.log "UPDATE SUCCESS"

  pairSchema.statics.refresh = (wiki, title, relatedtitles) ->
    console.log "remove #{wiki}, #{title}, related = #{relatedtitles}"
    @find {wiki:wiki, title1:title}, (err, results) =>
      removeentries = results.map (result) -> result.title2
      #@find {wiki:wiki, title2:title}, (err, results) =>
      #  removeentries = removeentries.concat results.map (result) -> result.title1
      console.log "removeentries = #{removeentries}----"
      removeentries = removeentries.filter (e) ->
        ! (e in relatedtitles)
      removeentries.forEach (e) =>
        @find {wiki:wiki, title1:title, title2:e}, (err, results) ->
          results.forEach (result) =>
            console.log "========removing unused entry #{title}, #{e}"
            result.remove (err) ->
              console.log "remove fail" if err
        #@find {wiki:wiki, title1:e, title2:title}, (err, results) ->
        #  results.forEach (result) =>
        #    console.log "========removing unused entry #{e}, #{title}"
        #    result.remove (err) ->
        #      console.log "remove fail" if err

        #removeentries.map (entry) =>
        #  pair = new @
        #  pair.wiki =   wiki
        #  pair.title1 = title
        #  pair.title2 = entry
        #  pair.remove (err) ->
        #    if err
        #      console.log "Pair write error"
        #    else
        #      console.log "REMOVE SUCCESS"
        #  pair = new @
        #  pair.wiki =   wiki
        #  pair.title1 = entry
        #  pair.title2 = title
        #  pair.remove (err) ->
        #    if err
        #      console.log "Pair write error"
        #    else
        #      console.log "REMOVE SUCCESS"
        
    relatedtitles.forEach (relatedtitle) =>
      #@find {wiki:wiki, title1:relatedtitle, title2:title}, (err, results) ->
      #  results.forEach (result) =>
      #    console.log "========removing entry #{relatedtitle}, #{title}"
      #    result.remove (err) ->
      #      console.log "remove fail" if err

      pair = new @
      pair.wiki =   wiki
      pair.title1 = title
      pair.title2 = relatedtitle
      console.log "wiki=#{wiki}, title1=#{title}, reelatedtitle=#{relatedtitle}"
      @find {wiki:wiki, title1:title, title2:relatedtitle}, (err, results) ->
        if results[0]
          result = results[0]
          console.log "result = #{result}"
          console.log "========removing entry #{relatedtitle}, #{title} for update"
          result.remove (err) ->
            if (err)
              console.log "result.remove error"
            pair.save (err) ->
              if err
                console.log "Pair SAVE error"
              else
                console.log "UPDATE SUCCESS"
        else
          pair.save (err) ->
            if err
              console.log "Pair update error"
            else
              console.log "UPDATE SUCCESS"
                
      #pair = new @
      #pair.wiki =   wiki
      #pair.title1 = title
      #pair.title2 = relatedtitle
      #pair.save (err) ->
      #  if err
      #    console.log "Pair write error"
      #  else
      #    console.log "UPDATE SUCCESS"

    #
    # 何故か@remove が使えない
    # @remove {wiki:wiki, title1:title}, (err) ->
    #
    # @find {wiki:wiki, title1:title}, (err, results) =>
    #   removeentries = results.map (result) -> [title, result.title2]
    #   @find {wiki:wiki, title2:title}, (err, results) =>
    #     removeentries = removeentries.concat results.map (result) -> [result.title1, title]
    #     console.log "Register!!! removeentries = #{removeentries} newentries = #{relatedtitles}"
    #     if removeentries.length == 0
    #       console.log "Pair.add"
    #       relatedtitles.forEach (relatedtitle) =>
    #         console.log "Update: wiki=#{wiki}, title1=#{title}, relatedtitle=#{relatedtitle}"
    #         @update
    #           wiki:   wiki
    #           title1: title
    #           title2: relatedtitle
    #         , (err) ->
    #           if err
    #             console.log "Pair write error"
    #           else
    #             console.log "UPDATE SUCCESS"
    #     else
    #       async.parallel removeentries.map (pair) =>
    #         (callback) =>
    #           console.log "========remove #{pair[0]}, #{pair[1]}"
    #           @find {wiki:wiki, title1: pair[0], title2: pair[1]}, (err, results) ->
    #             console.log "========removing entry #{pair[0]}, #{pair[1]}"
    #             results[0].remove
    #       , (err, results) =>
    #         if err
    #           console.log "REMOVE ERROR"
    #         console.log "remove entries"
    #         console.log "Pair.add"
    #         relatedtitles.forEach (relatedtitle) =>
    #           console.log "wiki=#{wiki}, title1=#{title}, reelatedtitle=#{relatedtitle}"
    #           @update
    #             wiki:   wiki
    #             title1: title
    #             title2: relatedtitle
    #           , (err) ->
    #             if err
    #               console.log "Pair write error"
    #             else
    #               console.log "UPDATE SUCCESS"

  mongoose.model 'Pair', pairSchema
