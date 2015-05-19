EventEmitter = (require 'events').EventEmitter

##
# Consume input stream considering given environment
# and emit cropped documents. Signal on done.
#
# @fires BaseCropper#document
# @fires BaseCropper#done
#
class module.exports.BaseCropper extends EventEmitter

  consume: (stream, task) ->
