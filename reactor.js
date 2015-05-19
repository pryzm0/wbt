'use strict';

const csp = require('js-csp');
const Q = require('q');
const _ = require('lodash');

const MINBUFFER = 5;
const MAXACTIVE = 10;


module.exports = function (induct, scheduler) {
  return Q.Promise(function (resolve) {
    csp.takeAsync(reactor(induct, scheduler), resolve);
  });
};


function reactor(induct, scheduler) {

  /** Channel of ready-to-run task configs. */
  let frontier = csp.chan(500);

  /** Total number of waiting task configs. */
  let inactiveCount = 0;

  /** Running tasks. */
  let active = [];

  /** Scheduler function for putting tasks to frontier. */
  let schedule = scheduler(function (task) {
    csp.putAsync(frontier, task);
  });


  function alts() {
    return active.length < MAXACTIVE
      ? csp.alts([frontier].concat(active))
      : csp.alts(active);
  }

  function register(task) {
    inactiveCount++;
    schedule(task);
  }

  function drain() {
    if (inactiveCount <= 0) {
      frontier.close();
    }
    return csp.take(frontier);
  }

  /**
   * Register inducted tasks in frontier.
   */
  let acceptChan = csp.chan();
  function accept(value) {
    induct(value.task, value.doc)
      .then(function (tasks) {
        if (_.isArray(tasks)) {
          tasks.forEach(register);
        }
      }).fin(function () {
        csp.putAsync(acceptChan, false);
      });
    return csp.take(acceptChan);
  }

  /**
   * Initiate page fetch by agent and stream page content
   * to number of document croppers. Put all cropped
   * documents to result channel. Close channel on end.
   */
  function activate(task) {
    let ch = csp.chan(task.buffer || (MINBUFFER * task.croppers.length));
    let stream = task.agent.fetch(task.target);

    inactiveCount--;
    active.push(ch);

    let ends = _.map(task.croppers, function (Cropper) {
      let cropper = new Cropper();

      cropper.consume(stream, task);

      cropper.on('document', function (doc) {
        csp.putAsync(ch, {
          task: task,
          doc: doc
        });
      });

      return Q.Promise(function (resolve) {
        cropper.on('done', resolve);
      });
    });

    Q.all(ends).then(function () {
      ch.close();
    });
  }

  function terminate(ch) {
    active = _.without(active, ch);
  }

  return csp.go(function*() {

    yield accept({ task: 'initial' });

    do {
      if (!active.length) {
        let task = yield drain();
        if (task === csp.CLOSED) {
          break;
        }
        activate(task);
      }

      let alt = yield alts();

      alt.channel === frontier
        ? activate(alt.value)
        : alt.value !== csp.CLOSED
          ? yield accept(alt.value)
          : terminate(alt.channel);

    } while (true);
  });
}
