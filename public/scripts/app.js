var jobs = new Vue({
  el: '#jobs',
  data: {
    jobs: [ ],
    error: [ ]
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
          refresh();
        }).catch(error => {
          this.$set('error', error);
        }
      );
    },

    clear: function() {
      axios.delete('/v1/jobs').then(response => {
          refresh();
        }).catch(error => {
          this.$set('error', error);
        }
      );
    }
  },

  // hooks
  created: function() {
    refresh();
  },
});
