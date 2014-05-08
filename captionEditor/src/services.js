angular.module('CaptionServices', [])
// .constant("serverPath", "http://salesmanbuddyserver.elasticbeanstalk.com/v1/salesmanbuddy/")
.constant("serverPath", "http://localhost:8080/salesmanBuddy/v1/salesmanbuddy/")
.constant("languagesPath", "languages")
.constant("mediaPath", "media")
.constant("captionPath", "captions")
.constant("saveDataPath", "saveData")
.constant("bucketsPath", "buckets")
.constant("popupsPath", "popups")
.constant("subPopupsPath", "subpopups")

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

.factory('mediaFactory',function(serverPath, mediaPath, saveDataPath, $http, $q){
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
			defer.reject(data);
		});
		return defer.promise;
	}

	factory.updateMediaName = function(mediaId, name){
		var defer = $q.defer();
		var options = {
			params:{
				mediaId:mediaId,
				name:name
			}
		};
		$http.put(serverPath + mediaPath + "/name", {}, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("put media name update fail", data, status, headers, config);
			defer.reject(data);
		});
		return defer.promise;
	}

	factory.saveMedia = function(base64String, mediaId, contentType){
		var defer = $q.defer();
		var options = {
			params:{
				mediaId:mediaId,
				base64:1
			},
			headers:{
				"content-type":contentType
			}
		};
		$http.put(serverPath + saveDataPath, base64String.split(",")[1], options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("put saveMedia fail", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	factory.deleteMediaById = function(id){
		var defer = $q.defer();
		var options = {
			params:{
				id:id
			}
		};
		$http.delete(serverPath + mediaPath, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("delete media fail, id: " + id, data, status, headers, config);
			defer.reject(data);
		});
		return defer.promise;
	}

	return factory;
})

.factory('bucketsFactory', function(serverPath, bucketsPath, $http, $q){
	var factory = {};

	factory.getCaptionEditorBucket = function(){
		var defer = $q.defer();
		$http.get(serverPath + bucketsPath + "/captionEditor", {cache:true}).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("get caption editor bucket failed", data, status, headers, config);
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
			console.log("get all captions failed", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	factory.putCaptions = function(captions){
		var defer = $q.defer();
		$http.put(serverPath + captionPath, captions).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("put captions failed", data, status, headers, config);
			defer.reject(data);
		});
		return defer.promise;
	}

	factory.deleteCaption = function(captionId){
		var defer = $q.defer();
		var options = {
			params:{
				captionId:captionId
			}
		};
		$http.delete(serverPath + captionPath, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("delete caption failed, id: " + captionId, data, status, headers, config);
			defer.reject(data);
		});
		return defer.promise;
	}

	return factory;
})

.factory('popupsFactory',function(serverPath, popupsPath, subPopupsPath, saveDataPath, $http, $q){
	var factory = {};

	factory.getAllPopups = function(mediaId, languageId){
		var defer = $q.defer();
		var options = {
			params:{
				mediaid:mediaId,
				languageid:languageId
			}
		};
		$http.get(serverPath + popupsPath, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("get all popups failed", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	factory.putPopups = function(popups){
		var defer = $q.defer();
		$http.put(serverPath + popupsPath, popups).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("put popups failed", data, status, headers, config);
			defer.reject(data);
		});
		return defer.promise;
	}

	factory.deletePopup = function(popupId){
		var defer = $q.defer();
		var options = {
			params:{
				popupId:popupId
			}
		};
		$http.delete(serverPath + popupsPath, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("delete popup failed, id: " + popupId, data, status, headers, config);
			defer.reject(data);
		});
		return defer.promise;
	}

	factory.deleteSubPopup = function(subPopupId){
		var defer = $q.defer();
		var options = {
			params:{
				subPopupId:subPopupId
			}
		};
		$http.delete(serverPath + subPopupsPath, options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("delete subpopup failed, id: " + popupId, data, status, headers, config);
			defer.reject(data);
		});
		return defer.promise;
	}

	factory.savePopupSubPopupFile = function(base64String, popupId, contentType, subPopupId){
		var defer = $q.defer();
		var options = {
			params:{
				popupId:popupId || null,
				base64:1,
				subPopupId:subPopupId || null
			},
			headers:{
				"content-type":contentType
			}
		};
		$http.put(serverPath + saveDataPath, base64String.split(",")[1], options).success(function(data){
			defer.resolve(data);
		}).error(function(data, status, headers, config){
			console.log("put savePopup fail", data, status, headers, config);
			defer.reject();
		});
		return defer.promise;
	}

	return factory;
})

// .factory('promptsFactory', function(serverPath, promptsPath, $http, $q){
// 	var factory = {};

// 	factory.getAllPrompts = function(mediaId, languageId){
// 		var defer = $q.defer();
// 		var options = {
// 			params:{
// 				mediaid:mediaId,
// 				languageid:languageId
// 			}
// 		};
// 		$http.get(serverPath + promptsPath, options).success(function(data){
// 			defer.resolve(data);
// 		}).error(function(data, status, headers, config){
// 			console.log("get all prompts failed", data, status, headers, config);
// 			defer.reject();
// 		});
// 		return defer.promise;
// 	}

// 	factory.putPrompts = function(prompts){
// 		var defer = $q.defer();
// 		$http.put(serverPath + promptsPath, prompts).success(function(data){
// 			defer.resolve(data);
// 		}).error(function(data, status, headers, config){
// 			console.log("put prompts failed", data, status, headers, config);
// 			defer.reject(data);
// 		});
// 	}
// 	return factory;
// })