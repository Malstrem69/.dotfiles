-- Main
import XMonad
import System.IO (hPutStrLn)
import System.Exit
import qualified XMonad.StackSet as W

-- Actions
import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.MouseResize
import XMonad.Actions.WithAll (sinkAll, killAll)
import XMonad.Actions.CopyWindow (kill1)

-- Data
import Data.Semigroup
import Data.Monoid
import Data.Maybe (fromJust, isJust)
import qualified Data.Map as M

-- Hooks
import XMonad.Hooks.DynamicProperty
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, isDialog, doCenterFloat, doRectFloat)

-- Layouts
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.ResizableTile
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowNavigation
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

-- Utilities
import XMonad.Util.Dmenu
import XMonad.Util.EZConfig(additionalKeysP)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Scratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import Graphics.X11.ExtraTypes.XF86

------------------------------------------------------------------------
-- My Strings
------------------------------------------------------------------------
myTerminal :: String
myTerminal = "alacritty"        -- Default terminal

myDmenu :: String
myDmenu = "dmenu_run -h 26 -bw 2 -W 1000 -l 10 -p Run:" -- Dmenu

myModMask :: KeyMask
myModMask = mod4Mask            -- Super Key (--mod4Mask= super key --mod1Mask= alt key --controlMask= ctrl key --shiftMask= shift key)

myBorderWidth :: Dimension
myBorderWidth   = 2             -- Window border

myNormColor :: String           -- Border color of normal windows
myNormColor   = "#212733"

myFocusColor :: String          -- Border color of focused windows
myFocusColor  = "#55b4d4"

myEmacs :: String
myEmacs = "emacsclient -c -a 'emacs' "  -- Makes emacs keybindings easier to type
------------------------------------------------------------------------
-- Space between Tiling Windows
------------------------------------------------------------------------
mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border 30 10 10 10) True (Border 10 10 10 10) True

------------------------------------------------------------------------
-- Layout Hook
------------------------------------------------------------------------
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts full
               $ mkToggle (NBFULL ?? NOBORDERS ?? MIRROR ?? EOT) myDefaultLayout
             where
               myDefaultLayout =      withBorder myBorderWidth tall
                                  ||| full
                                  ||| grid
                                  ||| mirror
------------------------------------------------------------------------
-- Tiling Layouts
------------------------------------------------------------------------
tall     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Tall</fc>"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 8
           $ mySpacing 5
           $ ResizableTall 1 (3/100) (1/2) []               
grid     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Grid</fc>"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 12
           $ mySpacing 5
           $ mkToggle (single MIRROR)
           $ Grid (16/10)   
mirror   = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Mirror</fc>"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 6
           $ mySpacing 5
           $ Mirror  
           $ ResizableTall 1 (3/100) (1/2) []            
full     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Full</fc>"]
           $ Full                     

------------------------------------------------------------------------
-- Workspaces
------------------------------------------------------------------------
xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where
    doubleLts x = [x]
myWorkspaces :: [String]
myWorkspaces = clickable . (map xmobarEscape) $ [" <fn=3>\61713</fn> ", " <fn=3>\61713</fn> ", " <fn=3>\61713</fn> ", " <fn=3>\61713</fn> ", " <fn=3>\61713</fn> "]
  where
    clickable l = ["<action=xdotool key super+" ++ show (i) ++ "> " ++ ws ++ "</action>" | (i, ws) <- zip [1 .. 5] l]
windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

