function selectVideoCtrl($scope, $routeParams, $rootScope, $route, $http, $location, mediaFactory, languagesFactory){
	$scope.errorMessage = "";
	$scope.showErrorMessage = false;

	$scope.newMedia = {};
	$scope.fixMedia = {};

	$scope.loading = false;

	$scope.changedSelectedMedia = function(selectedMedia){
		console.log("Selected: ", selectedMedia);
	}

	$scope.deleteThisMedia = function(media){
		if(media && media.id){
			var p = prompt("Are you sure? Type DELETE in all caps to confirm. This cannot be undone and will delete all subtitles and popups with this media.");
			if(p != null && p == "DELETE"){
				console.log("deleting")
				$scope.loading = true;
				mediaFactory.deleteMediaById(media.id).then(function(data){
					$scope.loading = false;
					console.log("done");
					$route.reload();
				}, function(data){
					$scope.loading = false;
					alert("delete failed, error in console");
					console.log("error data: ", data);
				});
			}
		}
	}

	$scope.saveFixedFile = function(file){
		
		if(file.base64Data && $scope.selectedMedia.name){
			console.log("got fix file: ", file);
			$scope.loading = true;
			file.id = $scope.selectedMedia.id;
			file.audioLanguageId = $scope.selectedMedia.audioLanguageId;
			file.type = $scope.selectedMedia.type;
			file.name = $scope.selectedMedia.name;
			// filename is really the only thing changing, already on file

			var base64String = file.base64Data;
			delete file.base64Data;
			console.log(file);

			mediaFactory.putMedia(file).then(function(data){
				console.log("returned updated media: ", data);
				mediaFactory.saveMedia(base64String, data.id, file.contentType).then(function(newFilenameInBucket){
					console.log("returned updated saveMedia");
					$scope.loading = false;
					$location.path("/" + data.id);
				}, function(data){
					alert("saving the media data failed, please try again");
					console.log(data);
					$scope.loading = false;
				});
			});
		}
	}

	$scope.fixFile = function(){
		// odnt do anything
	}

	$scope.getAllLanguages = function(){
		languagesFactory.getLanguages().then(function(data){
			$scope.languages = data;
		});
	}
	$scope.getAllLanguages();


	$scope.getVideoList = function(){
		mediaFactory.getAllMedia().then(function(data){
			$scope.allMedia = data;
			if($routeParams.mediaId){
				for (var i = $scope.allMedia.length - 1; i >= 0; i--) {
					if($scope.allMedia[i].id == $routeParams.mediaId){
						$scope.selectedMedia = $scope.allMedia[i];
						return;
					}
				};
			}
		});
	}
	$scope.getVideoList();

	$scope.selectedFile = function(file){
		console.log("selected file", file)
		// $scope.newMedia.filename = file.name;
		// if($scope.newMedia.filename.length > 100){
		// 	$scope.errorMessage = "The filename cant be longer than 100 characters, this one is: " + $scope.newMedia.filename.length;
		// 	return;
		// }

		// $scope.newMedia.stringType = file.type;

		$scope.newMedia.type = 3;// unknown
		if(file.contentType && file.contentType.substr(0, 5) == 'video')
			$scope.newMedia.type = 1;
		else if(file.contentType && file.contentType.substr(0, 5) == 'audio')
			$scope.newMedia.type = 2;


		// console.log($scope.newMedia)
		// $scope.$apply();
	}


	$scope.useThisMedia = function(media){
		$location.path("/modify/" + media.id + "/none/none");
	}

	$scope.saveNewMedia = function(newMedia){
		if(!(newMedia.filename && newMedia.type && newMedia.audioLanguage)){
			$scope.errorMessage = "All the fields above need values before saving this to the server";
			// log error
			return;
		}
		$scope.loading = true;
		newMedia.id = 0;
		newMedia.audioLanguageId = newMedia.audioLanguage.id;
		var base64String = newMedia.base64Data;
		delete newMedia.base64Data;
		// console.log(angular.toJson(newMedia))
		mediaFactory.putMedia(newMedia).then(function(data){
			console.log("returned media: ", data);
			mediaFactory.saveMedia(base64String, data.id, newMedia.contentType).then(function(data){
				console.log("returned saveMedia");
				$scope.loading = false;
				$location.path("/" + data.id);
			}, function(data){
				// console.log("failed to save media", data, status, headers, config);
				alert("there was an error saving that video data, please select this media from the top list and reupload the file");
			});
		});
	}
	
	$scope.languageNameForId = function(id){
		if(!$scope.languages)
			return "";
		for (var i = $scope.languages.length - 1; i >= 0; i--) {
			if($scope.languages[i].id == id)
				return $scope.languages[i].name;
		};
	}

	$scope.getMediaType = function(type){
		if(type == 1)
			return "video";
		else if(type == 2)
			return "audio";
		else
			return "Unknown";
	}
	// $scope.closeChangeVideoModal = function(){
	// 	if($scope.video == undefined){
	// 		$scope.errorMessage = "You must select a video first";
	// 		$scope.showErrorMessage = true;
	// 	}
	// 	else
	// 		$location.path('/modify/' + $scope.video.id + '/none/none');
	// }

	// $scope.loadTypeIdVideo = function(){// for when you type in the id # of the video you want
	// 	if($scope.video.typedId.length == 3){
	// 		$scope.loadVideoData($scope.video.typedId);
	// 		$scope.video.typedId = "";
	// 	}
	// }

	// $scope.loadSelectVideo = function(){
	// 	console.log($scope.video)
	// 	$scope.loadVideoData($scope.video.id);
	// }

	// $scope.loadVideoData = function(id){
	// 	for (var i = $scope.allVideos.length - 1; i >= 0; i--) {
	// 		if($scope.allVideos[i].id == id){
	// 			$scope.video = $scope.allVideos[i];
	// 			$scope.getCaptionLanguagesThisVideo($scope.video.id);
	// 			break;
	// 		}
	// 	};
	// }

	// $scope.getAllLanguages = function(){// all possible languages
	// 	$http.get($rootScope.serverUrl + "captions/all").success(function(data){
	// 		$scope.allLanguages = data;
	// 		$scope.allLanguagesOriginal = data;
	// 	}).error(function(data, status, headers, config){
	// 		console.log("$http: getAllLanguages", data, status, headers, config);
	// 	});
	// }
	// $scope.getAllLanguages();

	// $scope.filterVideosByThisLanguage = function(preferedLanguage){
	// 	var finalList = new Array();
	// 	for (var i = 0; i < $scope.allVideosOriginal.length; i++) {
	// 		for (var i = $scope.allVideosOriginal[i].captionLanguages.length - 1; i >= 0; i--) {
	// 			if($scope.allVideosOriginal[i].captionLanguages[i] == preferedLanguage)
	// 				finalList.push($scope.allVideosOriginal[i]);
	// 		};
	// 	};
	// 	$scope.allVideos = finalList;
	// }

	// // copied from mainCtrl
	// $scope.getCaptionLanguagesThisVideo = function(itemId){
	// 	if(itemId){// to remove error for when you havent chosen a video yet
	// 		$http.get($rootScope.serverUrl + "media/" + itemId + "/captions").success(function(data){//success
	// 			//to indicate on the select video page which languages have captions
	// 			var temp = "";
	// 			for (var i = 0; i < data.length - 1; i++) {
	// 				temp += data[i].fullLang;
	// 				if(i != data.length - 2)
	// 					temp += ", ";
	// 			};
	// 			if(temp == '')
	// 				$scope.captionList = "None";
	// 			else
	// 				$scope.captionList = temp;
	// 		}).error(function(data, status, headers, config){// error
	// 			console.log("doDbRequestWithError: getCaptionLanguagesThisVideo", data, status, headers, config);
	// 		});
	// 	}
	// }

	// $scope.getLanguagesForEachVideo = function(){
	// 	for (var i = $scope.allVideos.length - 1; i >= 0; i--) {
	// 		console.log($scope.allVideos[i]);
	// 		$http.get($rootScope.serverUrl + "media/" + $scope.allVideos[i].id + "/captions").success(function(data){//success
	// 			console.log(data)
	// 			$scope.allVideos[i].captionsLanguages = data;
	// 		}).error(function(data){
	// 			console.log('get caption languages error');
	// 		});
	// 	};
	// }
}