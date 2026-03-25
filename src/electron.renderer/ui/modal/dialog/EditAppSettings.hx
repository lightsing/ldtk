package ui.modal.dialog;

class EditAppSettings extends ui.modal.Dialog {
	var anyChange = false;
	var needRestart = false;

	public function new() {
		super();

		addClose();
		updateForm();
	}

	function updateForm() {
		// Init
		loadTemplate("editAppSettings", {
			app: Const.APP_NAME,
			updateVer: App.ME.pendingUpdate==null ? null : App.ME.pendingUpdate.ver,
			// i18n: template strings
			title: L.t._("Application settings"),
			updateAvailable: L.t._("A new update is available!"),
			installLabel: L.t._("Install"),
			sectionGeneral: L.t._("General"),
			labelLanguage: L.t._("Language"),
			infoLanguage: L.t._("Select the display language for LDtk. A restart is required to apply the change."),
			labelOpenLastProject: L.t._("Re-open last project"),
			infoOpenLastProject: L.t._("If enabled, ::app:: will automatically re-open your last project and select the last level you were in.", {app: Const.APP_NAME}),
			sectionVisuals: L.t._("Visuals"),
			labelAppScale: L.t._("General UI scale"),
			infoAppScale: L.t._("This setting will affect the whole User Interface size."),
			labelFontScale: L.t._("Level UI scale"),
			infoFontScale: L.t._("This setting will only affect the size of texts and icons in the EDITOR VIEW (including entities custom fields and level custom fields)."),
			labelFieldsRender: L.t._("Entity fields aspect"),
			infoFieldsRender: L.t._("This option controls the visual aspect of custom entity fields in the editor."),
			labelNearbyTiles: L.t._("\"Nearby levels\" tiles rendering distance"),
			infoNearbyTiles: L.t._("If enabled, the tiles from nearby levels will also be rendered, to help you when painting transitions between maps. Please note that this could have a significant impact on performances for large levels."),
			labelSingleLayerMode: L.t._("Single-layer mode intensity"),
			infoSingleLayerMode: L.t._("When the \"single-layer\" mode is enabled, this setting defines the intensity of the fading effect applied to other layers."),
			labelFullScreen: L.t._("Start in fullscreen mode"),
			infoFullScreen: L.t._("Set default \"Full screen\" state when starting ::app::. You may also toggle fullscreen mode at any time using the F11 key.", {app: Const.APP_NAME}),
			labelColorBlind: L.t._("Prefer color-blind colors"),
			infoColorBlind: L.t._("Enable this option to use color-blind friendly colors by default for newly created entities, enums or intGrid values."),
			labelBlurMask: L.t._("Fade LDtk window when not focused"),
			infoBlurMask: L.t._("If enabled, the LDtk window will be grayed out when it is not focused."),
			sectionControls: L.t._("Controls"),
			labelMouseWheelSpeed: L.t._("Mouse wheel speed"),
			infoMouseWheelSpeed: L.t._("This setting affects the zoom in/out speed when using the mouse wheel."),
			labelAutoSwitchOnZoom: L.t._("World view with mouse wheel"),
			infoAutoSwitchOnZoom: L.t._("This setting allows to automatically switch to the World view when zooming out from a level. You can then zoom back in to any level to select it."),
			labelNavKeys: L.t._("Navigation keys layout"),
			infoNavKeys: L.t._("Navigation keys are used to navigate through the palette of values in a layer. For example, in a Tiles layer, you can navigate through the different tiles using these keys."),
			sectionAdvanced: L.t._("Advanced options"),
			labelGpu: L.t._("Try to use best GPU"),
			infoGpu: L.t._("When enabled, ::app:: will always try to use the best GPU available on your system, resulting in better performances. This might use extra battery life.", {app: Const.APP_NAME}),
			recommended: L.t._("Recommended"),
			labelAutoUpdate: L.t._("Auto update"),
			infoAutoUpdate: L.t._("When enabled, ::app:: will download and install new updates fully automatically. This is strongly RECOMMENDED as many updates contain important bug fixes and new features.", {app: Const.APP_NAME}),
			unsupportedWindows: L.t._("Only supported on Windows."),
			labelLogFile: L.t._("Log file"),
			infoLogFile: L.t._("The LOG file is only useful when reporting bugs. You can attach it to an e-mail or when you create an issue on GitHub site. It doesn't contain any sensitive or personal information, except used file paths."),
		});
		var jForm = jContent.find(".form");
		jForm.off().find("*").off();

		// Update available
		if( App.ME.pendingUpdate==null )
			jContent.find(".update").hide();
		else {
			jContent.find(".update").click(_->{
				if( App.ME.pendingUpdate.github ) {
					App.ME.checkForUpdate();
				}
				else
					electron.Shell.openExternal(Const.DOWNLOAD_URL);
				close();
			});
		}

		// Log button
		jContent.find(".logPath").text( JsTools.getLogPath() );
		jContent.find( "button.viewLog").click( (_)->{
			App.LOG.flushToFile();
			var raw = NT.readFileString( JsTools.getLogPath() );
			var te = new TextEditor(raw, "LDtk logs", LangLog);
			te.scrollToEnd();
		});
		jContent.find( "button.locateLog").click( (_)->JsTools.locateFile( JsTools.getLogPath(), true ) );

		// Language selector
		var jLang = jForm.find("#language");
		jLang.empty();
		var selectedLang = settings.v.language != null ? settings.v.language : Lang.CUR;
		for(lang in Lang.SUPPORTED_LANGUAGES) {
			var jOpt = new J('<option value="${lang.code}"/>');
			jLang.append(jOpt);
			jOpt.text(lang.name);
			if( lang.code==selectedLang )
				jOpt.prop("selected",true);
		}
		jLang.change( (_)->{
			settings.v.language = jLang.val();
			onSettingChanged();
			needRestart = true;
		});

		// World mode using mousewheel
		var i = new form.input.EnumSelect(
			jForm.find("#autoSwitchOnZoom"),
			Settings.AutoWorldModeSwitch,
			false,
			()->settings.v.autoWorldModeSwitch,
			(v)->{
				settings.v.autoWorldModeSwitch = v;
				onSettingChanged();
			},
			(v)->return switch v {
				case Never: L.t._("Never");
				case ZoomOutOnly: L.t._("Switch when zooming out");
				case ZoomInAndOut: L.t._("Switch when zooming in or out (default)");
			}
		);

		// GPU
		var i = Input.linkToHtmlInput(settings.v.useBestGPU, jForm.find("#gpu"));
		i.onChange = ()->{
			onSettingChanged();
			needRestart = true;
		}

		// Auto update
		var i = Input.linkToHtmlInput(settings.v.autoInstallUpdates, jForm.find("#autoUpdate"));
		i.onChange = ()->{
			onSettingChanged();
			needRestart = true;
		}
		i.setEnabled( NT.isWindows() );
		var jUnsupported = jForm.find("#autoUpdate").siblings(".unsupported");
		if( NT.isWindows() )
			jUnsupported.hide();
		else
			jUnsupported.show();

		// Fullscreen
		var i = Input.linkToHtmlInput(settings.v.startFullScreen, jForm.find("#startFullScreen"));
		i.onValueChange = (v)->{
			ET.setFullScreen(v);
			onSettingChanged();
			App.ME.updateBodyClasses();
		}

		// Single layer mode intensity
		var allValues = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1];
		if( !allValues.contains(settings.v.singleLayerModeIntensity) ) {
			for(v in allValues)
				if( v>=settings.v.singleLayerModeIntensity) {
					settings.v.singleLayerModeIntensity = v;
					break;
				}
		}
		JsTools.createValuesSelect(
			jForm.find("#singleLayerModeIntensity"),
			settings.v.singleLayerModeIntensity,
			allValues,
			false,
			0.9,
			(v)->Std.string(v*100)+"%",
			(v)->{
				settings.v.singleLayerModeIntensity = v;
				onSettingChanged();
			}
		);

