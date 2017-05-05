var jobs = new Vue({
  el: '#jobs',
  data: {
    jobs: [ ],
    errors: [ ]
  },

  created: function() {
  	console.log("requesting jobs");
    axios.get('/v1/jobs').then(response => {
        this.jobs = response.data;
      }).catch(error => {
        this.errors.push(error);
      }
    );
  },
});
