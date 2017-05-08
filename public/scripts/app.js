"use strict";

var weylandApp = angular.module('weylandApp', [ ]);

weylandApp.controller('weylandPrinterCtrl', function($scope, $http) {
  $scope.loading = false;
  $scope.printer_version = undefined;

  $scope.get_version = function() {
    $scope.loading = true;
    $http.get('/v1/printer/version').then(r => {
      $scope.printer_version = r.data.version;
    }, e => {
      $scope.printer_version = undefined;
    }).finally(function() {
      $scope.loading = false;
    });
  };

  $scope.pen_up = function() {
    $http.post('/v1/printer/pen/up').then(r => {
      // nothing to do
    });
  };

  $scope.pen_down = function() {
    $http.post('/v1/printer/pen/down').then(r => {
      // nothing to do
    });
  };

  $scope.get_version();
});

weylandApp.controller('weylandJobsCtrl', function($scope, $window, $http, $interval) {
  $scope.loading = false;
  $scope.jobs = [ ];

  $scope.refresh = function() {
    $scope.loading = true;
    $http.get('/v1/jobs').then(r => {
      $scope.jobs = r.data;
    }, e => {
      $scope.jobs = [ ];
    }).finally(function() {
      $scope.loading = false;
    });
  };

  $scope.view = function(job_id) {
    $window.open('/v1/jobs/' + job_id + '/content', "popup", "width=600,height=400,left=100,top=100");
  };

  $scope.delete = function(job_id) {
    $http.delete('/v1/jobs/' + job_id).then(r => {
      $scope.refresh();
    });
  };

  $scope.print = function(job_id) {
    $http.post('/v1/jobs/' + job_id + '/print').then(r => {
      $scope.refresh();
    });
  };

  $scope.is_printable = function(status) {
    return status == 'pending' || status == 'printed' || status == 'failed';
  };

  $scope.clear = function() {
    $http.delete('/v1/jobs').then(r => {
      $scope.refresh();
    });
  };

  $scope.refresh();
  $interval(function() {
    $scope.refresh()
  }, 5000);
});
