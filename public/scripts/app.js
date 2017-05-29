"use strict";

var weylandApp = angular.module('weylandApp', [ 'angularMoment', 'ui.bootstrap', 'bootstrap.fileField' ]);

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

weylandApp.controller('weylandJobsCtrl', function($scope, $log, $window, $http, $interval, $uibModal) {
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

  $scope.view = function(job) {
    $uibModal.open({
      animation: true,
      templateUrl: '/view',
      size: 'lg',
      controller: [ '$scope', 'uibButtonConfig', function($scope, buttonConfig) {
        buttonConfig.activeClass = 'btn-success';
        $scope.job = job;
        $scope.content_original = 'original';
        $scope.content_converted = 'converted';
        $scope.content_conversion_log = 'conversion_log';
        $scope.content_print_log = 'print_log';
        $scope.content_id = $scope.content_converted;
        $scope.have_content = function() {
          return $scope.content_body != undefined;
        };
        $scope.content_name = function(content_id) {
          switch (content_id) {
            case $scope.content_original: return 'Original File';
            case $scope.content_converted: return 'Converted File';
            case $scope.content_conversion_log: return 'Conversion Log';
            case $scope.content_print_log: return 'Print Log';
          }
          return 'Unknown Content Type';
        };
        $scope.is_image = function() {
          return $scope.content_id == $scope.content_original || $scope.content_id == $scope.content_converted;
        };
        $scope.download_link = function() {
          return '/v1/jobs/' + job.id + '/contents/' + $scope.content_id + '?download=true';
        };
      } ],
    }).result.then(angular.noop, angular.noop);
  };

  $scope.delete = function(job) {
    $http.delete('/v1/jobs/' + job.id).then(r => {
      $scope.refresh();
    });
  };

  $scope.print = function(job) {
    $http.post('/v1/jobs/' + job.id + '/print').then(r => {
      $scope.refresh();
    });
  };

  $scope.clear = function() {
    $http.delete('/v1/jobs').then(r => {
      $scope.refresh();
    });
  };

  $scope.upload = function() {
    $uibModal.open({
      animation: true,
      templateUrl: '/upload',
      size: 'lg',
      controller: function($scope) {
        $scope.name = undefined;
        $scope.file = undefined;
        $scope.convert = true;
        $scope.preview = undefined;

        $scope.updateName = function() {
          if (!angular.isDefined($scope.name)) {
            // only update the name if the user didn't explicitly override it
            // drop the .svg extension, if present
            $scope.name = $scope.file.name.replace('.svg', '');
          }
        };

        $scope.ok = function() {
          $scope.$close({ name: $scope.name, file: $scope.file, convert: $scope.convert });
        };
      }
    }).result.then(r => {
      var reader = new FileReader();
      reader.readAsBinaryString(r.file);
      reader.onloadend = function() {
        $http.post('/v1/jobs', { name: r.name, svg: reader.result, convert: r.convert }).then(r => {
          $scope.refresh();
        });
      }
    }, angular.noop);
  };

  $scope.refresh();
  $interval(function() {
    $scope.refresh()
  }, 5000);
});

weylandApp.filter('bytes', function() {
  return function(bytes, precision) {
    if (isNaN(parseFloat(bytes)) || !isFinite(bytes)) return '-';
    if (typeof precision === 'undefined') precision = 1;
    var units = ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB'],
      number = Math.floor(Math.log(bytes) / Math.log(1024));
    return (bytes / Math.pow(1024, Math.floor(number))).toFixed(precision) +  ' ' + units[number];
  }
});

weylandApp.directive('mycontent', function($http, $sce) {
  return {
    restrict: 'E',
    templateUrl: '/content',
    link: function(scope, element, attrs) {
      scope.$watchGroup([ 'job', 'content_id' ], function(newValues) {
        var job = newValues[0];
        var content_id = newValues[1];
        $http.get('/v1/jobs/' + job.id + '/contents/' + content_id).then(r => {
          // NOTE: This explicitly asserts that the content is safe. There be dragons...
          scope.content_body = $sce.trustAsHtml(r.data);
        }, err => {
          // got no content; the template will handle it
          scope.content_body = undefined;
        });
      });
    }
  };
});
