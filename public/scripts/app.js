var jobs = new Vue({
  el: '#jobs',
  data: {
    jobs: [ ],
    paused: false,
    error: false,
  },

  methods: {
    refresh: function() {
      axios.get('/v1/jobs').then(r => {
        this.$set('jobs', r.data);
      }).catch(e => {
        this.$set('error', e);
      });
    },

    view: function(job_id) {

    },

    delete: function(job_id) {
      axios.delete('/v1/jobs/' + job_id).then(r => {
        this.refresh();
      }).catch(e => {
        this.$set('error', e);
      });
    },

    clear: function() {
      axios.delete('/v1/jobs').then(r => {
        this.refresh();
      }).catch(e => {
        this.$set('error', e);
      });
    },

    pause: function() {
      axios.post('/v1/pause').then(r => {
        this.$set('paused', true);
      }).catch(e => {
        this.$set('error', e);
      });
    },

    resume: function() {
      axios.post('/v1/resume').then(r => {
        this.$set('paused', false);
      }).catch(e => {
        this.$set('error', e);
      });
    },

    pen_up: function() {
      axios.post('/v1/pen/up').then(r => {
        // nothing to do
      }).catch(e => {
        this.$set('error', e);
      });
    },

    pen_down: function() {
      axios.post('/v1/pen/down').then(r => {
        // nothing to do
      }).catch(e => {
        this.$set('error', e);
      });
    },
  },

  // hooks
  created: function() {
    this.refresh();
  },
});
