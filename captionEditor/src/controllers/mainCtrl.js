function mainCtrl($scope, $routeParams, $rootScope, $q, $http, $location, $timeout, languagesFactory, mediaFactory, captionsFactory){

	$scope.loading = true;
	$scope.validFileSelected = false;

	$scope.edit = new Object();
	$scope.edit.clickToSeek = 'on';//default for click to seek
	$scope.edit.showTestResults = 'yes';//default for show test results
	$scope.edit.showErrorMessage = false;
	$scope.edit.language = new Object();
	$scope.edit.referenceLanguage = new Object();

	$scope.editModes = new Array();
	$scope.editModes[0] = new Object();
	$scope.editModes[0].title = "Edit an existing caption";
	$scope.editModes[0].type = "modify";
	
	$scope.editModes[1] = new Object();
	$scope.editModes[1].title = "Add a new language";
	$scope.editModes[1].type = "new";
	$scope.edit.mode = $scope.editModes[0];

	$scope.video = new Object();
	$scope.video.captions = new Object();
	$scope.modalFlags = new Object();
	$scope.modalFlags.showChangeVideoModal = true;
	$scope.modalFlags.showJsonCopyModal = false;
	$scope.modalFlags.showJsonUploadModal = false;
	$scope.modalFlags.submitModalStatus = 'dontShow';

	$scope.modalMessages = new Object();
	$scope.showDontChangeWarning = false;
	$scope.showErrorOnHoverMessage = false;

	$scope.captionTypes = [
		{name:'Bottom', value:1, class:'bottomSubtitle'},
		{name:'Top', value:2, class:'topSubtitle'},
		{name:'Right', value:3, class:'rightSubtitle'},
		{name:'Left', value:4, class:'leftSubtitle'},
		{name:'Hard Right', value:5, class:'hardRightSubtitle'},
		{name:'Hard Left', value:6, class:'hardLeftSubtitle'}
	];


	$scope.captionValueForType = function(name){
		var value = $scope.captionTypeForTypeName(name);
		if(value != -1)
			return value.value;
		return -1;
	}

	$scope.captionTypeForTypeValue = function(value){
		for (var i = $scope.captionTypes.length - 1; i >= 0; i--) {
			if($scope.captionTypes[i].value == value)
				return $scope.captionTypes[i];
		};
		return -1;
	}

	$scope.captionTypeForTypeName = function(name){
		for (var i = $scope.captionTypes.length - 1; i >= 0; i--) {
			if($scope.captionTypes[i].name.toLowerCase() == name.toLowerCase())
				return $scope.captionTypes[i];
		};
		return -1;
	}

	$scope.routeValues = {// so we can use these in the html
		'how':$routeParams.how,
		'videoId':$routeParams.videoId,
		'lang':$routeParams.lang,
		'refLang':$routeParams.refLang
	}

	/* mainCtrl Notes************************************************************************************
	Controller initialization functions are at the very end
	$scope.tests has all the unit tests and field tests

	*/

	// things to fix*****************************************************************************
	// need to have language on the caption objects coming from the server for making and accepting caption backups
	// try removeAttribute("default") to change the current caption upon loading of different captions. see how videojs does it internally
	// try to implement live previewing of subtitles as they are typed with ng-change. If not, add a button to update the player
	// do a 'test current captions in the video player' functionality
	// some tests dont work
	// verify "upload a backup" data
	// new language list not have existing languages in it
	// allow user to change reference language without loosing current changes
	// changed field dont change languages warning
	// new edit backup download/upload
	// comment the tests
	// change the route and just rebuild the view when "select editing mode" is selected, instead of trying to clear everything
	// tab on last comment field makes a new line

	// $scope.mediaPromise = $http.get($rootScope.serverUrl + "media/" + $routeParams.videoId).success(function(data){//success
	// 	$scope.video.data = data;
	// 	$scope.prepareVideo();
	// }).error(function(data, status, headers, config){
	// 	console.log("$http: getVideoDetails", data, status, headers, config);
	// });

	$scope.selectedVideoFile = function(file){
		console.log(file)
		$scope.fileErrorMessage = "";
		// $scope.$apply();
		if(file.name != $scope.video.data.filename){
			$scope.fileErrorMessage = "You must select the file with the same name as what the database has. Has: " + $scope.video.data.filename + ", you selected: " + file.filename;
			return;
		}else{
			console.log("going herre")
			$scope.videoCommand("addSource", file.realFileName);
			$scope.videoCommand("setup");
			$scope.videoCommand("load");
			$scope.videoCommand("addTimeUpdate", $scope.showSubtitleForTime);
			$scope.prepareVideo();
		}
	}

	$scope.getCaptionTypeClass = function(){
		if($scope.captionShowing){
			return $scope.captionShowing.typeObject.class;
		}
	}

	$scope.showSubtitleForTime = function(time){
		$scope.$apply(function(){
			time = time * 1000;
			// console.log(time);
			if(!$scope.edit.activeEdit)
				return;
			for (var i = $scope.edit.activeEdit.length - 1; i >= 0; i--) {
				var caption = $scope.edit.activeEdit[i];
				// console.log($scope.convertCaptionEditorTimeToLong(caption.starttime), time, $scope.convertCaptionEditorTimeToLong(caption.endtime));
				if($scope.convertCaptionEditorTimeToLong(caption.starttime) < time && time < $scope.convertCaptionEditorTimeToLong(caption.endtime)){
					$scope.captionShowing = caption;
					break;
				}else
					$scope.captionShowing = null;
			};
		});
	}

	$scope.getLanguageIdForLanguage = function(name){
		for (var i = $scope.allLanguages.length - 1; i >= 0; i--) {
			if($scope.allLanguages[i].name == name){
				return $scope.allLanguages[i].id;
			}
		};
		return -1;
	}

	$scope.getLanguageForLanguageName = function(name){
		for (var i = $scope.allLanguages.length - 1; i >= 0; i--) {
			if($scope.allLanguages[i].name == name){
				return $scope.allLanguages[i];
			}
		};
		return -1;
	}

	$scope.convertLongToCaptionEditorTime = function(longTime){
		var milliseconds = Math.floor(longTime % 1000);
		var frames = Math.floor(milliseconds * 30 / 1000);
		var totalSec = Math.floor(longTime / 1000);
		var hours = Math.floor(parseInt( totalSec / 3600 ) % 24);
		var minutes = Math.floor(parseInt( totalSec / 60 ) % 60);
		var seconds = Math.floor(totalSec % 60);
		return $scope.addLeadingZerosToWholeTime(hours + ":" + minutes + ":" + seconds + "." + frames).wholeTime;
	}

	$scope.convertCaptionEditorTimeToLong = function(wholeTime){
		var hours = parseInt(wholeTime.slice(0,2));
		var minutes = parseInt(wholeTime.slice(3,5));
		var seconds = parseInt(wholeTime.slice(6,8));
		var frames = parseInt(wholeTime.slice(9));
		var milliseconds = Math.floor(frames * 1000 / 30);
		return milliseconds + seconds * 1000 + minutes * 60 * 1000 + hours * 60 * 60 * 1000;
	}

	$scope.prepareVideo = function(){
		// console.log($scope.video)
		// $scope.getUnusedLanguages();// instead of this just get any captions that exist for the language
		// $scope.actuallyGetTheCaptions();
		if($routeParams.lang != "none"){
			$scope.edit.language = $scope.getLanguageForLanguageName($routeParams.lang);
			var languageId = $scope.getLanguageIdForLanguage($routeParams.lang);
			if(languageId == -1)// didnt select a good language, its not in the list
				return;

			captionsFactory.getAllCaptions($scope.video.data.id, languageId).then(function(data){
				$scope.video.captions.defaultLanguage = data;
				$scope.buildCaptionListForRepeater();// look into this
				$scope.validFileSelected = true;
			});
			
		}
		// $scope.getCaptionLanguagesThisVideo();// we dont care about this because it does the references right now
		$scope.edit.showErrorMessage = false;
	}

	$scope.setDontChangeSettings = function(){// called when the user changes anything in the captions
		$scope.showDontChangeWarning = true;
	}

	$scope.getNewCaptionObject = function(){// error flags false, show fields true, fields empty, error messages empty
		var newCaption = new Object();
		newCaption.starttime = "";
		newCaption.endtime = "";
		newCaption.text = "";
		newCaption.refText = "";
		newCaption.language = $routeParams.lang;
		newCaption.showText = true;
		newCaption.showRefText = true;
		newCaption.startTimeError = $rootScope.flags.none;
		newCaption.endTimeError = $rootScope.flags.none;
		newCaption.textError = $rootScope.flags.none;
		newCaption.dontUseThisForTesting = false;
		newCaption.startTimeErrorMessage = "";
		newCaption.endTimeErrorMessage = "";
		newCaption.textErrorMessage = "";
		newCaption.sequence = 1000;

		// added for trainer
		newCaption.startTime = 0;
		newCaption.endTime = 0;
		newCaption.typeObject = $scope.captionTypeForTypeName('bottom');
		newCaption.languageId = $scope.getLanguageIdForLanguage($routeParams.lang);

		return newCaption;
	}

	$scope.makeNewCaptionList = function(){
		var newCaption = $scope.getNewCaptionObject();
		newCaption.showRefText = false;
		$scope.edit.activeEdit = new Array();
		$scope.edit.activeEdit.push(newCaption);
	}

	$scope.addRowAtEnd = function(){
		var newCaption = $scope.getNewCaptionObject();
		newCaption.showRefText = false;
		if($scope.edit.activeEdit[$scope.edit.activeEdit.length-1]){
			newCaption.starttime = $scope.edit.activeEdit[$scope.edit.activeEdit.length-1].endtime;
			newCaption.sequence = parseInt($scope.edit.activeEdit[$scope.edit.activeEdit.length-1].sequence) + 1000;
		}
		$scope.edit.activeEdit.push(newCaption);
		$scope.setDontChangeSettings();
		$("#captionArea").scrollTop($("#captionArea")[0].scrollHeight - $("#captionArea").height());
		$timeout(function(){// allows focus to be put on the new line's start time. timeout makes it wait for the page to be rendered
			var id = 'starttime' + (parseInt($scope.edit.activeEdit.length) - 1);
			document.getElementById(id).focus();
		},0);
	}

	$scope.tabInCaptionField = function(index){
		console.log("tabInCaptionField", $scope.edit.activeEdit.length, index)
		if($scope.edit.activeEdit.length == index + 1)
			// TODO run tests here
			$scope.addRowAtEnd();
		else{
			var inputs = $(this).closest('form').find(':input');
			console.log('inputs')
			inputs.eq( inputs.index(this)+ 1 ).focus();
		}
	}

	$scope.undoRemove = function(index){
		$scope.edit.activeEdit[index].showText = true;
		$scope.setDontChangeSettings();
	}

	$scope.addRowInMiddle = function(index){
		var newCaption = $scope.getNewCaptionObject();
		newCaption.endtime = $scope.edit.activeEdit[index].endtime;
		$scope.edit.activeEdit[index].endtime = "";
		newCaption.showRefText = false;
		if(index == $scope.edit.activeEdit.length - 1){//if row getting added at the end
			newCaption.sequence = ((parseInt($scope.edit.activeEdit[index].sequence)) + 1000);
			$scope.edit.activeEdit.push(newCaption);
			$("#captionArea").scrollTop($("#captionArea")[0].scrollHeight - $("#captionArea").height());
		}else{
			newCaption.sequence = ((parseInt($scope.edit.activeEdit[index+1].sequence) - parseInt($scope.edit.activeEdit[index].sequence))/2) + parseInt($scope.edit.activeEdit[index].sequence);
			$scope.edit.activeEdit.splice(index+1,0,newCaption);
		}
		$scope.setDontChangeSettings();
		$timeout(function(){// allows focus to be put on the new line's start time. timeout makes it wait for the page to be rendered
			var id = 'starttime' + (parseInt(index) + 1);
			document.getElementById(id).focus();
		},0);
	}

	$scope.removeRow = function(index){
		$scope.edit.activeEdit[index].showText = false;
		$scope.setDontChangeSettings();
	}

	$scope.setUpSubtitles = function(){

		$http.get($rootScope.serverUrl + "media/" + $routeParams.videoId + "/captions").success(function(data){//success
			//set up subtitles
			for(var i = 0; i < data.length; i++){
				var track = document.createElement("track");
				track.setAttribute("name","manyTracks");
				track.setAttribute("kind","subtitles");
				track.setAttribute("src", $rootScope.serverUrl + "media/" + $routeParams.videoId + "/captions/" + (data[i].lang).toLowerCase());
				//console.log($rootScope.serverUrl + "media/" + $routeParams.videoId + "/captions/" + (data[i].lang).toLowerCase());
				if($routeParams.lang == data[i].lang){
					track.setAttribute("default");
					track.setAttribute("id","")
				}
				track.setAttribute("srclang",data[i].lang);
				track.setAttribute("label",data[i].fullLang);
				$scope.videoCommand("addSubtitle", track);
			}	
			
			//run the videojs.js to set up player
			console.log("setup gets run")
			$scope.videoCommand("setup");
			$scope.videoCommand("load");
		}).error(function(data, status, headers, config){
			console.log("$http: captionPlayer", data, status, headers, config);
		});
	}

	$scope.videoCommand = function(what, element){
		var videoElement = document.getElementById("mainVideo2");
		if(what == "load"){
			// videoElement.ready(function(){
				videoElement.load();
			// });
		}else if(what == "addSource"){
			var source = document.createElement("source");
			source.setAttribute("src",element);
			source.setAttribute("type","video/mp4")
			videoElement.appendChild(source);
		}else if(what == "goToTime"){
			if(element.length == 0)
				return;
			if($scope.edit.clickToSeek == 'off')// click to see radio button
				return;
			var hours = parseInt(element.slice(0,2));
			var minutes = parseInt(element.slice(3,5));
			var seconds = parseInt(element.slice(6,8));
			var frames = parseInt(element.slice(9));
			// _V_("mainVideo").ready(function(){
				videoElement.currentTime = (seconds + minutes * 60 + hours *60 *60 + (frames / 30));// currentTime is in seconds
			// });
		}else if(what == "addTimeUpdate"){
			videoElement.addEventListener("timeupdate", function(){
				element(videoElement.currentTime);
			}, false);
		}
		// var videoElement = document.getElementById("mainVideo");
		// if(what == "load")
		// 	_V_("mainVideo").ready(function(){
		// 		_V_("mainVideo").load();
		// 	});
		// else if(what == "addSubtitle")
		// 	videoElement.appendChild(element);// at this point it is still the <video id="mainVideo"
		// else if(what == "addSource"){
		// 	var source = document.createElement("source");
		// 	source.setAttribute("src",element);
		// 	source.setAttribute("type","video/mp4")
		// 	videoElement.appendChild(source);
		// }
		// if(what == "setup")
		// 	_V_("mainVideo",{ "controls":true, "autoplay":false, "preload":"true", "playerFallbackOrder": ["flash", "html5", "links"] }, function(){});
	}

	$scope.changedEditMode = function(newMode){// rebuild the view and controller instead of trying to clear everything manually
		if(newMode == 'new')
			$location.path('/' + newMode + '/' + $routeParams.videoId + '/none/none');
		else
			$location.path('/');
	}

	$scope.setMainCaptions = function(lang){
		$location.path('/' + $routeParams.how + '/' + $routeParams.videoId + '/' + lang + '/' + $routeParams.refLang);
	}

	$scope.setReferenceCaptions = function(refLang){
		$location.path('/' + $routeParams.how + '/' + $routeParams.videoId + '/' + $routeParams.lang + '/' + refLang);
	}
	
	$scope.openChangeVideoModal = function(){
		$location.path('/');
	}

	$scope.buildCaptionListForRepeater = function(){
		if($routeParams.how == "new"){
			if($routeParams.refLang != 'none' && $routeParams.lang != 'none'){// both languages selected
				$scope.setUpSubtitles();
				var buildingCaptions = new Array();
				for (var i = 0; i < $scope.video.captions.reference.length; i++) {
					buildingCaptions.push($scope.video.captions.reference[i]);
					var pos = buildingCaptions.length-1;
					buildingCaptions[pos].refText = buildingCaptions[pos].text;
					buildingCaptions[pos].text = "";
					buildingCaptions[pos].showText = true;
					buildingCaptions[pos].showRefText = true;
					buildingCaptions[pos].language = $routeParams.lang;
				};
				$scope.edit.activeEdit = buildingCaptions;
				$scope.testCaptionsForSubmission($scope.edit.activeEdit, true);// test the new captions
			}else if($routeParams.refLang == 'none' && $routeParams.lang != 'none'){
				$scope.setUpSubtitles();
				var buildingCaptions = new Array();
				buildingCaptions.push($scope.getNewCaptionObject());
				buildingCaptions[0].showRefText = false;
				$scope.edit.activeEdit = buildingCaptions;
			}
		}
		else if($routeParams.how == "modify"){
			if($routeParams.lang != 'none' && $routeParams.refLang == "none"){// no reference
				// todo
				// $scope.setUpSubtitles();// dont want to do this because im not using built in subtitles
				$scope.edit.activeEdit = angular.copy($scope.video.captions.defaultLanguage);
				
				// set up al the fields for the active edit
				for (var i = $scope.edit.activeEdit.length - 1; i >= 0; i--) {
					$scope.edit.activeEdit[i].showText = true;
					$scope.edit.activeEdit[i].showRefText = false;
					$scope.edit.activeEdit[i].refText = "";
					$scope.edit.activeEdit[i].startTimeError = $rootScope.flags.none;
					$scope.edit.activeEdit[i].endTimeError = $rootScope.flags.none;
					$scope.edit.activeEdit[i].textError = $rootScope.flags.none;
					$scope.edit.activeEdit[i].dontUseThisForTesting = false;
					$scope.edit.activeEdit[i].startTimeErrorMessage = "";
					$scope.edit.activeEdit[i].endTimeErrorMessage = "";
					$scope.edit.activeEdit[i].textErrorMessage = "";
					$scope.edit.activeEdit[i].language = $routeParams.lang;
					$scope.edit.activeEdit[i].starttime = $scope.convertLongToCaptionEditorTime($scope.edit.activeEdit[i].startTime);
					$scope.edit.activeEdit[i].endtime = $scope.convertLongToCaptionEditorTime($scope.edit.activeEdit[i].endTime);
					$scope.edit.activeEdit[i].text = $scope.edit.activeEdit[i].caption;
					$scope.edit.activeEdit[i].typeObject = $scope.captionTypeForTypeValue($scope.edit.activeEdit[i].type);
				};
			}
			// dont care about this right now - trainer
			else if($routeParams.lang != 'none' && $routeParams.refLang != "none"){// builds combined list of main and reference captions
				$scope.setUpSubtitles();
				var buildingCaptions = new Array();
				var keepGoing = true;
				var indexRef = 0;
				var indexLang = 0;
				while(keepGoing){
					var langTime = parseInt($scope.video.captions.defaultLanguage[indexLang].starttime.replace(':','').replace(':','').replace('.',''));
					var refTime = parseInt($scope.video.captions.reference[indexRef].starttime.replace(':','').replace(':','').replace('.',''));
					if(langTime == refTime){// start times the same
						buildingCaptions.push($scope.video.captions.defaultLanguage[indexLang]);
						//console.log(buildingCaptions[0])
						buildingCaptions[buildingCaptions.length-1].refText = $scope.video.captions.reference[indexRef].text;
						buildingCaptions[buildingCaptions.length-1].showText = true;
						buildingCaptions[buildingCaptions.length-1].showRefText = true;
						indexRef++;
						indexLang++;
					}else if(langTime > refTime){// reference language has earlier time
						buildingCaptions.push($scope.video.captions.reference[indexRef]);
						buildingCaptions[buildingCaptions.length-1].showRefText = true;
						buildingCaptions[buildingCaptions.length-1].showText = false;
						buildingCaptions[buildingCaptions.length-1].refText = buildingCaptions[buildingCaptions.length-1].text;
						buildingCaptions[buildingCaptions.length-1].text = "";
						indexRef++;
					}else{// edit language has earlier time
						buildingCaptions.push($scope.video.captions.defaultLanguage[indexLang]);
						buildingCaptions[buildingCaptions.length-1].showRefText = false;
						buildingCaptions[buildingCaptions.length-1].showText = true;
						buildingCaptions[buildingCaptions.length-1].refText = "";
						indexLang++;
					}

					if(indexLang == $scope.video.captions.defaultLanguage.length - 1){
						for (var i = indexRef; i < $scope.video.captions.reference.length; i++) {
							buildingCaptions.push($scope.video.captions.reference[i]);
							buildingCaptions[buildingCaptions.length-1].showText = false;
							buildingCaptions[buildingCaptions.length-1].showRefText = true;
							buildingCaptions[buildingCaptions.length-1].refText = buildingCaptions[buildingCaptions.length-1].text;
							buildingCaptions[buildingCaptions.length-1].text = "";
						};
						keepGoing = false;
					}else if(indexRef == $scope.video.captions.reference.length - 1){
						for (var i = 0; i < $scope.video.captions.defaultLanguage.length; i++) {
							buildingCaptions.push($scope.video.captions.defaultLanguage[i]);
							buildingCaptions[buildingCaptions.length-1].showText = true;
							buildingCaptions[buildingCaptions.length-1].showRefText = false;
							buildingCaptions[buildingCaptions.length-1].refText = "";
						};
						keepGoing = false;
					}
				}
				$scope.edit.activeEdit = buildingCaptions;
			}
			if($scope.edit.activeEdit != undefined)
				$scope.testCaptionsForSubmission($scope.edit.activeEdit);// test the new captions
		}
	}

	$scope.getAllLanguages = function(){// all possible languages
		// languagesFactory.getLanguages().then(function(data){
		// 	$scope.allLanguages = data;
		// 	$scope.getUnusedLanguages();
		// });
		// $http.get($rootScope.serverUrl + "captions/all").success(function(data){
		// 	$scope.allLanguages = data;
		// 	$scope.getUnusedLanguages();
		// }).error(function(data, status, headers, config){
		// 	console.log("$http: getAllLanguages", data, status, headers, config);
		// });
	}

	$scope.getCaptionsThisVideoWEBVTT = function(shortLanguage){
		$http.get($rootScope.serverUrl + "media/" + $routeParams.videoId + "/captions/" + shortLanguage, {'Content-Type':'text/html'}).success(function(data){//success
			$scope.video.captions.webvtt = data;
		}).error(function(data, status, headers, config){
			console.log("$http: getCaptionsThisVideoWEBVTT", data, status, headers, config);
		});
	}

	$scope.getCaptionsThisVideoJson = function(shortLanguage, whereToSave, languageId){
		var defer = $q.defer();

		captionsFactory.getAllCaptions($scope.video.data.id, languageId).then(function(data){
			if(whereToSave == "default")
				$scope.video.captions.defaultLanguage = data;
		});
		// return $http.get($rootScope.serverUrl + "media/" + $routeParams.videoId + "/captions/" + shortLanguage + "/json").success(function(data){//success
		// 	if(whereToSave == "default")
		// 		$scope.video.captions.defaultLanguage = data;
		// 	else if(whereToSave == "reference")
		// 		$scope.video.captions.reference = data;
		// 	else
		// 		$scope.video.captions.json = data;
		// }).error(function(data, status, headers, config){
		// 	console.log("$http: getCaptionsThisVideoJson", data, status, headers, config);
		// });
		return defer.promise;
	}

	$scope.getCaptionLanguagesThisVideo = function(){
		if($routeParams.videoId != 'none'){// to remove error for when you havent chosen a video yet
			$http.get($rootScope.serverUrl + "media/" + $routeParams.videoId + "/captions").success(function(data){//success
				//to indicate on the select video page which languages have captions
				var temp = "";
				for (var i = 0; i < data.length - 1; i++) {
					temp += data[i].fullLang;
					if(i != data.length - 2)
						temp += ", ";
				};
				if(data.length == 0)// no languages currently being used
					temp = "None";
				$scope.video.captions.captionList = temp;
				
				data.push({// to add the None option to for reference language list
					'id':0,
					'mediaitemid':0,
					'lang':'none',
					'fullLang':'None'
				});
				$scope.video.captions.languages = data;
				
				if($routeParams.refLang == 'none')//set the None as default reference language if none is in routeParams.refLang
					$scope.edit.referenceLanguage = $scope.video.captions.languages[$scope.video.captions.languages.length - 1];
			}).error(function(data, status, headers, config){
				console.log("$http: getCaptionLanguagesThisVideo", data, status, headers, config);
			});
		}
	}

	$scope.getUnusedLanguages = function(){
		console.log($scope.allLanguages)
		$scope.video.captions.unusedLanguages = new Array();
		for (var i = 0; i < $scope.allLanguages.length; i++) {
			var found = false;
			for (var j = $scope.video.captions.languages.length - 1; j >= 0; j--) {
				if($scope.allLanguages[i].lang == $scope.video.captions.languages[j].lang){
					found = true;
					break;
				}
			};
			if(!found)
				$scope.video.captions.unusedLanguages.push($scope.allLanguages[i]);
		};
		if($routeParams.how == 'modify'){
			for (var i = $scope.video.captions.languages.length - 1; i >= 0; i--) {
				if($scope.video.captions.languages[i].lang == $routeParams.lang){// initialize the $scope.edit.language model, makes the dropdown have an initial value
					$scope.edit.language = $scope.video.captions.languages[i];
					break;
				}
			};
		}else{// for a new language, much bigger list
			for (var i = $scope.video.captions.unusedLanguages.length - 1; i >= 0; i--) {
				if($scope.video.captions.unusedLanguages[i].lang == $routeParams.lang){// initialize the $scope.edit.language model, makes the dropdown have an initial value
					$scope.edit.language = $scope.video.captions.unusedLanguages[i];
					break;
				}
			};
		}
		for (var i = $scope.video.captions.languages.length - 1; i >= 0; i--) {
			if($scope.video.captions.languages[i].lang == $routeParams.refLang){// initialize the $scope.edit.referenceLanguage model, makes the dropdown have an initial value
				$scope.edit.referenceLanguage = $scope.video.captions.languages[i];
				break;
			}
		};
	}

	// $scope.actuallyGetTheCaptions = function(){
	// 	// to handle initial controller loads
	// 	if($routeParams.lang != 'none' && $routeParams.refLang == 'none'){
	// 		for (var i = $scope.languages.length - 1; i >= 0; i--) {
	// 			if($scope.languages[i].name = $routeParams.lang){
	// 				$scope.getCaptionsThisVideoJson($routeParams.lang, "default").then(function(data){
	// 					$scope.buildCaptionListForRepeater();
	// 				});
	// 				break;
	// 			}
	// 		};
	// 	}
	// 	// else if($routeParams.lang != 'none' && $routeParams.refLang != 'none'){
	// 	// 	// should never get hit in this version for trainer
	// 	// 	var promise1 = $scope.getCaptionsThisVideoJson($routeParams.refLang, "reference");
	// 	// 	var promise2 = $scope.getCaptionsThisVideoJson($routeParams.lang,"default");
	// 	// 	promise1.then(function(data1){
	// 	// 		promise2.then(function(data2){
	// 	// 			$scope.buildCaptionListForRepeater();
	// 	// 		});
	// 	// 	});
	// 	// }
		
	// }

	$scope.checkIfInError = function(index, whichField) {// called from main.html
		if($scope.edit.showTestResults == 'yes'){
			if(whichField == "starttime"){
				if($scope.edit.activeEdit[index].startTimeError == $rootScope.flags.invalid){
					console.log('mFieldError')
					return 'mFieldError';
				}
				else if($scope.edit.activeEdit[index].startTimeError == $rootScope.flags.none)
					return '';
				else
					return 'mFieldValid';
			}else if(whichField == "endtime"){
				if($scope.edit.activeEdit[index].endTimeError == $rootScope.flags.invalid)
					return 'mFieldError';
				else if($scope.edit.activeEdit[index].endTimeError == $rootScope.flags.none)
					return '';
				else
					return 'mFieldValid';
			}else if(whichField == "caption"){
				if($scope.edit.activeEdit[index].textError == $rootScope.flags.invalid)
					return 'mFieldError';
				else if($scope.edit.activeEdit[index].textError == $rootScope.flags.none)
					return '';
				else
					return 'mFieldValid';
			}
		}
		return '';
	}

	$scope.tests = {
		startTimeValid: function(captionsToTest, index){
			console.log('in startTimeValid')
			var startTimeValid = $scope.tests.isTimeValid(captionsToTest[index].starttime);
			if(startTimeValid != "valid"){
				$scope.showErrorOnHoverMessage = true;
				captionsToTest[index].startTimeError = $rootScope.flags.invalid;
				captionsToTest[index].startTimeErrorMessage = startTimeValid;
			}else
				captionsToTest[index].startTimeError = $rootScope.flags.valid;
			return captionsToTest;
		},
		endTimeValid: function(captionsToTest, index){
			var endTimeValid = $scope.tests.isTimeValid(captionsToTest[index].endtime);
			if(endTimeValid != "valid"){
				$scope.showErrorOnHoverMessage = true;
				captionsToTest[index].endTimeError = $rootScope.flags.invalid;
				captionsToTest[index].endTimeErrorMessage = endTimeValid;
			}else
				captionsToTest[index].endTimeError = $rootScope.flags.valid;
			return captionsToTest;
		},
		captionValid: function(captionsToTest, index){
			console.log(captionsToTest, index)
			var captionValid = $scope.tests.isCaptionValid(captionsToTest[index].text || captionsToTest[index].caption)
			if(captionValid != "valid"){
				console.log("not valid")
				$scope.showErrorOnHoverMessage = true;
				captionsToTest[index].textError = $rootScope.flags.invalid;
				captionsToTest[index].textErrorMessage = captionValid;
			}else
				captionsToTest[index].textError = $rootScope.flags.valid;
			return captionsToTest;
		},
		oneRowTimesOverlapping: function(captionsToTest, index){
			var oneRowTimesOverlapping = $scope.tests.isOneRowTimesOverlapping(captionsToTest[index].starttime, captionsToTest[index].endtime);
			if(oneRowTimesOverlapping != "valid"){
				$scope.showErrorOnHoverMessage = true;
				captionsToTest[index].startTimeError = $rootScope.flags.invalid;
				captionsToTest[index].endTimeError = $rootScope.flags.invalid;
				captionsToTest[index].startTimeErrorMessage += oneRowTimesOverlapping;
				captionsToTest[index].endTimeErrorMessage += oneRowTimesOverlapping;
			}else{// to not override previous error flags from previous tests
				if(captionsToTest[index].startTimeError == $rootScope.flags.invalid){}
				else
					captionsToTest[index].startTimeError = $rootScope.flags.valid;
				if(captionsToTest[index].endTimeError == $rootScope.flags.invalid){}
				else
					captionsToTest[index].endTimeError = $rootScope.flags.valid;
			}
			return captionsToTest;
		},
		hasErrors: function(captionsToTest){
			for (var i = captionsToTest.length - 1; i >= 0; i--) {
				if(captionsToTest[i].startTimeError == $rootScope.flags.invalid || captionsToTest[i].endTimeError == $rootScope.flags.invalid || captionsToTest[i].textError == $rootScope.flags.invalid)
					return true;
			};
		},
		endTimeThisAfterStartTimeNext: function(captionsToTest, index){
			if(index != captionsToTest.length - 1){
				var tempI = index + 1;
				var keepGoing2 = true;
				var skipThisTest = false;
				while(keepGoing2){
					if(captionsToTest[tempI].dontUseThisForTesting)
						tempI++;
					else
						keepGoing2 = false;
					if(tempI == captionsToTest.length){
						skipThisTest = true;
						break;
					}
				}
				if(!skipThisTest){
					var endTimeThisAfterStartTimeNext = $scope.tests.isEndTimeThisAfterStartTimeNextValid(captionsToTest[index].endtime, captionsToTest[tempI].starttime);
					if(endTimeThisAfterStartTimeNext != "valid"){
						$scope.showErrorOnHoverMessage = true;
						captionsToTest[tempI].startTimeError = $rootScope.flags.invalid;
						captionsToTest[index].endTimeError = $rootScope.flags.invalid;
						captionsToTest[tempI].startTimeErrorMessage += endTimeThisAfterStartTimeNext;
						captionsToTest[index].endTimeErrorMessage += endTimeThisAfterStartTimeNext;
					}
				}else{// to not override previous error flags from previous tests
					if(captionsToTest[index].startTimeError == $rootScope.flags.invalid){}
					else
						captionsToTest[index].startTimeError = $rootScope.flags.valid;
					if(captionsToTest[index].endTimeError == $rootScope.flags.invalid){}
					else
						captionsToTest[index].endTimeError = $rootScope.flags.valid;
				}
			}
			return captionsToTest;
		},
		thisCaptionSameAsNextCaption: function(captionsToTest, index){
			if(index != captionsToTest.length - 1){
				var tempI = index + 1;
				var keepGoing2 = true;
				var skipThisTest = false;
				while(keepGoing2){
					if(captionsToTest[tempI].dontUseThisForTesting)
						tempI++;
					else
						keepGoing2 = false;
					if(tempI == captionsToTest.length){
						skipThisTest = true;
						break;
					}
				}
				if(!skipThisTest){
					var thisCaptionNextCaptionTheSame = $scope.tests.isThisCaptionNextCaptionTheSame(captionsToTest[index].text || captionsToTest[index].caption, captionsToTest[tempI].text || captionsToTest[tempI].caption);
					if(thisCaptionNextCaptionTheSame != "valid"){
						$scope.showErrorOnHoverMessage = true;
						captionsToTest[tempI].textError = $rootScope.flags.invalid;
						captionsToTest[index].textError = $rootScope.flags.invalid;
						captionsToTest[tempI].textErrorMessage += thisCaptionNextCaptionTheSame;
						captionsToTest[index].textErrorMessage += thisCaptionNextCaptionTheSame;
					}
				}else{// to not override previous error flags from previous tests
					if(captionsToTest[index].startTimeError == $rootScope.flags.invalid){}
					else
						captionsToTest[index].startTimeError = $rootScope.flags.valid;
					if(captionsToTest[index].endTimeError == $rootScope.flags.invalid){}
					else
						captionsToTest[index].endTimeError = $rootScope.flags.valid;
				}
			}
			return captionsToTest;
		},

		// dont use these tests outside of $scope.tests functions, only externaly use the tests above****************************************************************************************************
		isTimeValid: function(wholeTime){
			var templateTime = "00:00:00.00";
			var message = "";
			if(wholeTime.length < 11)
				return "Time is too short, should be of the form 00:00:00.00";
			var hours = parseInt(wholeTime.slice(0,2));
			if(!$scope.tests.areNumbers(wholeTime.slice(0,2)))
				message += "The hours(first two digits) are not numbers";
			else if(hours > 98 || hours < 0)
				message += "The hours(first two digits) are not between 0 and 98";
			var minutes = parseInt(wholeTime.slice(3,5));
			if(!$scope.tests.areNumbers(wholeTime.slice(3,5)))
				message += ", The minutes(digits 4 and 5) are not numbers";
			else if(minutes > 59 || minutes < 0)
				message += ", The minutes(digits 4 and 5) are not between 0 and 59"
			var seconds = parseInt(wholeTime.slice(6,8));
			if(!$scope.tests.areNumbers(wholeTime.slice(6,8)))
				message += ", The seconds(digits 7 and 8) are not numbers";
			else if(seconds > 59 || seconds < 0)
				message += ", The seconds(digits 7 and 8) are not between 0 and 59"
			var frames = parseInt(wholeTime.slice(9));
			if(!$scope.tests.areNumbers(wholeTime.slice(9)))
				message += ", The frames(digits 10 and 11) are not numbers";
			else if(frames > 30 || frames < 0)
				message += ", The frames(digits 10 and 11) are not between 0 and 30: " + frames;
			if(templateTime.slice(2,3) != wholeTime.slice(2,3))
				message += ", Missing colin between hours and minutes";
			if(templateTime.slice(5,6) != wholeTime.slice(5,6))
				message += ", Missing colin between minutes and seconds";
			if(templateTime.slice(8,9) != wholeTime.slice(8,9))
				message += ", Missing period between seconds and frames";
			if(message == "")
				return "valid";
			else 
				return message;
		},
		isCaptionValid: function(caption){
			console.log(caption)
			var message = "";
			if(caption.length == 0)
				message = "The caption is blank. Remove it completelly or type something in it";
			if(caption.length > 200)
				message = ", The caption is longer than 200 characters. Shorten it or break it up into multiple captions";
			if(message == "")
				return "valid";
			else 
				return message;
		},
		isOneRowTimesOverlapping: function(startTime, endTime){
			var message = "";
			var startTimeOnlyNumbers = $scope.giveTimeAsNumber(startTime);
			var endTimeOnlyNumbers = $scope.giveTimeAsNumber(endTime);
			if($scope.tests.areNumbers(startTimeOnlyNumbers) && $scope.tests.areNumbers(endTimeOnlyNumbers))
				if(parseInt(startTimeOnlyNumbers) > parseInt(endTimeOnlyNumbers))
					message = ", Start time is after the end time";
				else if(parseInt(startTimeOnlyNumbers) == parseInt(endTimeOnlyNumbers))
					message = ", Start time and end time are the same";
			if(message == "")
				return "valid";
			else 
				return message;
		},
		isEndTimeThisAfterStartTimeNextValid: function(endTime, startTime){
			var message = "";
			var startTimeOnlyNumbers = $scope.giveTimeAsNumber(startTime);
			var endTimeOnlyNumbers = $scope.giveTimeAsNumber(endTime);
			if($scope.tests.areNumbers(startTimeOnlyNumbers) && $scope.tests.areNumbers(endTimeOnlyNumbers))
				if(parseInt(startTimeOnlyNumbers) < parseInt(endTimeOnlyNumbers))
					message = "Start time is before the previous end time";
			if(message == "")
				return "valid";
			else 
				return message;
		},
		isThisCaptionNextCaptionTheSame: function(thisText, nextText){
			if(thisText == nextText)
				return "The caption is the same as the other next to it";
			return "valid";
		},
		areNumbers: function(stringToTest){
	    	var valid = true;
	   		for (var i = stringToTest.length - 1; i >= 0; i--) {
	   			var myCharCode = stringToTest.charCodeAt(i);
	   			// console.log(stringToTest.charAt(i), myCharCode);
			    if((myCharCode < 47) || (myCharCode >  58))
			        valid = false;
			};
			return valid;
		}
	}

	$scope.testCaptionsForSubmission = function(captionsToTest, dontTestCaptionField){
		for (var i = captionsToTest.length - 1; i >= 0; i--) {
			if(captionsToTest[i].showText == false)
				captionsToTest[i].dontUseThisForTesting = true;
			else{
				captionsToTest = $scope.tests.startTimeValid(captionsToTest, i);
				captionsToTest = $scope.tests.endTimeValid(captionsToTest, i);
				captionsToTest = $scope.tests.oneRowTimesOverlapping(captionsToTest, i);
				captionsToTest = $scope.tests.endTimeThisAfterStartTimeNext(captionsToTest, i);

				if(dontTestCaptionField != true){
					captionsToTest = $scope.tests.captionValid(captionsToTest, i);
					captionsToTest = $scope.tests.thisCaptionSameAsNextCaption(captionsToTest, i);
				}else
					captionsToTest[i].textError = $rootScope.flags.none;
			}
		};
		$scope.edit.showTestResults = 'yes';
		var hasErrors = $scope.tests.hasErrors(captionsToTest);
		if(hasErrors)
			$scope.showErrorOnHoverMessage = true;
		else
			$scope.showErrorOnHoverMessage = false;
		return hasErrors;
	}

	$scope.giveTimeAsNumber = function(wholeTime){
		return wholeTime.slice(0,2) + wholeTime.slice(3,5) + wholeTime.slice(6,8) + wholeTime.slice(9);
	}
	
	// Modal functions
	$scope.makeSureBackupIsValid = function(){
		console.log("in backup is valid?")
		var tempActiveEdit = angular.fromJson($scope.jsonStringOfBackupText);
		if(!$scope.testCaptionsForSubmission(tempActiveEdit)){
			console.log("valid")
			$scope.jsonUploadErrorMessage = "This data is valid, please close this modal";
			$scope.jsonUploadValid = true;
		}
		else{
			$scope.jsonUploadErrorMessage = "This data is invalid, make sure you copied everyting from your backup text file";
			$scope.jsonUploadValid = false;
			console.log("invalid")
		}
	}

	$scope.classForJsonValidity = function(){
		if($scope.jsonUploadValid)
			return "mGreen";
		else
			return "mRed";
	}

	$scope.prepareUploadCaptionModal = function(){
		$scope.jsonStringOfBackupText = "";
		$scope.modalFlags.showJsonUploadModal = true;

		$scope.modalMessages.jsonTitle = "Upload Captions Backup Data";
		$scope.modalMessages.jsonMessage = "Click in the text box and paste the text that you copied and saved last time. This does not upload to the server. You must click 'Submit Captions' after you close this window.";
	}

	$scope.prepareDownloadCaptionBackupModal = function(){
		var backupCaptions = [];
		var languageId = $scope.getLanguageIdForLanguage($routeParams.lang);
		for (var i = 0; i < $scope.edit.activeEdit.length; i++) {
			var caption = $scope.edit.activeEdit[i];
			if(caption.showText){
				var tempCaption = new Object();
				tempCaption.startTime = $scope.convertCaptionEditorTimeToLong(caption.starttime);
				tempCaption.endTime = $scope.convertCaptionEditorTimeToLong(caption.endtime);
				tempCaption.mediaId = parseInt($routeParams.videoId);
				tempCaption.caption = caption.text;
				tempCaption.type = caption.typeObject.value;
				tempCaption.languageId = languageId;
				backupCaptions.push(tempCaption);
			}
		};
		$scope.jsonStringOfBackupText = angular.toJson(backupCaptions);
		$scope.modalFlags.showJsonCopyModal = true;
		$scope.modalMessages.jsonTitle = "Download Captions Backup Data";
		$scope.modalMessages.jsonMessage = "Click in the text box, select all the text by pressing Ctrl A, then copy all the text to a text document where YOU SAVE IT to a spot of your choosing.";
	}

	$scope.closeCaptionModal = function(){
		if($scope.modalFlags.showJsonUploadModal){
			if($scope.jsonUploadValid){
				$scope.edit.activeEdit = angular.fromJson($scope.jsonStringOfBackupText);
			}
			$scope.modalFlags.showJsonUploadModal = false;
			$scope.jsonUploadErrorMessage = "";
		}
		else{
			$scope.modalFlags.showJsonCopyModal = false;
		}
	}

	$scope.endTimesToStartTimes = function(){
		if($scope.edit.activeEdit != undefined){
			for (var i = 1; i < $scope.edit.activeEdit.length; i++) {
				$scope.edit.activeEdit[i-1].endtime = $scope.edit.activeEdit[i].starttime;
			};
			$scope.testCaptionsForSubmission($scope.edit.activeEdit);// test for errors after this process
		}
	}

	$scope.submitCaptions = function(){
		$scope.saveMessage = "";
		if($scope.edit.activeEdit != undefined){
			if($scope.testCaptionsForSubmission($scope.edit.activeEdit)){
				$scope.bigError = "Big error";
				$scope.showErrorOnHoverMessage = true;
				console.log("big error")
				$scope.saveMessage = "Fix errors first";
			}else{
				$scope.saveMessage = "Saving";
				console.log("generating final")
				$scope.finalCaptions = new Array();
				$scope.showErrorOnHoverMessage = false;

				var languageId = $scope.getLanguageIdForLanguage($routeParams.lang);
				for (var i = 0; i < $scope.edit.activeEdit.length; i++) {
				// 	$scope.edit.activeEdit[i]
				// };
				// for (var i = $scope.edit.activeEdit.length - 1; i >= 0; i--) {
					var caption = $scope.edit.activeEdit[i];
					if($scope.edit.activeEdit[i].showText){
						var tempCaption = new Object();
						tempCaption.startTime = $scope.convertCaptionEditorTimeToLong(caption.starttime);
						tempCaption.endTime = $scope.convertCaptionEditorTimeToLong(caption.endtime);
						tempCaption.mediaId = parseInt($routeParams.videoId);
						tempCaption.caption = caption.text;
						tempCaption.type = caption.typeObject.value;
						tempCaption.languageId = languageId;

						// tempCaption.starttime = $scope.edit.activeEdit[i].starttime;
						// tempCaption.endtime = $scope.edit.activeEdit[i].endtime;
						// tempCaption.text = $scope.edit.activeEdit[i].text;
						// tempCaption.language = $scope.edit.activeEdit[i].language;
						// tempCaption.sequence = i * 1000 + 100000;// Rebuild sequence
						$scope.finalCaptions.push(tempCaption);
					}
				};
				//submit function
				console.log("to submit function", $scope.finalCaptions);

				captionsFactory.putCaptions($scope.finalCaptions).then(function(data){
					if(data == null)
						$scope.saveMessage = "Error, please back up";
					else{
						$scope.saveMessage = "Success";
						$timeout(function() {$scope.saveMessage = "";}, 3000);
					}
					console.log("submitted, here", data);
				});
				// $scope.modalFlags.submitModalStatus ='askPassword';
			}
		}	
	}

	$scope.sendCaptions = function(password){
		$scope.modalFlags.submitModalStatus = 'sending';
		$http.post($rootScope.serverUrl + 'media/' + $routeParams.videoId + '/captions/' + $scope.finalCaptions[0].language + '/json?key=' + password, $scope.finalCaptions).success(function(data){
			console.log(data)
			if(data[0] == 0){
				console.log("submission password invalid");
				$scope.modalFlags.submitModalStatus = 'invalidPassword';
			}else{
				console.log("submit success");
				$scope.modalFlags.submitModalStatus = 'success';
			}
		}).error(function(data, status, headers, config){
			console.log('Submit error', data, status, headers, config);
			$scope.modalFlags.submitModalStatus = 'error';
		});
	}

	$scope.closeSubmitModal = function(whetherToShowBackup){
		if(whetherToShowBackup != undefined && whetherToShowBackup == true)
			$scope.prepareDownloadCaptionBackupModal();
		$scope.modalFlags.submitModalStatus = 'dontShow';
	}

	$scope.showAddRemove = function(showValue){// we dont want them to be able to edit english
		if($routeParams.lang == "en")
			return false;
		else
			return showValue;
	}

	$scope.videoToThisTime = function(wholeTime){
		$scope.videoCommand("goToTime", wholeTime);
	}

	$scope.convertQuickTime = function(whichField, index){// changes time typed in 123 to 1.23 OR 14256 to 1:42:56
		// console.log(whichField, index, $scope.edit.activeEdit[index].starttime.length)
		var hours = 0, minutes = 0, seconds = 0, frames = 0;
		if(whichField == 'start'){
			if($scope.edit.activeEdit[index].starttime == undefined || $scope.edit.activeEdit[index].starttime == ''){
				return;//invalid field
			}else if(!$scope.tests.areNumbers($scope.edit.activeEdit[index].starttime)){// there are already special characters in the field. use the smarter time parser
				console.log("in specialS")
				var returnedObject = $scope.addLeadingZerosToWholeTime($scope.edit.activeEdit[index].starttime);
				if(returnedObject.hasError){
					console.log('in has error', index)
					$scope.edit.activeEdit[index].startTimeError = $rootScope.flags.invalid;
					$scope.edit.activeEdit[index].startTimeErrorMessage = returnedObject.errorMessage;
				}else{
					$scope.edit.activeEdit[index].starttime = returnedObject.wholeTime;
					$scope.edit.activeEdit[index].startTimeError = $rootScope.flags.valid;
					$scope.edit.activeEdit[index].startTimeErrorMessage = '';
				}
				$scope.tests.startTimeValid($scope.edit.activeEdit, index);
				return;
			}else if($scope.edit.activeEdit[index].starttime.length > 8){
				return;// do nothing, they typed too many numbers
			}else if($scope.edit.activeEdit[index].starttime.length > 6){// take the time assuming that fields are complete, starting with frames and then moving left
				frames = 	$scope.edit.activeEdit[index].starttime.slice($scope.edit.activeEdit[index].starttime.length - 2);
				seconds = 	$scope.edit.activeEdit[index].starttime.slice($scope.edit.activeEdit[index].starttime.length - 4, $scope.edit.activeEdit[index].starttime.length - 2);
				minutes = 	$scope.edit.activeEdit[index].starttime.slice($scope.edit.activeEdit[index].starttime.length - 6, $scope.edit.activeEdit[index].starttime.length - 4);
				hours = 	$scope.edit.activeEdit[index].starttime.slice(0, $scope.edit.activeEdit[index].starttime.length - 6);
				console.log(frames,seconds,minutes,hours)
			}else if($scope.edit.activeEdit[index].starttime.length > 4){
				frames = 	$scope.edit.activeEdit[index].starttime.slice($scope.edit.activeEdit[index].starttime.length - 2);
				seconds = 	$scope.edit.activeEdit[index].starttime.slice($scope.edit.activeEdit[index].starttime.length - 4, $scope.edit.activeEdit[index].starttime.length - 2);
				minutes = 	$scope.edit.activeEdit[index].starttime.slice(0, $scope.edit.activeEdit[index].starttime.length - 4);
				console.log(frames,seconds,minutes,hours)
			}else if($scope.edit.activeEdit[index].starttime.length > 2){
				frames = 	$scope.edit.activeEdit[index].starttime.slice($scope.edit.activeEdit[index].starttime.length - 2);
				seconds = 	$scope.edit.activeEdit[index].starttime.slice(0, $scope.edit.activeEdit[index].starttime.length - 2);
				console.log(frames,seconds,minutes,hours)
			}else if($scope.edit.activeEdit[index].starttime.length > 0)
				frames = 	$scope.edit.activeEdit[index].starttime;
			console.log(frames,seconds,minutes,hours)
			if($scope.edit.activeEdit[index].starttime.length != 0){
				$scope.edit.activeEdit[index].starttime = $scope.addLeadingZeros(hours, 2) + ':' + $scope.addLeadingZeros(minutes, 2) + ':' + $scope.addLeadingZeros(seconds, 2) + '.' + $scope.addLeadingZeros(frames, 2);
				$scope.tests.startTimeValid($scope.edit.activeEdit, index);
			}
		}else if(whichField == 'end'){
			console.log('asdfasdf',$scope.tests.areNumbers($scope.edit.activeEdit[index].endtime))
			if($scope.edit.activeEdit[index].endtime == undefined || $scope.edit.activeEdit[index].endtime == ''){
				//invalid field
				console.log("in end")
				return;
			}else if(!$scope.tests.areNumbers($scope.edit.activeEdit[index].endtime)){// there are already special characters in the field. use the smarter time parser
				console.log("in end")
				var returnedObject = $scope.addLeadingZerosToWholeTime($scope.edit.activeEdit[index].endtime);
				if(returnedObject.hasError){
					$scope.edit.activeEdit[index].endTimeError = $rootScope.flags.invalid;
					$scope.edit.activeEdit[index].endTimeErrorMessage = returnedObject.errorMessage;
				}else{
					$scope.edit.activeEdit[index].endtime = returnedObject.wholeTime;
					$scope.edit.activeEdit[index].endTimeError = $rootScope.flags.valid;
					$scope.edit.activeEdit[index].endTimeErrorMessage = '';
				}
				$scope.tests.endTimeValid($scope.edit.activeEdit, index);
				$scope.tests.oneRowTimesOverlapping($scope.edit.activeEdit, index);
				return;
			}else if($scope.edit.activeEdit[index].endtime.length > 8){
				// do nothing, they typed too many numbers
				console.log("in end")
				return;
			}else if($scope.edit.activeEdit[index].endtime.length > 6){// take the time assuming that fields are complete, starting with frames and then moving left
				frames = 	$scope.edit.activeEdit[index].endtime.slice($scope.edit.activeEdit[index].endtime.length - 2);
				seconds = 	$scope.edit.activeEdit[index].endtime.slice($scope.edit.activeEdit[index].endtime.length - 4, $scope.edit.activeEdit[index].endtime.length - 2);
				minutes = 	$scope.edit.activeEdit[index].endtime.slice($scope.edit.activeEdit[index].endtime.length - 6, $scope.edit.activeEdit[index].endtime.length - 4);
				console.log("in end")
				hours = 	$scope.edit.activeEdit[index].endtime.slice(0, $scope.edit.activeEdit[index].endtime.length - 6);
			}else if($scope.edit.activeEdit[index].endtime.length > 4){
				frames = 	$scope.edit.activeEdit[index].endtime.slice($scope.edit.activeEdit[index].endtime.length - 2);
				seconds = 	$scope.edit.activeEdit[index].endtime.slice($scope.edit.activeEdit[index].endtime.length - 4, $scope.edit.activeEdit[index].endtime.length - 2);
				console.log("in end")
				minutes = 	$scope.edit.activeEdit[index].endtime.slice(0, $scope.edit.activeEdit[index].endtime.length - 4);
			}else if($scope.edit.activeEdit[index].endtime.length > 2){
				frames = 	$scope.edit.activeEdit[index].endtime.slice($scope.edit.activeEdit[index].endtime.length - 2);
				seconds = 	$scope.edit.activeEdit[index].endtime.slice(0, $scope.edit.activeEdit[index].endtime.length - 2);
				console.log(frames, seconds)
			}else if($scope.edit.activeEdit[index].endtime.length > 0)
				frames = 	$scope.edit.activeEdit[index].endtime;
			else
				console.log('fail')
			if($scope.edit.activeEdit[index].endtime.length != 0){
				$scope.edit.activeEdit[index].endtime = $scope.addLeadingZeros(hours, 2) + ':' + $scope.addLeadingZeros(minutes, 2) + ':' + $scope.addLeadingZeros(seconds, 2) + '.' + $scope.addLeadingZeros(frames, 2);
				$scope.tests.endTimeValid($scope.edit.activeEdit, index);
				$scope.tests.oneRowTimesOverlapping($scope.edit.activeEdit, index);
			}
		}
	}

	$scope.addLeadingZeros = function(input, howManyDigitsTotal){// for a single number
		var inputString = String(input);
		while(inputString.length < howManyDigitsTotal)
			inputString = '0' + inputString;
		return inputString;
	}

	$scope.addLeadingZerosToWholeTime = function(wholeTime){// for a partial time like: 12.3 -> 00:00:12.03
		var returnObject = {
			'wholeTime':wholeTime,
			'hasError':true,
			'errorMessage':''
		};
		var hours = 0, minutes = 0, seconds = 0, frames = 0;
		var periodIndex = -1, colin1Index = -1, colin2Index = -1;
		var colinsFound = 0;
		var periodsFound = 0;
		
		for (var i = 0; i < wholeTime.length; i++) {// find the period
			if(wholeTime.charAt(i) == '.'){
				periodsFound++;
				if(periodsFound == 1)
					periodIndex = i;
				else{// too many periods found, dont change anything
					returnObject.errorMessage = "Too many periods found: " + periodsFound + ", should be 1 or 0.";
					return returnObject;
				}
			}else if(wholeTime.charAt(i) == ':'){
				colinsFound++;
				if(colinsFound == 1)
					colin1Index = i;
				else if(colinsFound == 2)
					colin2Index = i;
				else{// too many colins found, dont change anything
					returnObject.errorMessage = 'Too many colins found: ' + colinsFound + ', should only be 0, 1, or 2.';
					return returnObject;
				}
			}else if(!$scope.tests.areNumbers(wholeTime.charAt(i))){
				returnObject.errorMessage = 'Invalid character in time field';
				return returnObject;//not a period, colin, or number
			}
		};
		if(periodsFound != 1 && periodsFound != 0){
			returnObject.errorMessage = "Invalid number of periods found: " + periodsFound + ", should be 1 or 0.";
			return returnObject;//invalid number of periods found
		}
		if(colinsFound != 1 && colinsFound != 2 && colinsFound != 0){
			returnObject.errorMessage = 'Invalid number of colins found: ' + colinsFound + ', should only be 0, 1, or 2.';
			return returnObject;//invalid number of colins found
		}
		if(colinsFound > 0 && periodsFound != 1){
			returnObject.errorMessage = 'Cant have colins without periods.';
			return returnObject;
		}
		if(colinsFound == 1){//the first and only colin found must really in fact be the second colin(between seconds and minutes, not minutes and hours)
			colin2Index = colin1Index;
			colin1Index = -1;
		}

		if(colin1Index != -1){// hours must exist, whether '' or a digit or two
			hours = wholeTime.slice(0, colin1Index);
			minutes = wholeTime.slice(colin1Index+1, colin2Index);
			seconds = wholeTime.slice(colin2Index+1, periodIndex);
			frames = wholeTime.slice(periodIndex+1);
		}else if(colinsFound == 0 && periodsFound == 0){// only frames exitst
			frames = wholeTime;
		}else if(colinsFound == 0){// minutes dont exist
			seconds = wholeTime.slice(0, periodIndex);
			frames = wholeTime.slice(periodIndex+1);
		}else{// hours dont exist
			minutes = wholeTime.slice(0, colin2Index);
			seconds = wholeTime.slice(colin2Index+1, periodIndex);
			frames = wholeTime.slice(periodIndex+1);
		}
		returnObject.hasError = false;
		returnObject.wholeTime = $scope.addLeadingZeros(hours, 2) + ':' + $scope.addLeadingZeros(minutes, 2) + ':' + $scope.addLeadingZeros(seconds, 2) + '.' + $scope.addLeadingZeros(frames, 2);
		return returnObject;
	}

	// Adds one second to the time per up arrow press
	$scope.upArrow = function(index, startOrEnd){// true start, false end
		if(startOrEnd == undefined)
			return;
		if(startOrEnd){
			if($scope.edit.activeEdit[index].starttime == ''){// insead of incrementing an empty field, take the time from the previous row's end
				if($scope.edit.activeEdit[index-1] && $scope.edit.activeEdit[index-1].endtime != undefined && $scope.edit.activeEdit[index - 1].endtime != '')
					$scope.edit.activeEdit[index].starttime = $scope.correctTheTimeGreaterThan($scope.edit.activeEdit[index - 1].endtime, 0, "seconds");
				else
					$scope.edit.activeEdit[index].starttime = $scope.convertLongToCaptionEditorTime(0);
			}else
				$scope.edit.activeEdit[index].starttime = $scope.correctTheTimeGreaterThan($scope.edit.activeEdit[index].starttime, 1, "seconds");
			$scope.videoToThisTime($scope.edit.activeEdit[index].starttime);
		}else{
			if($scope.edit.activeEdit[index].endtime == ''){// instead of incrementing an empty field, take the start time of this row
				if($scope.edit.activeEdit[index] && $scope.edit.activeEdit[index].starttime != undefined && $scope.edit.activeEdit[index].starttime != '')
					$scope.edit.activeEdit[index].endtime = $scope.correctTheTimeGreaterThan($scope.edit.activeEdit[index].starttime, 0, "seconds");
				else
					$scope.edit.activeEdit[index].endtime = $scope.correctTheTimeGreaterThan($scope.convertLongToCaptionEditorTime(0), 1, "seconds");
			}else
				$scope.edit.activeEdit[index].endtime = $scope.correctTheTimeGreaterThan($scope.edit.activeEdit[index].endtime, 1, "seconds");
			$scope.videoToThisTime($scope.edit.activeEdit[index].endtime);
		}
		
	}

	// Minuses one second from the time per down arrow press
	$scope.downArrow = function(index, startOrEnd){// true start, false end
		if(startOrEnd == undefined)
			return;
		if(startOrEnd){
			if($scope.edit.activeEdit[index].starttime != undefined && $scope.edit.activeEdit[index].starttime != ''){
				$scope.edit.activeEdit[index].starttime = $scope.correctTheTimeLessThan($scope.edit.activeEdit[index].starttime, 1, "seconds");
				$scope.videoToThisTime($scope.edit.activeEdit[index].starttime);
			}else
				$scope.edit.activeEdit[index].starttime = $scope.correctTheTimeLessThan($scope.convertLongToCaptionEditorTime(0), 0, "seconds");
		}else{
			if($scope.edit.activeEdit[index].endtime != undefined && $scope.edit.activeEdit[index].endtime != '')
				$scope.edit.activeEdit[index].endtime = $scope.correctTheTimeLessThan($scope.edit.activeEdit[index].endtime, 1, "seconds");
			else{
				if($scope.edit.activeEdit[index].starttime != undefined && $scope.edit.activeEdit[index].starttime != ''){
					$scope.edit.activeEdit[index].endtime = $scope.correctTheTimeLessThan($scope.edit.activeEdit[index].starttime, 0, "seconds");
					$scope.videoToThisTime($scope.edit.activeEdit[index].endtime);
				}else
					$scope.edit.activeEdit[index].endtime = $scope.correctTheTimeLessThan($scope.convertLongToCaptionEditorTime(0), 0, "seconds");
			}
		}
	}

	$scope.correctTheTimeGreaterThan = function(wholeTime, howManyUnknown, what){// increments next number and subtracts from current BUT frames get truncated to 30
		var howMany = 0;
		var hours = parseInt(wholeTime.slice(0,2));
		var minutes = parseInt(wholeTime.slice(3,5));
		var seconds = parseInt(wholeTime.slice(6,8));
		var frames = parseInt(wholeTime.slice(9));

		if(!$scope.tests.areNumbers(hours) || !$scope.tests.areNumbers(minutes) || !$scope.tests.areNumbers(seconds) || !$scope.tests.areNumbers(frames))
			return wholeTime;

		if(howManyUnknown != undefined)
			howMany = parseInt(howManyUnknown);

		if(what == "frames")
			frames += howMany;
		else if(what == "seconds")
			seconds += howMany;
		else if(what == "minutes")
			minutes += howMany;
		else if(what == "hours")
			hours += howMany;

		if(frames > 30)
			frames = 30;
		if(seconds > 59){
			minutes += 1;
			seconds -= 60;
		}
		if(minutes > 59){
			hours += 1;
			minutes -= 60;
		}
		if(hours > 98)
			hours = 98;
		return String($scope.addLeadingZeros(hours, 2) + ":" + $scope.addLeadingZeros(minutes, 2) + ":" + $scope.addLeadingZeros(seconds, 2) + "." + $scope.addLeadingZeros(frames, 2));
	}

	$scope.correctTheTimeLessThan = function(wholeTime, howManyUnknown, what){// increments next number and subtracts from current BUT frames get truncated to 30
		var howMany = parseInt(howManyUnknown);
		var hours = parseInt(wholeTime.slice(0,2));
		var minutes = parseInt(wholeTime.slice(3,5));
		var seconds = parseInt(wholeTime.slice(6,8));
		var frames = parseInt(wholeTime.slice(9));

		if(!$scope.tests.areNumbers(hours) || !$scope.tests.areNumbers(minutes) || !$scope.tests.areNumbers(seconds) || !$scope.tests.areNumbers(frames))
			return wholeTime;
		if(what == "frames"){
			if((frames - howmany) < 0)
				frames = 0;
		}else if(what == "seconds"){
			seconds -= howMany;
			while(seconds < 0){
				if(minutes > 0){
					seconds += 60;
					minutes--;
					while(minutes < 0){
						if(hours > 0){
							minutes += 60;
							hours--;
						}else{
							minutes = 0;
							hours = 0;
							seconds = 0;
							frames = 0;
							break;
						}
					}
				}else{
					if(hours > 0){
						minutes += 60;
						hours--;
					}else{
						minutes = 0;
						hours = 0;
						seconds = 0;
						frames = 0;
						break;
					}
				}
			}
		}else if(what == "minutes"){
			minutes -= howMany;
			while(minutes < 0){
				if(hours > 0){
					minutes += 60;
					hours--;
				}else{
					minutes = 0;
					hours = 0;
					seconds = 0;
					frames = 0;
					break;
				}
			}
		}else if(what == "hours"){
			hours -= howMany;
			if(hours < 0){
				minutes = 0;
				hours = 0;
				seconds = 0;
				frames = 0;
			}
		}
		return String($scope.addLeadingZeros(hours, 2) + ":" + $scope.addLeadingZeros(minutes, 2) + ":" + $scope.addLeadingZeros(seconds, 2) + "." + $scope.addLeadingZeros(frames, 2));
	}

	mediaFactory.getMediaById($routeParams.videoId).then(function(data){
		$scope.video.data = data;
		for (var i = $scope.editModes.length - 1; i >= 0; i--) {//setup $scope.edit.mode model from the route params, allows dropdown to show correct mode
			if($scope.editModes[i].type == $routeParams.how){
				$scope.edit.mode = $scope.editModes[i];
				break;
			}
		};
		languagesFactory.getLanguages().then(function(data){
			$scope.video.captions.languages = data;
			$scope.allLanguages = data;
			$scope.loading = false;
			for (var i = $scope.allLanguages.length - 1; i >= 0; i--) {
				if($scope.allLanguages[i].name == $routeParams.lang){
					$scope.edit.language = $scope.allLanguages[i];
					break;
				}
			};
		});
	});
}
















