var jobs = new Vue({
  el: '#jobs',
  data: {
    jobs: [ ],
    paused: false,
    error: [ ],
  },

  methods: {
    refresh: function() {
      axios.get('/v1/jobs').then(response => {
          this.$set('jobs', response.data);
        }).catch(error => {
          this.$set('error', error);
        }
      );
    },

    view: function(job_id) {

    },

    delete: function(job_id) {
      axios.delete('/v1/jobs/' + job_id).then(response => {
          this.refresh();
        }).catch(error => {
          this.$set('error', error);
        }
      );
    },

    clear: function() {
      axios.delete('/v1/jobs').then(response => {
          this.refresh();
        }).catch(error => {
          this.$set('error', error);
        }
      );
    },

    pause: function() {
      axios.post('/v1/pause').then(response => {
          this.$set('paused', true);
        }).catch(error => {
          this.$set('error', error);
        }
      );
    },

    resume: function() {
      axios.post('/v1/resume').then(response => {
          this.$set('paused', false);
        }).catch(error => {
          this.$set('error', error);
        }
      );
    },
  },

  // hooks
  created: function() {
    this.refresh();
  },
});