------------------------------------------------------------------------
-- Scratch Pads
------------------------------------------------------------------------
myScratchPads :: [NamedScratchpad]
myScratchPads =
  [
      NS "nemo"                 "nemo"                 (className =? "nemo")                    (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "terminal"             launchTerminal         (title =? "scratchpad")                  (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
  ]
  where
    launchMocp     = myTerminal ++ " -t ncmpcpp -e ncmpcpp"
    launchTerminal = myTerminal ++ " -t scratchpad"

------------------------------------------------------------------------
-- Custom Keys
-- use "xev" utility in terminal to get keycodes
------------------------------------------------------------------------
myKeys :: [(String, X ())]
myKeys =

    [
    -- Xmonad
        ("M-<KP_Multiply>", spawn "xmonad --recompile && xmonad --restart")                        -- Recompile & Restarts xmonad
      , ("M-S-q", io exitSuccess)                                                                  -- Quits xmonad

    -- System Volume (PulseAudio)
      , ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ +10%")              -- Volume Up
      , ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ -10%")              -- Volume Down
      , ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")                     -- Mute

    -- System Lock
      , ("M-r", spawn "betterlockscreen -l dim -- --time-str='%H:%M'")                             -- Lock Screen

    -- Run Prompt
      , ("M-S-<Return>", spawn (myDmenu))                                                                   -- Run Dmenu
      , ("M-p h", spawn "dm-hub")
    -- Apps
      , ("M-b", spawn "google-chrome-stable")                                                      -- Google-chrome
      , ("M-<Return>", spawn (myTerminal))                                                         -- Terminal

    -- Flameshot
      , ("<Print>", spawn "flameshot gui")                                                         -- Flameshot GUI (screenshot)

    -- Windows navigation
      , ("M-<Space>", sendMessage NextLayout)                                       -- Rotate through the available layout algorithms
      , ("M1-f", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts)        -- Toggles full width
      , ("M1-s", sinkAll)                                                           -- Push all windows back into tiling      
      , ("M1-S-p>", withFocused $ windows . W.sink)                                 -- Push window back into tiling
      , ("M1-t", sendMessage (T.Toggle "floats"))                                   -- Toggles my 'floats' layout
      , ("M-<Left>", windows W.swapMaster)                                          -- Swap the focused window and the master window
      , ("M-<Up>", windows W.swapUp)                                                -- Swap the focused window with the previous window
      , ("M-<Down>", windows W.swapDown)                                            -- Swap the focused window with the next window     

    -- Workspaces
      , ("M-.", nextScreen)                                                         -- Switch focus to next monitor
      , ("M-,", prevScreen)                                                         -- Switch focus to prev monitor
      , ("M-S-.", shiftTo Next nonNSP >> moveTo Next nonNSP)                        -- Shifts focused window to next ws
      , ("M-S-,", shiftTo Prev nonNSP >> moveTo Prev nonNSP)                        -- Shifts focused window to prev ws

    -- Kill windows
      , ("M-q", kill1)                                                              -- Quit the currently focused client
      , ("M-S-w", killAll)                                                          -- Quit all windows on current workspace
      , ("M-<Escape>", spawn "xkill")                                               -- Kill the currently focused client

    -- Increase/decrease spacing (gaps)
      , ("M-C-j", decWindowSpacing 4)                                               -- Decrease window spacing
      , ("M-C-k", incWindowSpacing 4)                                               -- Increase window spacing
      , ("M-C-h", decScreenSpacing 4)                                               -- Decrease screen spacing
      , ("M-C-l", incScreenSpacing 4)                                               -- Increase screen spacing

    -- Window resizing
      , ("M1-<Left>", sendMessage Shrink)                                           -- Shrink horiz window width
      , ("M1-<Right>", sendMessage Expand)                                          -- Expand horiz window width
      , ("M1-<Down>", sendMessage MirrorShrink)                                     -- Shrink vert window width
      , ("M1-<Up>", sendMessage MirrorExpand)                                       -- Expand vert window width

    -- Brightness Display 1
      , ("M-<F1>", spawn "sh $HOME/.xmonad/scripts/brightness.sh + DisplayPort-0")  -- Night Mode
      , ("M-<F2>", spawn "sh $HOME/.xmonad/scripts/brightness.sh - DisplayPort-0")  -- Day mode
      , ("M-S-<F1>", spawn "sh $HOME/.xmonad/scripts/brightness.sh = DisplayPort-0")-- Reset redshift light

    -- Brightness Display 2
      , ("M1-<F1>", spawn "sh $HOME/.xmonad/scripts/brightness.sh + HDMI-A-1")      -- Night Mode
      , ("M1-<F2>", spawn "sh $HOME/.xmonad/scripts/brightness.sh - HDMI-A-1")      -- Day mode
      , ("M1-S-<F1>", spawn "sh $HOME/.xmonad/scripts/brightness.sh = HDMI-A-1")    -- Reset redshift light

    -- Scratchpad windows
      , ("M-m", namedScratchpadAction myScratchPads "ncmpcpp")                      -- Ncmpcpp Player
      , ("M-o", namedScratchpadAction myScratchPads "spotify")                      -- Spotify
      , ("M-a", namedScratchpadAction myScratchPads "nautilus")                     -- Nautilus
      , ("M-d", namedScratchpadAction myScratchPads "discord")                      -- Discord
      , ("M-w", namedScratchpadAction myScratchPads "whatsapp-for-linux")           -- WhatsApp
      , ("M-t", namedScratchpadAction myScratchPads "terminal")                     -- Terminal

    -- KB_GROUP Emacs (SUPER-e followed by a key)
      , ("M-e e", spawn (myEmacs))   -- emacs dashboard
      , ("M-e b", spawn (myEmacs ++ ("--eval '(ibuffer)'")))   -- list buffers
      , ("M-e d", spawn (myEmacs ++ ("--eval '(dired nil)'"))) -- dired
      , ("M-e i", spawn (myEmacs ++ ("--eval '(erc)'")))       -- erc irc client
      , ("M-e n", spawn (myEmacs ++ ("--eval '(elfeed)'")))    -- elfeed rss
      , ("M-e s", spawn (myEmacs ++ ("--eval '(eshell)'")))    -- eshell
      , ("M-e t", spawn (myEmacs ++ ("--eval '(mastodon)'")))  -- mastodon.el
      , ("M-e v", spawn (myEmacs ++ ("--eval '(+vterm/here nil)'"))) -- vterm if on Doom Emacs

    ]  

------------------------------------------------------------------------
-- Moving between WS
------------------------------------------------------------------------
      where nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
            nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))

