try (destroydialog roViewportLayout);catch(err)
rollout roViewportLayout "Viewport Layout Manager" width:314 height:40
(

	--------------------------------------------------------------------------------------------
	-- interface
	--------------------------------------------------------------------------------------------
	
	dropdownList ddlLayouts "" pos:[0,6] width:208 height:21
	button btnReset "Reset" pos:[212,6] width:40 height:20 tooltip:"Reset all viewports to default settings"
	--checkButton ckbBg "Bg" pos:[256,6] width:20 height:20
	button btnBg "Bg" pos:[256,6] width:20 height:20 tooltip:"Toggle viewport background on / off"
	button btnCfg "Cfg" pos:[276,6] width:20 height:20 tooltip:"Open Viewport Background dialog..."
		

	--------------------------------------------------------------------------------------------
	-- variables
	--------------------------------------------------------------------------------------------

		local iniFile	= "$max/viewportLayout.ini"

		local vpt
		local shading
		local safeFrame
		local bgImageOn
		local bgImage
		local viewTM
		local iniString, iniArr

		local defaultTM = (matrix3 [0.707107,0.353553,-0.612372] [-0.707107,0.353553,-0.612372] [0,0.866025,0.5] [0,0,-250])

		local activeVpt

		local allowableViews = #(
			#view_left, 
			#view_right, 
			#view_top, 
			#view_bottom, 
			#view_front, 
			#view_back, 
			#view_iso_user, 
			#view_persp_user, 
			#view_camera, 
			#view_grid, 
			#view_none, 
			#view_spot, 
			#view_shape
		)

		local vptOptions = #(
			#(#layout_4,	"4 viewports - all same size"),
			#(undefined,	"--------------------------------------------------------------------------------------"),
			#(#layout_4vl,	"4 viewports - 3 on left, 1 on right"),
			#(#layout_4vr,	"4 viewports - 1 on left, 3 on right"),
			#(#layout_4ht,	"4 viewports - 3 on top, 1 on bottom"),
			#(#layout_4hb,	"4 viewports - 1 on top, 3 on bottom"),
			#(undefined,	"--------------------------------------------------------------------------------------"),
			#(#layout_3vl,	"3 viewports - 2 on left, 1 on right"),
			#(#layout_3vr,	"3 viewports - 1 on left, 2 on right"),
			#(#layout_3ht,	"3 viewports - 2 on top, 1 on bottom"),
			#(#layout_3hb,	"3 viewports - 1 on top, 2 on bottom"),
			#(undefined,	"--------------------------------------------------------------------------------------"),
			#(#layout_2v,	"2 viewports - vertical split, both same size"),
			#(#layout_2h,	"2 viewports - horizontal split, both same size"),
			#(#layout_2ht,	"2 viewports - horizontal split, top smaller"),
			#(#layout_2hb,	"2 viewports - horizontal split, top larger"),
			#(undefined,	"--------------------------------------------------------------------------------------"),
			#(#layout_1,	"1 viewport")
		)
	/*
	*/
		local vptDefaults = #(
			#(#layout_4,	#view_top,		#view_right,	#view_front,	#view_persp_user	),
			#(#layout_4vl,	#view_top,		#view_front,	#view_left,		#view_persp_user	),
			#(#layout_4vr,	#view_top,		#view_front,	#view_left,		#view_persp_user	),
			#(#layout_4ht,	#view_top,		#view_front,	#view_left,		#view_persp_user	),
			#(#layout_4hb,	#view_persp_user,	#view_top,	#view_front,	#view_left			),
			#(#layout_3vl,	#view_top,		#view_front,	#view_persp_user	),
			#(#layout_3vr,	#view_top,		#view_front,	#view_persp_user	),
			#(#layout_3ht,	#view_top,		#view_left,		#view_persp_user	),
			#(#layout_3hb,	#view_top,		#view_left,		#view_persp_user	),
			#(#layout_2v,	#view_top,		#view_persp_user	),
			#(#layout_2h,	#view_left,		#view_persp_user	),
			#(#layout_2ht,	#view_left,		#view_persp_user	),
			#(#layout_2hb,	#view_top,		#view_left			),
			#(#layout_1,	#view_persp_user)
		)
	
	--------------------------------------------------------------------------------------------
	-- callbacks
	--------------------------------------------------------------------------------------------

		fn checkVptBgState =
		(
			--print viewport.activeViewport
			if viewport.activeViewport != activeVpt then
			(
				ckbBg.state = viewport.DispBkgImage
				InvalidateAllBackgrounds()
			)
		)

		fn vptManager_cb = checkVptBgState()


	--------------------------------------------------------------------------------------------
	-- functions
	--------------------------------------------------------------------------------------------

		function updateDropdown layout =
		(
			local index = 0
			while index == 0 do
			(
				for i = 1 to vptOptions.count do
				(
					if vptOptions[i][1] == layout then index = i
					exit
				)
			)
			ddlLayouts.selection = index
		)
			
		fn resetLayout =
		(
			-- get default views
				local layoutName = viewport.getLayout()
				local arrViews
				for arr in vptDefaults where arr[1] == layoutName do
				(
					arrViews = copy arr #nomap
					deleteItem arrViews 1
				)
			-- reset views
				for i = 1 to viewport.numViews do
				(
					-- view
						viewport.activeViewport = i
						
					-- view type
						if (viewport.getType()) != arrViews[i] then viewport.setType arrViews[i]
					
					-- other settings
						if arrViews[i] == #view_persp_user then 
						(
							viewport.setRenderLevel #smoothhighlights
							--viewport.setTM defaultTM
						)
						else
						(
							viewport.setRenderLevel #wireFrame
						)
						
						viewport.DispBkgImage 	= false
						displaySafeFrames 		= false
				)
		)
			
		function saveSettings =
		(
			-- variables
				local layout		= viewport.getLayout()
				local oldActiveVpt = viewport.activeViewport
				
			-- get views
				for i = 1 to viewport.numViews do
				(
					-- view
						viewport.activeViewport = i
						
					-- view type
						vpt = viewport.gettype()
						if vpt == #view_camera then vpt = (viewport.getCamera()).name
					
					-- other settings
						shading		= viewport.GetRenderLevel()
						bgImage		= backgroundImageFileName
						bgImageOn	= if viewport.DispBkgImage then 1 else 0
						safeFrame	= if displaySafeFrames then 1 else 0
						viewTM		= if vpt == #view_iso_user OR vpt == #view_persp_user then (viewport.getTM()) else ""
						
						iniString	= 	vpt as string +"|"+ 
										shading as string +"|"+ 
										bgImage as string +"|"+ 
										bgImageOn as string +"|"+ 
										safeFrame as string +"|"+ 
										viewTM as string
						
					-- ini setting
						setINISetting iniFile layout (i as string) iniString
				)
			-- ini setting
				setINISetting iniFile layout "activeVpt" (oldActiveVpt as string)

			-- cleanup
				viewport.activeViewport = oldActiveVpt
		)

		function loadSettings =
		(
			
			-- variables
				local layout		= viewport.getLayout()
				local oldActiveVpt = viewport.activeViewport

/*
			-- debug
				format "----------------------------------------------------\n"
				format "layout: %\n" layout
*/
			-- get views
				for i = 1 to viewport.numViews do
				(
					-- view
						viewport.activeViewport = i
						
					-- ini setting
						iniString	= getINISetting iniFile layout (i as string)
						iniArr		= filterstring iniString "|"
					
					-- view type
						vpt			= iniArr[1]
						if vpt != undefined AND vpt != "" then
						(
							if finditem allowableViews (vpt as name) != 0 then viewport.settype (vpt as name)
							else
							(
								local cam = getNodeByName vpt
								if cam != undefined then viewport.setCamera cam
							)
						)
					--messagebox (vpt as string)
						
					-- other settings
						if iniArr[2] != undefined AND iniArr[2] != "" then viewport.setRenderLevel(iniArr[2] as name)
						if iniArr[3] != undefined AND iniArr[3] != "" then
						(
							if getFileSize iniArr[3] != 0 then backgroundImageFileName = iniArr[3]
						)
						if iniArr[4] != undefined AND iniArr[4] != "" then viewport.DispBkgImage = if iniArr[4] == "1" then true else false
						if iniArr[5] != undefined AND iniArr[5] != "" then displaySafeFrames = if iniArr[5] == "1" then true else false
						if iniArr[6] != undefined AND iniArr[6] != "" then
						(
							execute ("vptMatrix = " + iniArr[6])
							try(viewport.setTM vptMatrix)
							catch(
								format "Could not set viewport matrix...\n"
							)
						)
/*
					-- debug
--						format "\n view: %\n" i
						format "\n	view %:		%\n" i iniArr[1]
						format "	shading:	%\n" iniArr[2]
						format "	bgFile:		%\n" iniArr[3]
						format "	bgOn:		%\n" iniArr[4]
						format "	safeframe:	%\n" iniArr[5]
						format "	viewTM:		%\n" iniArr[6]
*/
				)
					
			-- cleanup
				local oldActiveVpt = getINISetting iniFile layout "activeVpt"
				viewport.activeViewport = if oldActiveVpt != "" then (oldActiveVpt as integer) else 1
				checkVptBgState()
				activeVpt = viewport.activeViewport
				checkVptBgState()
		)
		

	--------------------------------------------------------------------------------------------
	-- handlers
	--------------------------------------------------------------------------------------------

		on ddlLayouts selected index do
		(
			if vptOptions[index][1] != undefined then
			(
				saveSettings()
				viewport.setLayout vptOptions[index][1]
				loadSettings()
				viewport.SetRenderLevel (viewport.getRenderLevel())
			)
			else updateDropdown (viewport.getLayout())

			enableSceneRedraw()
			forcecompleteredraw()
			redrawViews()
		)
			
		on btnReset pressed do
		(
			resetLayout()
		)
	
		on ckbBg changed state do
		(
			viewport.DispBkgImage = state
			InvalidateAllBackgrounds()
		)

		on btnBg pressed do
		(
			viewport.DispBkgImage = NOT viewport.DispBkgImage
			InvalidateAllBackgrounds()
		)
	
		on btnCfg pressed do
		(
			actionMan.executeAction 0 "40095"  -- Views: Viewport Background
		)


		on roViewportLayout open do
		(
			-- dropdown
				ddlLayouts.items = for a in vptOptions collect a[2]
				updateDropdown (viewport.getLayout())
			-- callback for bg image button
				if ckbBg != undefined then registerRedrawViewsCallback vptManager_cb
			-- vpt matrix
				global vptMatrix = defaultTM

		)
			
		on roViewportLayout close do
		(
			unregisterRedrawViewsCallback vptManager_cb
		)
			
)
createdialog roViewportLayout style:#(#style_titlebar, #style_border, #style_sysmenu)
cui.RegisterDialogBar roViewportLayout style:#(#cui_dock_top, #cui_dock_bottom, #cui_floatable)
