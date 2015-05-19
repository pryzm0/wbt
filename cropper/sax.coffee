{ BaseCropper } = require './base'
htmlparser = require 'htmlparser2'
_ = require 'lodash'


##
# SAX parser writeable stream.
#
# @fires SaxFilter#document
#
class module.exports.SaxFilter extends htmlparser.Stream

  constructor: (task) ->
    super {
      lowerCaseTags: true
      lowerCaseAttributeNames: true
    }

    @initEvents(task)

  initEvents: (task) ->
    for filter in _.toArray task.filters
      filter(this)
    return

  emitDocument: (doc) ->
    @emit 'document', doc


##
# Utilize htmlstream2 SAX-parser to extract documents.
#
class module.exports.SaxCropper extends BaseCropper

  consume: (stream, task) ->
    filter = @_createFilterStream(task)

    filter.on 'document', (doc) =>
      @emit 'document', doc

    filter.on 'finish', =>
      @emit 'done'

    stream.pipe filter

  _createFilterStream: (task) ->
    return new module.exports.SaxFilter(task)
