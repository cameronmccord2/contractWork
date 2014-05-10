function mainCtrl($scope, $routeParams, $rootScope, $q, $http, $location, $timeout, languagesFactory, mediaFactory, captionsFactory, bucketsFactory, popupsFactory){

	$scope.loading = true;
	$scope.validFileSelected = false;
	console.log = function(){};
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
	$scope.video.popups = new Object();
	$scope.modalFlags = new Object();
	$scope.modalFlags.showChangeVideoModal = true;
	$scope.modalFlags.showJsonCopyModal = false;
	$scope.modalFlags.showJsonUploadModal = false;
	$scope.modalFlags.submitModalStatus = 'dontShow';

	$scope.modalMessages = new Object();
	$scope.showDontChangeWarning = false;
	$scope.showErrorOnHoverMessage = false;

	$scope.showPopupEditor = false;
	$scope.showCaptionEditor = true;

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

	// trainer notes
	// add tests for displayName validity, currently always valid
	// make popup previewer
	// make popups list by video at right time




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

	// $scope.selectedVideoFile = function(file){
	// 	console.log(file)
	// 	$scope.fileErrorMessage = "";
	// 	// $scope.$apply();
	// 	if(file.name != $scope.video.data.filename){
	// 		$scope.fileErrorMessage = "You must select the file with the same name as what the database has. Has: " + $scope.video.data.filename + ", you selected: " + file.filename;
	// 		return;
	// 	}else{
	// 		console.log("going herre")
	// 		$scope.videoCommand("addSource", file.realFileName);
	// 		$scope.videoCommand("setup");
	// 		$scope.videoCommand("load");
	// 		$scope.videoCommand("addTimeUpdate", $scope.showSubtitleForTime);
	// 		$scope.prepareVideo();
	// 	}
	// }

	$scope.changePreviewToIndex = function(index){
		// console.log($scope.edit.popups[index])
		bucketsFactory.getCaptionEditorBucket().then(function(bucket){
			$scope.captionEditorBucket = bucket;
			$scope.audioSource = "https://s3-us-west-2.amazonaws.com/" + bucket.name + "/" + $scope.edit.popups[index].filenameInBucket;
			$scope.showingPreview = true;
			$scope.popupPreviewIndex = index;
			// console.log($scope.popupTextPreview)
			$timeout(function(){
				$scope.audioCommand("load");
				if($scope.edit.popups[index].subPopups.length > 0)
					$scope.audioCommand("addTimeUpdate", $scope.showSubPopupForTime);
				else
					$scope.popupTextPreview = $scope.edit.popups[index].text || "ERROR, couldnt find text";
			}, 1000);
		});
	}

	$scope.getCaptionTypeClass = function(){
		if($scope.captionShowing){
			return $scope.captionShowing.typeObject.class;
		}
	}

	$scope.showSubPopupForTime = function(time){
		$scope.$apply(function(){
			time = time * 1000;
			if(!$scope.edit.activeEdit)// need?
				return;
			for (var i = $scope.edit.popups[$scope.popupPreviewIndex].subPopups.length - 1; i >= 0; i--) {
				var subPopup = $scope.edit.popups[$scope.popupPreviewIndex].subPopups[i];
				if($scope.convertCaptionEditorTimeToLong(subPopup.startTime) < time && time < $scope.convertCaptionEditorTimeToLong(subPopup.endTime)){
					subPopup.imageUrl = "";
					console.log(subPopup)
					if(subPopup.filenameInBucket && subPopup.filenameInBucket.length > 0)
						subPopup.imageUrl = "https://s3-us-west-2.amazonaws.com/" + $scope.captionEditorBucket.name + "/" + subPopup.filenameInBucket;
					else
						subPopup.imageUrl = "";
					$scope.subPopupShowing = subPopup;
					break;
				}else
					$scope.subPopupShowing = null;
			};
		});
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

			popupsFactory.getAllPopups($scope.video.data.id, languageId).then(function(popups){
				$scope.video.popups.defaultLanguage = popups;
				$scope.buildPopupListForRepeater();
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

	$scope.getNewPopupObject = function(){
		var newPopup = {
			starttime:'',
			endtime:'',
			text:'',
			refText:'',
			language:$routeParams.lang,
			showText:true,
			showRefText:true,
			startTimeError: $rootScope.flags.none,
			endTimeError:$rootScope.flags.none,
			textError:$rootScope.flags.none,
			displayNameError:$rootScope.flags.none,
			dontUseThisForTesting:false,
			startTimeErrorMessage:'',
			endTimeErrorMessage:'',
			textErrorMessage:'',
			displayNameErrorMessage:'',
			startTime:0,
			endTime:0,
			languageId:$scope.getLanguageIdForLanguage($routeParams.lang),
			displayName:'',
			mediaId:parseInt($routeParams.videoId),
			filename:''
		};
		return newPopup;
	}

	$scope.makeNewCaptionList = function(){
		var newCaption = $scope.getNewCaptionObject();
		newCaption.showRefText = false;
		$scope.edit.activeEdit = new Array();// TODOHERE
		$scope.edit.activeEdit.push(newCaption);
	}

	$scope.addRowAtEnd = function(type, popupIndex){
		if(type && type == 'subPopup'){
			var newSubPopup = $scope.newSubPopup();
			$scope.edit.popups[popupIndex].subPopups.push(newSubPopup);
			$scope.setDontChangeSettings();

		}else if(type && type == 'popup'){
			var newPopup = $scope.getNewPopupObject();
			newPopup.showRefText = false;
			if($scope.edit.popups[$scope.edit.popups.length-1])// there is a list already, so add and update start time to previous end time
				newPopup.starttime = $scope.edit.popups[$scope.edit.popups.length-1].endtime;
			
			$scope.edit.popups.push(newPopup);
			$scope.setDontChangeSettings();
			// dont scroll, might not work
			$timeout(function(){// allows focus to be put on the new line's start time. timeout makes it wait for the page to be rendered
				var id = 'starttimeP' + (parseInt($scope.edit.popups.length) - 1);
				console.log(id)
				document.getElementById(id).focus();
			},0);
		}else{// must be a caption
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
	}

	$scope.tabInCaptionField = function(index, type){
		if(type && type == 'popup'){
			if($scope.edit.popups.length == index + 1)
				$scope.addRowAtEnd(type);// Run tests here?
			else{// move focus to next input in form
				var inputs = $(this).closest('form').find(':input');
				inputs.eq( inputs.index(this)+ 1 ).focus();
			}
		}else{
			console.log("tabInCaptionField", $scope.edit.activeEdit.length, index)
			if($scope.edit.activeEdit.length == index + 1)
				// TODO run tests here?
				$scope.addRowAtEnd();
			else{
				var inputs = $(this).closest('form').find(':input');
				inputs.eq( inputs.index(this)+ 1 ).focus();
			}
		}
	}

	$scope.undoRemove = function(index, type, parentIndex){
		if(type && type == 'subPopup')
			$scope.edit.popups[parentIndex].subPopups[index].showSubPopup = true;
		else if(type && type == 'popup')
			$scope.edit.popups[index].showText = true;
		else
			$scope.edit.activeEdit[index].showText = true;
		$scope.setDontChangeSettings();
	}

	$scope.addRowInMiddle = function(index, type, parentIndex){
		if(type && type == 'subPopup'){
			if(index == $scope.edit.popups[parentIndex].subPopups.length-1){// just adding to the end
				$scope.addRowAtEnd(type, parentIndex);
			}else{
				var newSubPopup = $scope.newSubPopup();
				$scope.edit.popups[parentIndex].subPopups.splice(index+1, 0, newSubPopup);
			}
		}else if(type && type == 'popup'){
			if(index == $scope.edit.popups.length-1){// just adding to the end
				$scope.addRowAtEnd(type);
			}else{
				var newPopup = $scope.getNewPopupObject();
				newPopup.endtime = $scope.edit.popups[index].endtime;
				$scope.edit.popups[index].endtime = "";
				newPopup.showRefText = false;
				$scope.edit.popups.splice(index+1, 0, newPopup);
				$timeout(function(){// allows focus to be put on the new line's start time. timeout makes it wait for the page to be rendered
					var id = 'starttimeP' + (parseInt(index) + 1);
					document.getElementById(id).focus();
				}, 0);
			}
		}else{
			if(index == $scope.edit.activeEdit.length - 1){//if row getting added at the end
				$scope.addRowAtEnd();
				// newCaption.sequence = ((parseInt($scope.edit.activeEdit[index].sequence)) + 1000);
				// $scope.edit.activeEdit.push(newCaption);
				// $("#captionArea").scrollTop($("#captionArea")[0].scrollHeight - $("#captionArea").height());
			}else{
				var newCaption = $scope.getNewCaptionObject();
				newCaption.endtime = $scope.edit.activeEdit[index].endtime;
				$scope.edit.activeEdit[index].endtime = "";
				newCaption.showRefText = false;

				newCaption.sequence = ((parseInt($scope.edit.activeEdit[index+1].sequence) - parseInt($scope.edit.activeEdit[index].sequence))/2) + parseInt($scope.edit.activeEdit[index].sequence);
				$scope.edit.activeEdit.splice(index+1, 0, newCaption);
				
				
				$timeout(function(){// allows focus to be put on the new line's start time. timeout makes it wait for the page to be rendered
					var id = 'starttime' + (parseInt(index) + 1);
					document.getElementById(id).focus();
				}, 0);
			}
		}
		$scope.setDontChangeSettings();
	}

	$scope.removeRow = function(index, type, parentIndex){
		if(type && type == 'subPopup')
			$scope.edit.popups[parentIndex].subPopups[index].showSubPopup = false;
		else if(type && type == 'popup')
			$scope.edit.popups[index].showText = false;
		else
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

	$scope.audioCommand = function(what, element){
		var audioElement = document.getElementById('previewAudioPlayer');
		if(what == 'addTimeUpdate'){
			audioElement.addEventListener("timeupdate", function(){
				element(audioElement.currentTime);
			}, false);
		}else if(what == 'load'){
			audioElement.load();
		}
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

	$scope.buildPopupListForRepeater = function(){
		if($routeParams.how == 'new'){
			alert("new is not implemented at this time for popups");
		}else if($routeParams.how == "modify"){
			if($routeParams.lang != 'none' && $routeParams.refLang == "none"){
				$scope.edit.popups = angular.copy($scope.video.popups.defaultLanguage);// TODOHERE make sure scope.video.popups is getting set

				// set up all the fields for the popups
				for (var i = $scope.edit.popups.length - 1; i >= 0; i--) {
					var popup = $scope.edit.popups[i];
					popup.showText = true;
					popup.showRefText = false;
					popup.refText = "";
					popup.startTimeError = $rootScope.flags.none;
					popup.endTimeError = $rootScope.flags.none;
					popup.textError = $rootScope.flags.none;
					popup.dontUseThisForTesting = false;
					popup.startTimeErrorMessage = "";
					popup.endTimeErrorMessage = "";
					popup.textErrorMessage = "";
					popup.language = $routeParams.lang;
					popup.starttime = $scope.convertLongToCaptionEditorTime(popup.startTime);
					popup.endtime = $scope.convertLongToCaptionEditorTime(popup.endTime);
					popup.text = popup.popupText;
					for (var j = popup.subPopups.length - 1; j >= 0; j--) {
						var subPopups = popup.subPopups[j];
						subPopups.showSubPopup = true;
						subPopups.startTime = $scope.convertLongToCaptionEditorTime(subPopups.startTime);
						subPopups.endTime = $scope.convertLongToCaptionEditorTime(subPopups.endTime);
					};
				};
				console.log($scope.edit.popups)
			}else
				alert("this isnt implemented, buildPopupListForRepeater");
			if($scope.edit.popups != undefined)
				$scope.testPopupsForSubmission($scope.edit.popups);// test the new captions
		}
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

	$scope.checkIfInError = function(index, whichField, type) {// called from main.html
		var editType = 'activeEdit';
		if(type && type == 'popup')
			editType = 'popups';

		if($scope.edit.showTestResults == 'yes'){
			if(whichField == "starttime"){
				if($scope.edit[editType][index].startTimeError == $rootScope.flags.invalid)
					return 'mFieldError';
				else if($scope.edit[editType][index].startTimeError == $rootScope.flags.none)
					return '';
				else
					return 'mFieldValid';
			}else if(whichField == "endtime"){
				if($scope.edit[editType][index].endTimeError == $rootScope.flags.invalid)
					return 'mFieldError';
				else if($scope.edit[editType][index].endTimeError == $rootScope.flags.none)
					return '';
				else
					return 'mFieldValid';
			}else if(whichField == "caption" || whichField == 'popup'){
				if($scope.edit[editType][index].textError == $rootScope.flags.invalid)
					return 'mFieldError';
				else if($scope.edit[editType][index].textError == $rootScope.flags.none)
					return '';
				else
					return 'mFieldValid';
			}else if(whichField == "displayName"){
				if($scope.edit[editType][index].displayNameError == $rootScope.flags.invalid)
					return 'mFieldError';
				else if($scope.edit[editType][index].displayNameError == $rootScope.flags.none)
					return '';
				else
					return 'mFieldValid';
			}else
				alert("the field name: " + whichField + " is not valid");
		}
		return '';
	}

	$scope.tests = {
		displayNameValid: function(captionsToTest, index){
			if(captionsToTest[index].displayName.length == 0){
				$scope.showErrorOnHoverMessage = true;
				captionsToTest[index].displayNameError = $rootScope.flags.invalid;
				captionsToTest[index].displayNameErrorMessage = "The display name cannot be blank";
			}else
				captionsToTest[index].displayNameError = $rootScope.flags.valid;
			return captionsToTest;
		},
		popupTextValid: function(captionsToTest, index){
			console.log("three", captionsToTest[index])
			if(captionsToTest[index].subPopups.length == 0 && captionsToTest[index].text.length == 0){
				console.log("bad")
				$scope.showErrorOnHoverMessage = true;
				captionsToTest[index].textError = $rootScope.flags.invalid;
				captionsToTest[index].textErrorMessage = "The popup text cannot be blank";
			}else
				captionsToTest[index].textError = $rootScope.flags.valid;
			
			return captionsToTest;
		},
		startTimeValid: function(captionsToTest, index){
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

			endTimeValid = $scope.tests.endTimeBeforeStartTime(captionsToTest[index]);
			if(endTimeValid != "valid"){
				$scope.showErrorOnHoverMessage = true;
				captionsToTest[index].endTimeError = $rootScope.flags.invalid;
				captionsToTest[index].endTimeErrorMessage += endTimeValid;
			}
			return captionsToTest;
		},
		captionValid: function(captionsToTest, index){
			var captionValid = $scope.tests.isCaptionValid(captionsToTest[index].text || captionsToTest[index].caption)
			if(captionValid != "valid"){
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
		endTimeBeforeStartTime: function(caption){
			var message  = "";
			if(caption.endtime < caption.starttime)
				message = "The end time is before the start time";
			if(message == "")
				return "valid";
			else
				return message;
		},
		isCaptionValid: function(caption){
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

	$scope.testPopupsForSubmission = function(popups){
		console.log("here")
		for (var i = popups.length - 1; i >= 0; i--) {
			var popup = popups[i];
			if(popup.showText == false)
				popup.dontUseThisForTesting = true;
			else{
				popups = $scope.tests.startTimeValid(popups, i);
				popups = $scope.tests.endTimeValid(popups, i);
				popups = $scope.tests.displayNameValid(popups, i);
				popups = $scope.tests.popupTextValid(popups, i);
			}
		};
		$scope.edit.showTestResults = 'yes';
		var hasErrors = $scope.tests.hasErrors(popups);
		if(hasErrors)
			$scope.showErrorOnHoverMessage = true;
		else
			$scope.showErrorOnHoverMessage = false;
		return hasErrors;
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
		var backup = angular.fromJson($scope.jsonStringOfBackupText);
		if(!$scope.testCaptionsForSubmission(backup.captions) && !$scope.testPopupsForSubmission(backup.popups)){
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

		// TODO change this to backup the ones that are show text false too, update backup restore
		var backupPopups = [];
		for (var i = 0; i < $scope.edit.popups.length; i++) {
			var popup = $scope.edit.popups[i];
			if(popup.showText){
				var tempPopup = {
					startTime: $scope.convertCaptionEditorTimeToLong(popup.starttime),
					endTime: $scope.convertCaptionEditorTimeToLong(popup.endtime),
					displayName: popup.displayName,
					popupText: popup.text,
					mediaId: popup.mediaId,
					languageId: languageId,
					filename: popup.filename
				};
				backupPopups.push(tempPopup);
			}
		};
		var backupData = {
			languageId:languageId,
			captions:backupCaptions,
			popups:backupPopups
		};
		$scope.jsonStringOfBackupText = angular.toJson(backupData);
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
		console.log($scope.edit.popups);
		$scope.saveMessage = "";
		if($scope.edit.activeEdit != undefined && $scope.edit.popups != undefined){
			if($scope.testCaptionsForSubmission($scope.edit.activeEdit) || $scope.testPopupsForSubmission($scope.edit.popups)){
				$scope.bigError = "Big error";
				$scope.showErrorOnHoverMessage = true;
				console.log("big error")
				$scope.saveMessage = "Fix errors first";
				$timeout(function(){
					$scope.saveMessage = "";
				}, 5000);
			}else{
				$scope.saveMessage = "Saving";
				console.log("generating final")

				// build captions
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
					}else if(caption.id != undefined && caption.id != 0)
						captionsFactory.deleteCaption(caption.id);
				};
				//submit function
				console.log("final captions: ", $scope.finalCaptions);

				// build popups
				$scope.finalPopups = [];
				for (var i = 0; i < $scope.edit.popups.length; i++) {
					var popup = $scope.edit.popups[i];
					if(popup.showText){
						var tempPopup = {
							id:popup.id || 0,
							startTime: $scope.convertCaptionEditorTimeToLong(popup.starttime),
							endTime: $scope.convertCaptionEditorTimeToLong(popup.endtime),
							displayName: popup.displayName,
							popupText: popup.text,
							mediaId: popup.mediaId,
							languageId: languageId,
							filename: popup.filename,
							subPopups:[]
						};
						if(popup.file)
							tempPopup.filename = popup.file.filename;
						for (var j = popup.subPopups.length - 1; j >= 0; j--) {
							var subPopup = popup.subPopups[j];
							console.log(subPopup)
							if(subPopup.showSubPopup){
								var tempSubPopup = {
									id:subPopup.id || 0,
									startTime: $scope.convertCaptionEditorTimeToLong(subPopup.startTime),
									endTime: $scope.convertCaptionEditorTimeToLong(subPopup.endTime),
									popupText:subPopup.popupText,
									popupId:subPopup.popupId || popup.id || 0,
									assetPosition:subPopup.assetPosition,
									filename:subPopup.filename
								};
								if(subPopup.file)
									tempSubPopup.filename = subPopup.file.filename;
							}else if(subPopup.id != undefined && subPopup.id != 0)
								popupsFactory.deleteSubPopup(subPopup.id);

							tempPopup.subPopups.push(tempSubPopup);
						};
						$scope.finalPopups.push(tempPopup);

					}else if(popup.id != undefined && popup.id != 0)
						popupsFactory.deletePopup(popup.id);
				};

				var captionsDefer = $q.defer();
				var popupsDefer = $q.defer();
				var uploadFilesDefer = $q.defer();
				captionsDefer.promise.then(function(){
					popupsDefer.promise.then(function(){
						$scope.saveMessage = "Uploading Files";
						uploadFilesDefer.promise.then(function(){
							if($scope.saveMessage != "Uploading Files")
								return;

							$scope.saveMessage = "Success";
							$timeout(function() {
								if($scope.saveMessage == "Success")
									$scope.saveMessage = "";
							}, 5000);
						});
					});
				})
				$scope.filesNeedToUpload = 0;
				$scope.filesUploaded = 0;

				captionsFactory.putCaptions($scope.finalCaptions).then(function(data){
					$scope.video.captions.defaultLanguage = data;
					$scope.buildCaptionListForRepeater();
					captionsDefer.resolve();
					if(data == null)
						$scope.saveMessage = "Error, please back up";
				});

				popupsFactory.putPopups($scope.finalPopups).then(function(newPopups){
					popupsDefer.resolve();
					for (var i = $scope.edit.popups.length - 1; i >= 0; i--) {
						var popup = $scope.edit.popups[i];

						// upload ones that have a file, this is set by the directive so they are new
						// search for this popup in the ones that just came back to get the new id

						for (var j = newPopups.length - 1; j >= 0; j--) {
							var newPopup = newPopups[j];
							if(newPopup.mediaId == popup.mediaId &&
								newPopup.startTime == $scope.convertCaptionEditorTimeToLong(popup.starttime) &&
								newPopup.endTime == $scope.convertCaptionEditorTimeToLong(popup.endtime) &&
								newPopup.displayName == popup.displayName &&
								newPopup.popupText == popup.text){// get the popups from each list that match

								popup.id = newPopup.id;

								if(popup.file){
									$scope.filesNeedToUpload++;
									$scope.uploadFileForPopup(popup, newPopup.id, uploadFilesDefer, popup.file.filename);
								}

								// go through subpopups to upload files
								$scope.uploadFilesForSubPopups(popup, newPopup, uploadFilesDefer);
								break;
							}
						};
					};
					if($scope.filesNeedToUpload == 0)// in case there are no files to upload
						uploadFilesDefer.resolve();
				});
			}
		}	
	}

	$scope.uploadFilesForSubPopups = function(oldPopup, newPopupFromServer, uploadFilesDefer){
		console.log(oldPopup, newPopupFromServer, uploadFilesDefer)
		for (var i = oldPopup.subPopups.length - 1; i >= 0; i--) {
			var oldSub = oldPopup.subPopups[i];
			for (var j = newPopupFromServer.subPopups.length - 1; j >= 0; j--) {
				var newSub = newPopupFromServer.subPopups[j];
				console.log(i, newSub.popupText, oldSub.popupText, $scope.convertCaptionEditorTimeToLong(oldSub.startTime) == newSub.startTime ,
					$scope.convertCaptionEditorTimeToLong(oldSub.endTime) == newSub.endTime ,
					oldSub.popupText == newSub.popupText ,					oldSub.assetPosition == newSub.assetPosition, oldSub.assetPosition, newSub.assetPosition);
				if($scope.convertCaptionEditorTimeToLong(oldSub.startTime) == newSub.startTime &&
					$scope.convertCaptionEditorTimeToLong(oldSub.endTime) == newSub.endTime &&
					oldSub.popupText == newSub.popupText &&
					oldSub.assetPosition == newSub.assetPosition){

					oldSub.id = newSub.id;
					console.log(oldSub)
					if(oldSub.file){
						$scope.filesNeedToUpload++;
						console.log(oldSub)
						$scope.uploadFileForSubPopup(oldSub, newSub.id, uploadFilesDefer, oldSub.file.filename);
					}
				}
			};
		};
	}

	$scope.uploadFileForSubPopup = function(subPopup, id, defer, newFilename){
		console.log(subPopup, id)
		popupsFactory.savePopupSubPopupFile(subPopup.file.base64Data, null, subPopup.file.contentType, id).then(function(data){
			subPopup.filenameInBucket = data;
			subPopup.bucketId = 1;
			subPopup.file = null;
			subPopup.filename = newFilename;
			$scope.filesUploaded++;
			if($scope.filesUploaded == $scope.filesNeedToUpload){
				console.log($scope.edit.popups)
				defer.resolve();
			}
		}, function(data){
			alert("error uploading file connected to subpopup: " + subPopup.popupText + ", the rest of the subPopup was saved except for the file. Please reload the page and try to upload the file again");
			$scope.saveMessage = "Error";
			console.log("error", id, data);
		});
	}

	$scope.uploadFileForPopup = function(popup, id, defer, newFilename){
		popupsFactory.savePopupSubPopupFile(popup.file.base64Data, id, popup.file.contentType, null).then(function(data){

			popup.filenameInBucket = data;
			popup.bucketId = 1;
			popup.file = null;
			popup.filename = newFilename;
			$scope.filesUploaded++;
			if($scope.filesUploaded == $scope.filesNeedToUpload)
				defer.resolve();
			

		}, function(data){
			alert("error uploading file connected to popup: " + popup.displayName + ", the rest of the popup information was saved except for files. Please reload the page and try to upload the audio files again");
			$scope.saveMessage = "Error";
			console.log("error", id, data);
		});
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

	$scope.convertQuickTime = function(whichField, index, type){// changes time typed in 123 to 1.23 OR 14256 to 1:42:56
		var editType = 'activeEdit';
		if(type && type == 'popup')
			editType = 'popups';

		// console.log(whichField, index, $scope.edit.activeEdit[index].starttime.length)
		var hours = 0, minutes = 0, seconds = 0, frames = 0;
		if(whichField == 'start'){
			if($scope.edit[editType][index].starttime == undefined || $scope.edit[editType][index].starttime == ''){
				return;//invalid field
			}else if(!$scope.tests.areNumbers($scope.edit[editType][index].starttime)){// there are already special characters in the field. use the smarter time parser
				var returnedObject = $scope.addLeadingZerosToWholeTime($scope.edit[editType][index].starttime);
				if(returnedObject.hasError){
					$scope.edit[editType][index].startTimeError = $rootScope.flags.invalid;
					$scope.edit[editType][index].startTimeErrorMessage = returnedObject.errorMessage;
				}else{
					$scope.edit[editType][index].starttime = returnedObject.wholeTime;
					$scope.edit[editType][index].startTimeError = $rootScope.flags.valid;
					$scope.edit[editType][index].startTimeErrorMessage = '';
				}
				$scope.tests.startTimeValid($scope.edit[editType], index);
				return;
			}else if($scope.edit[editType][index].starttime.length > 8){
				return;// do nothing, they typed too many numbers
			}else if($scope.edit[editType][index].starttime.length > 6){// take the time assuming that fields are complete, starting with frames and then moving left
				frames = 	$scope.edit[editType][index].starttime.slice($scope.edit[editType][index].starttime.length - 2);
				seconds = 	$scope.edit[editType][index].starttime.slice($scope.edit[editType][index].starttime.length - 4, $scope.edit[editType][index].starttime.length - 2);
				minutes = 	$scope.edit[editType][index].starttime.slice($scope.edit[editType][index].starttime.length - 6, $scope.edit[editType][index].starttime.length - 4);
				hours = 	$scope.edit[editType][index].starttime.slice(0, $scope.edit[editType][index].starttime.length - 6);
				console.log(frames,seconds,minutes,hours)
			}else if($scope.edit[editType][index].starttime.length > 4){
				frames = 	$scope.edit[editType][index].starttime.slice($scope.edit[editType][index].starttime.length - 2);
				seconds = 	$scope.edit[editType][index].starttime.slice($scope.edit[editType][index].starttime.length - 4, $scope.edit[editType][index].starttime.length - 2);
				minutes = 	$scope.edit[editType][index].starttime.slice(0, $scope.edit[editType][index].starttime.length - 4);
				console.log(frames,seconds,minutes,hours)
			}else if($scope.edit[editType][index].starttime.length > 2){
				frames = 	$scope.edit[editType][index].starttime.slice($scope.edit[editType][index].starttime.length - 2);
				seconds = 	$scope.edit[editType][index].starttime.slice(0, $scope.edit[editType][index].starttime.length - 2);
				console.log(frames,seconds,minutes,hours)
			}else if($scope.edit[editType][index].starttime.length > 0)
				frames = 	$scope.edit[editType][index].starttime;
			console.log(frames,seconds,minutes,hours)
			if($scope.edit[editType][index].starttime.length != 0){
				$scope.edit[editType][index].starttime = $scope.addLeadingZeros(hours, 2) + ':' + $scope.addLeadingZeros(minutes, 2) + ':' + $scope.addLeadingZeros(seconds, 2) + '.' + $scope.addLeadingZeros(frames, 2);
				$scope.tests.startTimeValid($scope.edit[editType], index);
			}
		}else if(whichField == 'end'){
			if($scope.edit[editType][index].endtime == undefined || $scope.edit[editType][index].endtime == ''){
				//invalid field
				console.log("invalid field, should never be here");
				return;
			}else if(!$scope.tests.areNumbers($scope.edit[editType][index].endtime)){// there are already special characters in the field. use the smarter time parser
				var returnedObject = $scope.addLeadingZerosToWholeTime($scope.edit[editType][index].endtime);
				if(returnedObject.hasError){
					$scope.edit[editType][index].endTimeError = $rootScope.flags.invalid;
					$scope.edit[editType][index].endTimeErrorMessage = returnedObject.errorMessage;
				}else{
					$scope.edit[editType][index].endtime = returnedObject.wholeTime;
					$scope.edit[editType][index].endTimeError = $rootScope.flags.valid;
					$scope.edit[editType][index].endTimeErrorMessage = '';
				}
				$scope.tests.endTimeValid($scope.edit[editType], index);
				$scope.tests.oneRowTimesOverlapping($scope.edit[editType], index);
				return;
			}else if($scope.edit[editType][index].endtime.length > 8){
				// do nothing, they typed too many numbers
				console.log("too many numbers");
				return;
			}else if($scope.edit[editType][index].endtime.length > 6){// take the time assuming that fields are complete, starting with frames and then moving left
				frames = 	$scope.edit[editType][index].endtime.slice($scope.edit[editType][index].endtime.length - 2);
				seconds = 	$scope.edit[editType][index].endtime.slice($scope.edit[editType][index].endtime.length - 4, $scope.edit[editType][index].endtime.length - 2);
				minutes = 	$scope.edit[editType][index].endtime.slice($scope.edit[editType][index].endtime.length - 6, $scope.edit[editType][index].endtime.length - 4);
				hours = 	$scope.edit[editType][index].endtime.slice(0, $scope.edit[editType][index].endtime.length - 6);
			}else if($scope.edit[editType][index].endtime.length > 4){
				frames = 	$scope.edit[editType][index].endtime.slice($scope.edit[editType][index].endtime.length - 2);
				seconds = 	$scope.edit[editType][index].endtime.slice($scope.edit[editType][index].endtime.length - 4, $scope.edit[editType][index].endtime.length - 2);
				minutes = 	$scope.edit[editType][index].endtime.slice(0, $scope.edit[editType][index].endtime.length - 4);
			}else if($scope.edit[editType][index].endtime.length > 2){
				frames = 	$scope.edit[editType][index].endtime.slice($scope.edit[editType][index].endtime.length - 2);
				seconds = 	$scope.edit[editType][index].endtime.slice(0, $scope.edit[editType][index].endtime.length - 2);
				console.log(frames, seconds)
			}else if($scope.edit[editType][index].endtime.length > 0)
				frames = 	$scope.edit[editType][index].endtime;
			else{
				console.log('fail, should never get here');
				return;
			}
			if($scope.edit[editType][index].endtime.length != 0){
				$scope.edit[editType][index].endtime = $scope.addLeadingZeros(hours, 2) + ':' + $scope.addLeadingZeros(minutes, 2) + ':' + $scope.addLeadingZeros(seconds, 2) + '.' + $scope.addLeadingZeros(frames, 2);
				$scope.tests.endTimeValid($scope.edit[editType], index);
				$scope.tests.oneRowTimesOverlapping($scope.edit[editType], index);
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
	$scope.upArrow = function(index, startOrEnd, type){// true start, false end
		var editType = 'activeEdit';
		if(type && type == 'popup')
			editType = 'popups';

		if(startOrEnd == undefined)
			return;
		if(startOrEnd){
			if($scope.edit[editType][index].starttime == ''){// insead of incrementing an empty field, take the time from the previous row's end
				if($scope.edit[editType][index-1] && $scope.edit[editType][index-1].endtime != undefined && $scope.edit[editType][index - 1].endtime != '')
					$scope.edit[editType][index].starttime = $scope.correctTheTimeGreaterThan($scope.edit[editType][index - 1].endtime, 0, "seconds");
				else
					$scope.edit[editType][index].starttime = $scope.convertLongToCaptionEditorTime(0);
			}else
				$scope.edit[editType][index].starttime = $scope.correctTheTimeGreaterThan($scope.edit[editType][index].starttime, 1, "seconds");
			$scope.videoToThisTime($scope.edit[editType][index].starttime);
		}else{
			if($scope.edit[editType][index].endtime == ''){// instead of incrementing an empty field, take the start time of this row
				if($scope.edit[editType][index] && $scope.edit[editType][index].starttime != undefined && $scope.edit[editType][index].starttime != '')
					$scope.edit[editType][index].endtime = $scope.correctTheTimeGreaterThan($scope.edit[editType][index].starttime, 0, "seconds");
				else
					$scope.edit[editType][index].endtime = $scope.correctTheTimeGreaterThan($scope.convertLongToCaptionEditorTime(0), 1, "seconds");
			}else
				$scope.edit[editType][index].endtime = $scope.correctTheTimeGreaterThan($scope.edit[editType][index].endtime, 1, "seconds");
			$scope.videoToThisTime($scope.edit[editType][index].endtime);
		}
		
	}

	// Minuses one second from the time per down arrow press
	$scope.downArrow = function(index, startOrEnd, type){// true start, false end
		var editType = 'activeEdit';
		if(type && type == 'popup')
			editType = 'popups';

		if(startOrEnd == undefined)
			return;
		if(startOrEnd){
			if($scope.edit[editType][index].starttime != undefined && $scope.edit[editType][index].starttime != ''){
				$scope.edit[editType][index].starttime = $scope.correctTheTimeLessThan($scope.edit[editType][index].starttime, 1, "seconds");
				$scope.videoToThisTime($scope.edit[editType][index].starttime);
			}else
				$scope.edit[editType][index].starttime = $scope.correctTheTimeLessThan($scope.convertLongToCaptionEditorTime(0), 0, "seconds");
		}else{
			if($scope.edit[editType][index].endtime != undefined && $scope.edit[editType][index].endtime != '')
				$scope.edit[editType][index].endtime = $scope.correctTheTimeLessThan($scope.edit[editType][index].endtime, 1, "seconds");
			else{
				if($scope.edit[editType][index].starttime != undefined && $scope.edit[editType][index].starttime != ''){
					$scope.edit[editType][index].endtime = $scope.correctTheTimeLessThan($scope.edit[editType][index].starttime, 0, "seconds");
					$scope.videoToThisTime($scope.edit[editType][index].endtime);
				}else
					$scope.edit[editType][index].endtime = $scope.correctTheTimeLessThan($scope.convertLongToCaptionEditorTime(0), 0, "seconds");
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

	// new subPopup stuff

	$scope.addSubPopupToPopup = function(index, popup){
		var popup = $scope.edit.popups[index];
		popup.subPopups = [];
		popup.subPopups.push($scope.newSubPopup(popup.id));
	}

	$scope.newSubPopup = function(popupId){
		var subPopup = {
			startTime:"",
			endTime:"",
			popupText:"",
			popupId:popupId,
			assetPosition:0,
			filename:"",
			bucketId:0,
			id:0,
			extension:"",
			filenameInBucket:"",
			showSubPopup:true
		}
		return subPopup;
	}

	$scope.upArrowSub = function(index, startOrEnd, type, popupIndex){// true start, false end
		var editType = '';
		var subEditType = "";
		if(type && type == 'subPopup'){
			editType = 'popups';
			subEditType = 'subPopups';
		}

		if(startOrEnd == undefined)
			return;
		if(startOrEnd){
			if($scope.edit[editType][popupIndex][subEditType][index].startTime == ''){// insead of incrementing an empty field, take the time from the previous row's end
				if($scope.edit[editType][popupIndex][subEditType][index-1] && $scope.edit[editType][popupIndex][subEditType][index-1].endTime != undefined && $scope.edit[editType][popupIndex][subEditType][index - 1].endTime != '')
					$scope.edit[editType][popupIndex][subEditType][index].startTime = $scope.correctTheTimeGreaterThan($scope.edit[editType][popupIndex][subEditType][index - 1].endTime, 0, "seconds");
				else
					$scope.edit[editType][popupIndex][subEditType][index].startTime = $scope.convertLongToCaptionEditorTime(0);
			}else
				$scope.edit[editType][popupIndex][subEditType][index].startTime = $scope.correctTheTimeGreaterThan($scope.edit[editType][popupIndex][subEditType][index].startTime, 1, "seconds");
			// $scope.videoToThisTime($scope.edit[editType][popupIndex][subEditType][index].startTime);
		}else{
			if($scope.edit[editType][popupIndex][subEditType][index].endTime == ''){// instead of incrementing an empty field, take the start time of this row
				if($scope.edit[editType][popupIndex][subEditType][index] && $scope.edit[editType][popupIndex][subEditType][index].startTime != undefined && $scope.edit[editType][popupIndex][subEditType][index].startTime != '')
					$scope.edit[editType][popupIndex][subEditType][index].endTime = $scope.correctTheTimeGreaterThan($scope.edit[editType][popupIndex][subEditType][index].startTime, 0, "seconds");
				else
					$scope.edit[editType][popupIndex][subEditType][index].endTime = $scope.correctTheTimeGreaterThan($scope.convertLongToCaptionEditorTime(0), 1, "seconds");
			}else
				$scope.edit[editType][popupIndex][subEditType][index].endTime = $scope.correctTheTimeGreaterThan($scope.edit[editType][popupIndex][subEditType][index].endTime, 1, "seconds");
			// $scope.videoToThisTime($scope.edit[editType][popupIndex][subEditType][index].endTime);
		}
		
	}

	// Minuses one second from the time per down arrow press
	$scope.downArrowSub = function(index, startOrEnd, type, popupIndex){// true start, false end
		var editType = '';
		var subEditType = "";
		if(type && type == 'subPopup'){
			editType = 'popups';
			subEditType = 'subPopups';
		}

		if(startOrEnd == undefined)
			return;
		if(startOrEnd){
			if($scope.edit[editType][popupIndex][subEditType][index].startTime != undefined && $scope.edit[editType][popupIndex][subEditType][index].startTime != ''){
				$scope.edit[editType][popupIndex][subEditType][index].startTime = $scope.correctTheTimeLessThan($scope.edit[editType][popupIndex][subEditType][index].startTime, 1, "seconds");
				// $scope.videoToThisTime($scope.edit[editType][popupIndex][subEditType][index].startTime);
			}else
				$scope.edit[editType][popupIndex][subEditType][index].startTime = $scope.correctTheTimeLessThan($scope.convertLongToCaptionEditorTime(0), 0, "seconds");
		}else{
			if($scope.edit[editType][popupIndex][subEditType][index].endTime != undefined && $scope.edit[editType][popupIndex][subEditType][index].endTime != '')
				$scope.edit[editType][popupIndex][subEditType][index].endTime = $scope.correctTheTimeLessThan($scope.edit[editType][popupIndex][subEditType][index].endTime, 1, "seconds");
			else{
				if($scope.edit[editType][popupIndex][subEditType][index].startTime != undefined && $scope.edit[editType][popupIndex][subEditType][index].startTime != ''){
					$scope.edit[editType][popupIndex][subEditType][index].endTime = $scope.correctTheTimeLessThan($scope.edit[editType][popupIndex][subEditType][index].startTime, 0, "seconds");
					// $scope.videoToThisTime($scope.edit[editType][popupIndex][subEditType][index].endTime);
				}else
					$scope.edit[editType][popupIndex][subEditType][index].endTime = $scope.correctTheTimeLessThan($scope.convertLongToCaptionEditorTime(0), 0, "seconds");
			}
		}
	}






















//https://s3-us-west-2.amazonaws.com/captioneditor-uuid-f6f6be1d-3c04-4c1c-82e1-ec58fce68747/ph7j39l09amcebpjsqbc61v91o
	mediaFactory.getMediaById($routeParams.videoId).then(function(data){
		var waitDefer1 = $q.defer();
		var waitDefer2 = $q.defer();
		$scope.video.data = data;
		console.log(data)
		for (var i = $scope.editModes.length - 1; i >= 0; i--) {//setup $scope.edit.mode model from the route params, allows dropdown to show correct mode
			if($scope.editModes[i].type == $routeParams.how){
				$scope.edit.mode = $scope.editModes[i];
				break;
			}
		};
		bucketsFactory.getCaptionEditorBucket().then(function(bucket){
			$scope.captionEditorBucket = bucket;
			var videoPath = "https://s3-us-west-2.amazonaws.com/" + bucket.name + "/" + $scope.video.data.filenameInBucket;
			$scope.videoCommand("addSource", videoPath);
			$scope.videoCommand("setup");
			$scope.videoCommand("load");
			$scope.videoCommand("addTimeUpdate", $scope.showSubtitleForTime);
			waitDefer1.resolve();
		});
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
			waitDefer2.resolve();
		});
		waitDefer1.promise.then(function(){
			waitDefer2.promise.then(function(){
				$scope.prepareVideo();
			});
		});
	});
}
















