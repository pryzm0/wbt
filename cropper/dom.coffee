{ BaseCropper } = require './base'
concat = require 'concat-stream'
cheerio = require 'cheerio'
_ = require 'lodash'


##
# Utilize cheerio to extract documents.
#
class module.exports.DomCropper extends BaseCropper

  consume: (stream, task) ->
    stream.pipe concat (content) =>
      @extract (cheerio.load content), task
      @emit 'done'

  extract: ($, task) ->
    for extractor in _.toArray task.dom
      for doc in _.toArray (extractor $)
        @emit 'document', doc
    return