------------------------------------------------------------------------
-- Floats
------------------------------------------------------------------------
myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     [ className =? "confirm"                           --> doFloat
     , className =? "file_progress"                     --> doFloat
     , resource  =? "desktop_window"                    --> doIgnore
     , className =? "MEGAsync"                          --> doFloat
     , className =? "mpv"                               --> doCenterFloat
     , className =? "Gthumb"                            --> doCenterFloat
     , className =? "Ristretto"                         --> doCenterFloat
     , className =? "feh"                               --> doCenterFloat
     , className =? "Galculator"                        --> doCenterFloat
     , className =? "Gcolor3"                           --> doFloat
     , className =? "dialog"                            --> doFloat
     , className =? "Downloads"                         --> doFloat
     , className =? "Save As..."                        --> doFloat
     , className =? "Xfce4-appfinder"                   --> doFloat
     , className =? "Org.gnome.NautilusPreviewer"       --> doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)
     , className =? "Xdg-desktop-portal-gtk"            --> doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)
     , className =? "Thunar"                            --> doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)
     , className =? "Sublime_merge"                     --> doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)
     , isFullscreen -->  doFullFloat
     , isDialog --> doCenterFloat
     ] <+> namedScratchpadManageHook myScratchPads

myHandleEventHook :: Event -> X All
myHandleEventHook = dynamicPropertyChange "WM_NAME" (title =? "Spotify" --> floating)
        where floating = doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)

------------------------------------------------------------------------
-- Startup Hooks
------------------------------------------------------------------------
myStartupHook = do
    spawnOnce "$HOME/.xmonad/scripts/autostart.sh"
    spawnOnce "/usr/bin/emacs --daemon"
    setWMName "LG3D"

------------------------------------------------------------------------
-- Main Do
------------------------------------------------------------------------
main :: IO ()
main = do
        xmproc0 <- spawnPipe ("xmobar -x 0 ~/.xmobarrc0")
        -- xmproc1 <- spawnPipe "/usr/bin/xmobar -x 1 ~/.xmobarrc0"
        xmonad $ ewmh def
                { manageHook = myManageHook <+> manageDocks
                , logHook = dynamicLogWithPP $ filterOutWsPP [scratchpadWorkspaceTag] $ xmobarPP
                        { ppOutput = \x -> hPutStrLn xmproc0 x -- xmobar on monitor 1
                         --             >> hPutStrLn xmproc1 x -- xmobar on monitor 2
                         , ppCurrent = xmobarColor "#ff79c6" "" . \s -> " <fn=2>\61713</fn>"
                         , ppVisible = xmobarColor "#d4bfff" ""
                         , ppHidden = xmobarColor "#d4bfff" ""
                         , ppHiddenNoWindows = xmobarColor "#d4bfff" ""
                         , ppTitle = xmobarColor "#c7c7c7" "" . shorten 60
                         , ppSep =  "<fc=#212733>  <fn=1> </fn> </fc>"
                         , ppOrder  = \(ws:l:_:_)  -> [ws,l]
                        }
                , modMask            = mod4Mask
                , layoutHook         = myLayoutHook
                , workspaces         = myWorkspaces
                , terminal           = myTerminal
                , borderWidth        = myBorderWidth
                , startupHook        = myStartupHook
                , handleEventHook    = myHandleEventHook
                , normalBorderColor  = myNormColor
                , focusedBorderColor = myFocusColor
                } `additionalKeysP` myKeys

-- Find app class name
-- xprop | grep WM_CLASS
-- https://xmobar.org/#diskio-disks-args-refreshrate
