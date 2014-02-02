angular.module('directives',[])

.directive('onEnter', function(){
  return function(scope, element, attrs){
    element.bind("keydown keypress", function(event){
      if(event.which === 13){
        scope.$apply(function(){
          scope.$eval(attrs.onEnter);
        });
        event.preventDefault();
      }
    });
  }
})

.directive('onUpArrow', function(){
  return function(scope, element, attrs){
    element.bind("keydown keypress", function(event){
      if(event.which === 38){
        scope.$apply(function(){
          scope.$eval(attrs.onUpArrow);
        });
        event.preventDefault();
      }
    });
  }
})

.directive('onDownArrow', function(){
  return function(scope, element, attrs){
    element.bind("keydown keypress", function(event){
      if(event.which === 40){
        scope.$apply(function(){
          scope.$eval(attrs.onDownArrow);
        });
        event.preventDefault();
      }
    });
  }
})

.directive('onTab', function(){
  return function(scope, element, attrs){
    element.bind("keydown keypress", function(event){
      if(event.which === 9){
        scope.$apply(function(){
          scope.$eval(attrs.onTab);
        });
        event.preventDefault();
      }
    });
  }
})

//https://gist.github.com/eliotsykes/5394631#file-ngfocusandblur-js
.directive('onFocus', ['$parse', function($parse) {
  return function(scope, element, attrs) {
    var fn = $parse(attrs['onFocus']);
    element.bind('focus', function(event) {
      scope.$apply(function() {
        scope.$eval(attrs.onFocus);
      });
    });
  }
}])

.directive('appFilereader', function($q){
    var slice = Array.prototype.slice;

    return {
        restrict: 'A'
        , require: '?ngModel'
        , link: function(scope, element, attrs, ngModel){
            if(!ngModel) return;

            ngModel.$render = function(){}

            element.bind('change', function(e){
                var element = e.target;
                console.log(e.target.files)

                var file;

                if(e.target.files.length == 1)
                	file = e.target.files[0];

                console.log(file);

                var fileUrl = URL.createObjectURL(file);

                console.log(fileUrl)
                file.realFileName = fileUrl;

             //    var videoNode = document.getElementById('videoSource');// fix this so that it all works great

             // //    var canPlay = videoNode.canPlayType(file.type);

            	// // canPlay = (canPlay === '' ? 'no' : canPlay);

             //    console.log(videoNode)
             //    console.log(canPlay)
             //    videoNode.src = fileUrl;
             scope.$apply(function(){
                ngModel.$setViewValue(file);
                ngModel.$render();
            });
                // ngModel.$setViewValue('asdfasdf');
                // console.log(slice.call(element.files, 0).map(readFile))

     //            $q.all(slice.call(element.files, 0).map(readFile)).then(function(base64DataArray){
					// var base64Data = base64DataArray[0];
					// console.log(base64Data)


					// // if(element.multiple) ngModel.$setViewValue(base64Data);
					// // else 
					// 	ngModel.$setViewValue(base64Data.length ? base64Data[0] : null);
     //            });

                function readFile(file) {
                    var deferred = $q.defer();

                    var reader = new FileReader()
                    reader.onload = function(e){
                        deferred.resolve(e.target.result);
                    }
                    reader.onerror = function(e) {
                        deferred.reject(e);
                    }
                    reader.readAsDataURL(file);

                    return deferred.promise;
                }

            });//change

        }//link

    };//return

})//appFilereader


.directive("fileread", [function () {
    return {
        scope: {
            fileread: "="
        },
        link: function (scope, element, attributes) {
            element.bind("change", function (changeEvent) {
                scope.$apply(function () {
                    scope.fileread = changeEvent.target.files[0];
                    // or all selected files:
                    // scope.fileread = changeEvent.target.files;
                });
            });
        }
    }
}])
 
.directive('onBlur', ['$parse', function($parse) {
  return function(scope, element, attrs) {
    var fn = $parse(attrs['onBlur']);
    element.bind('blur', function(event) {
      scope.$apply(function() {
        scope.$eval(attrs.onBlur);
      });
    });
  }
}]);