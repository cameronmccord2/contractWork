//*****************************************************************************
//  ANGULAR MODULE SETUP
//*****************************************************************************

var app = angular.module('MEDIAPORTALCAPTIONEDITOR', ['CaptionServices', 'directives', 'ngRoute', 'AuthenticationService']);

app.config(['$routeProvider', function($routeProvider) {
// Configureable Options:


  $routeProvider.
      when('/', {templateUrl: 'templates/selectVideo.html', controller: selectVideoCtrl}).
      when('/:mediaId', {templateUrl: 'templates/selectVideo.html', controller: selectVideoCtrl}).
      when('/:how/:videoId/:lang/:refLang', {templateUrl:'templates/main.html', controller:mainCtrl}).
  otherwise({redirectTo: '/'});

}]);

app.config(['AuthServiceProvider', function(AuthServiceProvider){
		AuthServiceProvider.setClientID('185872110398-icdle47mq6dtff0ktdpc7qrpojkh5jrj.apps.googleusercontent.com');
		AuthServiceProvider.pushScope('https://www.googleapis.com/auth/plus.me') ;
		AuthServiceProvider.setRedirectURI('https://localhost/captionEditor');
}]);



//*****************************************************************************
//  ROOTSCOPE SETUP
//*****************************************************************************
app.run(function($rootScope, $http, AuthService){

	$rootScope.logout = AuthService.logout;
    $http.defaults.headers.common.authprovider = "google";
    // $http.defaults.headers.common.Authorization = "Bearer ya29.1.AADtN_Vzfx-pZu3cdpqCzuQmq0W8qPM41QNbETp7cf2cuogH795PPkL4m8JEMLt9Ng";
    //$rootScope.baseUrl = 'http://tallbeta.mtc.byu.edu/teachers/api/v1/apprentice/';
    $rootScope.serverUrl = "https://localhost/mediaportal/api/v2/";
    $rootScope.homeFolder = "http://localhost:8080/mediaportal/";
    $rootScope.videoPath = "http://fms.mtc.byu.edu/streams/";
    $rootScope.thumbPath = "http://fms.mtc.byu.edu/";

    $rootScope.flags = {
      'invalid':0,
      'valid':1,
      'none':2
    }

    //local paths, changes 4/17/13 in mediaplayer.js, newMediaPlayer.js, captionEditorPlayer.js, mediaportal.js
    // $rootScope.localVideoPath = "C:\\mediaportal\\videos\\";//changes 4/17/13 in mediaplayer.js, newMediaPlayer.js, captionEditorPlayer.js
    // $rootScope.localThumbPath = "C:\\mediaportal\\thumbs\\";//changes 4/17/13 in mediaportal.js
});

// vidoejs 3959 - _V_.get
//399
// if (this.readyState == 0) {
//       this.readyState = 1;
//       _V_.get(this.src, this.proxy(this.parseCues), this.proxy(this.onError));
//     }
// parseCues function on line 3972