		// Nearby tiles rendering distance
		var allValues = [0, 1, 1.5, 2];
		if( !allValues.contains(settings.v.nearbyTilesRenderingDist) ) {
			for(v in allValues)
				if( v>=settings.v.nearbyTilesRenderingDist) {
					settings.v.nearbyTilesRenderingDist = v;
					break;
				}
		}
		JsTools.createValuesSelect(
			jForm.find("#nearbyTilesRenderingDist"),
			settings.v.nearbyTilesRenderingDist,
			allValues,
			false,
			1,
			(v)->switch v {
				case 0: L.t._("Disabled");
				case _: settings.getNearbyTilesRenderingDistPx(v)+" "+L.t._("pixels");
			},
			(v)->{
				settings.v.nearbyTilesRenderingDist = v;
				onSettingChanged();
			}
		);

		// Load last project
		var i = Input.linkToHtmlInput(settings.v.openLastProject, jForm.find("#openLastProject"));
		i.onValueChange = (v)->{
			if( !v )
				settings.v.lastProject = null;
			else if( Editor.exists() )
				Editor.ME.saveLastProjectInfos();
			onSettingChanged();
		}

		// Color blind
		var i = Input.linkToHtmlInput(settings.v.colorBlind, jForm.find("#colorBlind"));
		i.onChange = ()->onSettingChanged();

