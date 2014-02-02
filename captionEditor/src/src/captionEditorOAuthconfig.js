var cfg = {};// configuration parameters, must be outside for logout to see it
(function(exp) {

	// helper function to configure oauth and ensure a token is ready
	exp.oa_configure = function() {

		// look at the current host and set up client respectively
		var h = location.host;
		if (h == "cdn.mtc.byu.edu") {
			cfg["oaClientId"]  = "captioneditor-cdn";
			cfg["oaMyUrl"]     = "https://cdn.mtc.byu.edu/captioneditor/";
			cfg["oaServerUrl"] = "https://security.mtc.byu.edu/";
			cfg["oaDbUrl"]     = "https://app.mtc.byu.edu/mediaportal/";
			cfg["oaScopes"]    = ["user","media-api"];
	
		} else if (h == "localhost" || h == "local") {
			cfg["oaClientId"]  = "captioneditor-local";
			cfg["oaMyUrl"]     = "https://localhost/captioneditor/";
			cfg["oaServerUrl"] = "https://security.mtc.byu.edu/";
			cfg["oaDbUrl"]     = "https://localhost/mediaportal/";
			cfg["oaScopes"]    = ["user","media-api"];
		
		// } else if (h == "10.5.26.77") {// Micael Patterson's computer
		// 	cfg["oaClientId"]  = "teacherportal-patty";
		// 	cfg["oaMyUrl"]     = "https://10.5.25.77/onboarding/";
		// 	cfg["oaServerUrl"] = "https://auth.mtc.byu.edu/";
		// 	cfg["oaDbUrl"]     = "https://10.5.25.77/teachers/";
		// 	cfg["oaScopes"]    = ["user","tp-api"];
		
		// } else if (h == "10.5.26.110") {// Cameron McCord's computer
		// 	cfg["oaClientId"]  = "teacherportal-cam";
		// 	cfg["oaMyUrl"]     = "https://10.5.25.110/onboarding/";
		// 	cfg["oaServerUrl"] = "https://auth.mtc.byu.edu/";
		// 	cfg["oaDbUrl"]     = "https://10.5.25.110/teachers/";
		// 	cfg["oaScopes"]    = ["user","tp-api"];
		
		} else throw new Error("No configuration in authconfig.");
	
		// add configuration for client to auth library
		var ac = {};
		ac[cfg.oaClientId] = {
			"client_id"        : cfg.oaClientId,
			"redirect_uri"     : cfg.oaMyUrl,
			"authorization"    : cfg.oaServerUrl + "services/oauth/authorize-implicit",
			"authenticate_thru": "byu"  // can be "byu", "lds", or "either"
		};
		jso_configure(ac);
	
		// ensure the client has a token for these scopes; if not, it will redirect away from this page and then back
		var ts = {};
		ts[cfg.oaClientId] = cfg.oaScopes;
		jso_ensureTokens(ts);
	};
	
	exp.oa_getToken = function() {
		return jso_getToken(cfg.oaClientId, cfg.oaScopes);
	};

	exp.oa_getDbUrl = function() {
		return cfg.oaDbUrl;
	};

	// helper function to redirect to a logout url on the security server
	exp.oa_logout = function() {
		window.location = cfg.oaServerUrl + "j_spring_security_logout";
	};
}(window));