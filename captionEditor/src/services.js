angular.module('CaptionServices', [])
.value("serverPath", "http://salesmanbuddytest1.elasticbeanstalk.com/v1/salesmanbuddy/")
// .value("serverPath", "http://localhost:8080/salesmanBuddy/v1/salesmanbuddy/")
.value("languagesPath", "languages")
.value("mediaPath", "media")
.value("captionPath", "captions")

.factory('languagesFactory',function(serverPath, languagesPath, $http, $q){
	var factory = {};

	factory.getLanguages = function(){
		var defer = $q.defer();
		$http.get(serverPath + languagesPath, {cache:true}).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("languages get all error", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	return factory;
})

.factory('mediaFactory',function(serverPath, mediaPath, $http, $q){
	var factory = {};

	factory.getMediaById = function(id){
		var defer = $q.defer();
		var options = {
			params:{
				mediaid:id
			}
		};

		$http.get(serverPath + mediaPath, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("get media by id fail, id: " + id, data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	factory.getAllMedia = function(){
		var defer = $q.defer();
		$http.get(serverPath + mediaPath).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("get all media fail", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	factory.putMedia = function(media){
		var defer = $q.defer();
		$http.put(serverPath + mediaPath, media).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("put media fail", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	return factory;
})

.factory('captionsFactory',function(serverPath, captionPath, $http, $q){
	var factory = {};

	factory.getAllCaptions = function(mediaId, languageId){
		var defer = $q.defer();
		var options = {
			params:{
				mediaid:mediaId,
				languageid:languageId
			}
		};
		$http.get(serverPath + captionPath, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("get all captions fail", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	factory.putCaptions = function(captions){
		var defer = $q.defer();
		$http.put(serverPath + captionPath, captions).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("put captions fail", data, status, headers, config);
			defer.reject(null);
		});
		return defer.promise;
	}

	return factory;
});