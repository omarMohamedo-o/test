var app = angular.module('catsvsdogs', []);
var socket = io.connect();

var bg1 = document.getElementById('background-stats-1');
var bg2 = document.getElementById('background-stats-2');

app.controller('statsCtrl', function ($scope) {
  $scope.aPercent = 50;
  $scope.bPercent = 50;
  $scope.total = 0;
  var firstScoreReceived = false;

  // Register socket listener ONCE
  socket.on('scores', function (json) {
    console.log('Received scores:', json);
    data = JSON.parse(json);
    var a = parseInt(data.a || 0);
    var b = parseInt(data.b || 0);

    var percentages = getPercentages(a, b);

    bg1.style.width = percentages.a + "%";
    bg2.style.width = percentages.b + "%";

    $scope.$apply(function () {
      $scope.aPercent = percentages.a;
      $scope.bPercent = percentages.b;
      $scope.total = a + b;
    });

    // Make page visible after receiving first score
    if (!firstScoreReceived) {
      console.log('First score received, showing page');
      document.body.style.opacity = 1;
      firstScoreReceived = true;
    }
  });

  // Fallback: show page after 3 seconds even if no scores received
  setTimeout(function () {
    if (!firstScoreReceived) {
      console.log('Timeout: showing page without scores');
      document.body.style.opacity = 1;
    }
  }, 3000);
});

function getPercentages(a, b) {
  var result = {};

  if (a + b > 0) {
    result.a = (a / (a + b) * 100).toFixed(1);
    result.b = (b / (a + b) * 100).toFixed(1);
  } else {
    result.a = result.b = 50;
  }

  return result;
}