		// Blur mask
		var i = Input.linkToHtmlInput(settings.v.blurMask, jForm.find("#blurMask"));
		i.onChange = ()->onSettingChanged();

		// Fields render
		var jSelect = jForm.find("#fieldsRender");
		jSelect.empty();
		for(k in Settings.FieldsRender.getConstructors()) {
			var nk = Settings.FieldsRender.createByName(k);
			var jOpt = new J('<option value="$k"/>');
			jSelect.append(jOpt);
			jOpt.text(switch nk {
				case FR_Outline: L.t._("Outlined texts (default)");
				case FR_Table: L.t._("Opaque tables");
			});
			if( settings.v.fieldsRender==nk )
				jOpt.prop("selected",true);
		}
		jSelect.change( (_)->{
			settings.v.fieldsRender = FieldsRender.createByName( jSelect.val() );
			onSettingChanged();
		});

		// Navigation keys
		var jNavKeys = jForm.find("#navKeys");
		jNavKeys.empty();
		for(k in Settings.NavigationKeys.getConstructors()) {
			var nk = Settings.NavigationKeys.createByName(k);
			var jOpt = new J('<option value="$k"/>');
			jNavKeys.append(jOpt);
			jOpt.text(k.toUpperCase());
			if( nk==settings.v.navigationKeys )
				jOpt.prop("selected",true);
		}
		jNavKeys.change( (_)->{
			settings.v.navigationKeys = Settings.NavigationKeys.createByName( jNavKeys.val() );
			onSettingChanged();
		});

		// Mouse wheel speed
		var i = Input.linkToHtmlInput(settings.v.mouseWheelSpeed, jForm.find("#mouseWheelSpeed"));
		i.setBounds(0.25, 3);
		i.enablePercentageMode();
		i.onChange = ()->{
			onSettingChanged();
		}

		// App scaling
		var jScale = jForm.find("#appScale");
		jScale.empty();
		for(s in [0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5]) {
			var jOpt = new J('<option value="$s"/>');
			jScale.append(jOpt);
			jOpt.text('${Std.int(s*100)}%');
			if( s==1 )
				jOpt.append(" "+L.t._("(default)"));
			if( s==settings.v.appUiScale)
				jOpt.prop("selected",true);
		}
		jScale.change( (_)->{
			settings.v.appUiScale = Std.parseFloat( jScale.val() );
			onSettingChanged();
			electron.renderer.WebFrame.setZoomFactor( settings.getAppZoomFactor() );
		});

		// Font scaling
		var jScale = jForm.find("#fontScale");
		jScale.empty();
		for(s in [0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5]) {
			var jOpt = new J('<option value="$s"/>');
			jScale.append(jOpt);
			jOpt.text('${Std.int(s*100)}%');
			if( s==1 )
				jOpt.append(" "+L.t._("(default)"));
			if( s==settings.v.editorUiScale)
				jOpt.prop("selected",true);
		}
		jScale.change( (_)->{
			settings.v.editorUiScale = Std.parseFloat( jScale.val() );
			onSettingChanged();
		});

		JsTools.parseComponents(jForm);
	}

	override function onClose() {
		super.onClose();

		if( needRestart )
			N.warning( L.t._("Saved. You need to RESTART the app to apply your changes.") );
		else if( anyChange )
			N.success( L.t._("Settings saved.") );
	}

	function hasEditor() {
		return Editor.ME!=null && !Editor.ME.destroyed;
	}

	function onSettingChanged() {
		settings.save();
		anyChange = true;
		if( hasEditor() )
			Editor.ME.ge.emit( AppSettingsChanged );
		updateForm();
		dn.Process.resizeAll();
	}
}