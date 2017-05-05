var jobs = new Vue({
  el: '#jobs',
  data: {
    jobs: false,
    error: false
  },

  ready: function() {
  	console.log("requesting jobs");
    this.$http({ url: '/api/jobs', method: 'GET' }).then(
      function success(response) {
        this.$set('jobs', response.data);
      },
      function failure(response) {
        this.$set('error', true);
      }
    );
  },
})
