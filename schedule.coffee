url = require 'url'
_ = require 'lodash'

# ===========================================================================

##
# All incoming tasks are put to the frontier immediately.
#
module.exports.Direct = (put) -> (task) -> put task

# ===========================================================================

##
# Delay random amount of time before putting task to the frontier.
#
module.exports.RandomDelay = (minTime, maxTime) -> (put) -> (task) ->
  amount = Math.round minTime + (maxTime - minTime) * Math.random()
  _.delay (-> put task), amount

# ===========================================================================

##
# Limit put rate by timeout and task's target host.
#
module.exports.TimeoutThrottle = (timeout=1000) -> (put) ->
  startQueue = ->
    queue = []

    next = _.throttle ->
      run() if run = queue.shift()
      next() if queue.length > 0
    , timeout

    (run) ->
      queue.push(run)
      next()

  queueByHost = {}

  (task) ->
    host = (url.parse task.target).host
    queue = (queueByHost[host] ?= startQueue())
    queue -> (put task)
