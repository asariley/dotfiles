{-# OPTIONS_GHC -Wall -Werror -Wno-unused-imports #-}

import Data.Bits ((.|.))
import qualified Data.Map as M
import Data.Semigroup (Endo)
import Graphics.X11.ExtraTypes.XF86 as XF86
import Graphics.X11.ExtraTypes.XF86 ()
import System.Exit (ExitCode(ExitSuccess), exitWith)
import System.IO ()
import XMonad
  ( Choose, KeyMask, KeySym, Layout, LayoutMessages(ReleaseResources), Query, WindowSet, X, XConfig(XConfig), (<+>), (-->), (=?), borderWidth
  , broadcastMessage, className, composeAll, doShift, focusedBorderColor, focusFollowsMouse, handleEventHook, io, keys, kill, layoutHook, manageHook, modMask, mod4Mask
  , normalBorderColor, restart, sendMessage, setLayout, shiftMask, spawn, startupHook, stringProperty, terminal, windows, withFocused, workspaces
  , xmonad
  )
import qualified XMonad
import XMonad.Actions.CycleWS (nextWS, prevWS)
import XMonad.Config.Desktop (desktopConfig)
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.FloatNext (floatNextHook, toggleFloatAllNew, toggleFloatNext)
import XMonad.Hooks.ManageDocks (AvoidStruts, ToggleStruts(ToggleStruts), avoidStruts, docks, manageDocks)
import XMonad.Hooks.ManageHelpers (doRectFloat)
import XMonad.Layout ((|||), Full(Full), IncMasterN(IncMasterN), ChangeLayout(NextLayout), Resize(Expand, Shrink))
import qualified XMonad.Layout.Decoration as D
import XMonad.Layout.LayoutModifier (ModifiedLayout)
import XMonad.Layout.Maximize (Maximize, maximize, maximizeRestore)
import XMonad.Layout.NoBorders (SmartBorder, smartBorders)
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.ResizableTile (ResizableTall(ResizableTall), MirrorResize(MirrorExpand, MirrorExpand, MirrorShrink))
import XMonad.Layout.Simplest (Simplest(Simplest))
import XMonad.Layout.Spacing (Border(Border), Spacing, spacingRaw, toggleWindowSpacingEnabled)
import XMonad.Layout.TabBarDecoration (XPPosition(Top), tabBar, shrinkText, resizeVertical)
import XMonad.Prompt (XPConfig)
import qualified XMonad.Prompt as Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch, fuzzySort)
import qualified XMonad.Prompt.Shell as ShellPrompt
import XMonad.Prompt.Window (WindowPrompt(Goto, Bring), windowMultiPrompt, allWindows, wsWindows)
import XMonad.Prompt.XMonad (xmonadPrompt)
import qualified XMonad.StackSet as StackSet
import XMonad.Util.SpawnOnce (spawnOnce, spawnOnOnce)


myTerminal :: String
myTerminal = "kitty"

codeWS, referenceWS, commsWS, officeWS, slackWS, remoteWS :: String
codeWS = "Code"
referenceWS = "Reference"
commsWS = "Meet"
officeWS = "Office"
slackWS = "Slack"
remoteWS = "Remote"
myWorkspaces :: [String]
myWorkspaces = [codeWS, referenceWS, commsWS, officeWS, slackWS, remoteWS]

gaps :: l a -> ModifiedLayout Spacing l a
gaps = spacingRaw True (Border 0 0 0 0) False (Border 4 4 4 4) False -- gaps (border / window spacing)

-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
myManageHook :: Query (Endo WindowSet)
myManageHook = composeAll . concat $
  [ [className =? "Slack" --> doShift slackWS]
  , [className =? "Sublime_merge" --> doShift referenceWS]
  , [className =? "zoom" --> doShift commsWS]
  , [className =? c --> doRectFloat (StackSet.RationalRect 0.3 0.3 0.4 0.4) | c <- floatsClass]
  , [wmName =? "sxiv" -->  doRectFloat (StackSet.RationalRect 0.3 0.3 0.4 0.4)]
  ]
  where
    wmName = stringProperty "WM_NAME"
    floatsClass = []

-- runs whenever XMonad is started (or restarted)
myStartupHook :: X ()
myStartupHook = do
  spawnOnce "polybar main"
  spawnOnOnce commsWS "slack --silent"
  spawnOnOnce commsWS "QT_SCALE_FACTOR=2 zoom-us"
  spawnOnOnce referenceWS "firefox"
  spawnOnOnce codeWS "obsidian"
  spawnOnOnce codeWS myTerminal

myNewManageHook :: Query (Endo WindowSet)
myNewManageHook = composeAll
  [ myManageHook
  , floatNextHook
  , manageHook desktopConfig
  ]

data ScrotSource = ScrotSelection | ScrotWindow
data ScrotTarget = ScrotFile | ScrotClipboard
--TODO make a notification for each of these
scrot :: ScrotSource -> ScrotTarget -> X ()
scrot ScrotSelection ScrotClipboard = spawn "SCROT_PATH=$(date +\"/tmp/scrot-shot%Y-%m-%dT%H-%M-%S.png\") bash -c 'sleep 0.2 && scrot --line style=dash,width=3 --select $SCROT_PATH && xclip -selection clipboard -target image/png $SCROT_PATH'"
scrot ScrotWindow    ScrotClipboard = spawn "SCROT_PATH=$(date +\"/tmp/scrot-shot%Y-%m-%dT%H-%M-%S.png\") bash -c 'scrot -u $SCROT_PATH && xclip -selection clipboard -target image/png $SCROT_PATH'"
scrot ScrotSelection ScrotFile      = spawn "SCROT_PATH=$(date +\"~/scrot-%Y-%m-%dT%H-%M-%S.png\") bash -c 'sleep 0.2 && scrot --line style=dash,width=3 --select $SCROT_PATH'"
scrot ScrotWindow    ScrotFile      = spawn "SCROT_PATH=$(date +\"~/scrot-%Y-%m-%dT%H-%M-%S.png\") bash -c 'scrot -u $SCROT_PATH'"

runInKitty :: String -> X ()
runInKitty cmd = spawn $ "kitty --hold zsh -c \"" <> cmd <> "\""

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig { XMonad.modMask = modm }) = M.fromList $
  [ ((modm              , XMonad.xK_Return), spawn myTerminal)
  , ((modm              , XMonad.xK_p     ), spawn "dmenu_run")
  , ((modm              , XMonad.xK_Tab   ), nextWS)
  , ((modm .|. shiftMask, XMonad.xK_Tab   ), prevWS)
  , ((modm              , XMonad.xK_j     ), windows StackSet.focusDown) -- %! Move focus to the next window
  , ((modm              , XMonad.xK_k     ), windows StackSet.focusUp)
  , ((modm              , XMonad.xK_comma ), sendMessage (IncMasterN 1)) -- %! Increment the number of windows in the master area
  , ((modm              , XMonad.xK_period), sendMessage (IncMasterN (-1))) -- %! Deincrement the number of windows in the master area
  , ((modm              , XMonad.xK_space ), sendMessage NextLayout) -- %! Rotate through the available layout algorithms
  , ((modm .|. shiftMask, XMonad.xK_space ), setLayout $ layoutHook conf) -- %!  Reset the layouts on the current workspace to default
  , ((modm              , XMonad.xK_i     ), withFocused $ windows . StackSet.sink) -- %! Push window back into tiling
  , ((modm              , XMonad.xK_h     ), sendMessage Shrink) -- %! Shrink the master area
  , ((modm              , XMonad.xK_l     ), sendMessage Expand) -- %! Expand the master area
  , ((modm              , XMonad.xK_m     ), windows StackSet.swapMaster) -- %! Swap the focused window and the master window
  , ((modm .|. shiftMask, XMonad.xK_j     ), windows StackSet.swapDown) -- %! Swap the focused window with the next window
  , ((modm .|. shiftMask, XMonad.xK_k     ), windows StackSet.swapUp) -- %! Swap the focused window with the previous window
  , ((modm              , XMonad.xK_m     ), windows StackSet.focusMaster  ) -- %! Move focus to the master window
  , ((modm .|. shiftMask, XMonad.xK_c     ), kill) -- %! Close the focused window
  , ((modm .|. shiftMask, XMonad.xK_a     ), runInKitty "home-manager switch && xmonad --recompile")
  , ((modm .|. shiftMask, XMonad.xK_q     ), broadcastMessage ReleaseResources >> restart "xmonad" True) -- %! Restart xmonad
  , ((modm .|. shiftMask, XMonad.xK_x     ), spawn "p=$(pidof polybar) && kill $p; polybar main")
  , ((modm              , XMonad.xK_f     ), withFocused (sendMessage . maximizeRestore))
  , ((modm              , XMonad.xK_z     ), sendMessage MirrorShrink)
  , ((modm              , XMonad.xK_a     ), sendMessage MirrorExpand)
  , ((modm              , XMonad.xK_u     ), toggleFloatNext)
  , ((modm .|. shiftMask, XMonad.xK_u     ), toggleFloatAllNew)
  , ((modm              , XMonad.xK_b     ), sendMessage ToggleStruts) -- toggle fullscreen (really just lower status bar below everything)
  , ((modm              , XMonad.xK_g     ), toggleWindowSpacingEnabled)
  , ((modm              , XMonad.xK_s     ), scrot ScrotSelection ScrotFile)
  , ((modm .|. shiftMask, XMonad.xK_s     ), scrot ScrotSelection ScrotClipboard)
  , ((modm              , XMonad.xK_d     ), scrot ScrotWindow    ScrotFile)
  , ((modm .|. shiftMask, XMonad.xK_d     ), scrot ScrotWindow    ScrotClipboard)

  , ((0, XF86.xF86XK_AudioMute),         spawn "pactl set-sink-mute alsa_output.pci-0000_00_1f.3.analog-stereo toggle")
  , ((0, XF86.xF86XK_AudioLowerVolume),  spawn "pactl set-sink-volume alsa_output.pci-0000_00_1f.3.analog-stereo -5%")
  , ((0, XF86.xF86XK_AudioRaiseVolume),  spawn "pactl set-sink-volume alsa_output.pci-0000_00_1f.3.analog-stereo +5%")
  , ((0, XF86.xF86XK_AudioMicMute),      spawn "pactl set-source-mute alsa_input.pci-0000_00_1f.3.analog-stereo toggle")
  , ((0, XF86.xF86XK_MonBrightnessDown), spawn "brightnessctl s 3%-")
  , ((0, XF86.xF86XK_MonBrightnessUp),   spawn "brightnessctl s 3%+")
  ]
    ++ [ ((m .|. modm, k), windows $ f i) -- mod-[1..9], Switch to workspace N
       | (i, k) <- zip (workspaces conf) [XMonad.xK_1 .. XMonad.xK_9] -- mod-shift-[1..9], Move client to workspace N
       , (f, m) <- [(StackSet.greedyView, 0), (StackSet.shift, shiftMask)]
       ]
    ++ [ ((m .|. modm, key), XMonad.screenWorkspace sc >>= flip XMonad.whenJust (windows . f)) -- mod-[w,e,r] switch to screen 1,2,3
       | (key, sc) <- zip [XMonad.xK_w, XMonad.xK_e, XMonad.xK_r] [0..] -- mod-shift-[w,e,r] move window to screen 1,2,3
       , (f, m) <- [(StackSet.view, 0), (StackSet.shift, shiftMask)]
       ]

main :: IO ()
main = do
  xmonad . ewmh . docks $ desktopConfig
    { handleEventHook = handleEventHook desktopConfig
    , borderWidth        = 8
    , normalBorderColor  = "#606060"
    , focusedBorderColor = "#f0f0f0"
    , focusFollowsMouse  = False
    , modMask            = mod4Mask
    , terminal           = myTerminal
    , workspaces         = myWorkspaces
    , keys               = myKeys
    , startupHook        = myStartupHook
    , manageHook         = myNewManageHook <+> manageDocks
    , layoutHook         = avoidStruts
                         . gaps
                         . smartBorders
                         . maximize
                         . onWorkspace commsWS (tabs ||| tiles)
                         . onWorkspace referenceWS (tabs ||| tiles)
                         $ tiles ||| tabs
    }
  where
    tabs = tabBar shrinkText theme Top (resizeVertical (D.fi . D.decoHeight $ theme) Simplest)
    tiles = ResizableTall 1 (3 / 100) (0.5) []
    theme = D.Theme
      { D.activeColor         = "#f92672"
      , D.activeBorderColor   = "#f92672"
      , D.activeTextColor     = "#f8f8f2"
      , D.inactiveColor       = "#75715e"
      , D.inactiveBorderColor = "#75715e"
      , D.inactiveTextColor   = "#f8f8f2"
      , D.urgentColor         = "#fd971f"
      , D.urgentBorderColor   = "#fd971f"
      , D.urgentTextColor     = "#f8f8f2"
      , D.decoHeight          = 28
      , D.fontName            = "xft:Fira Code Retina:size=9"
      , D.activeBorderWidth   = 1
      , D.inactiveBorderWidth = 1
      , D.urgentBorderWidth   = 1
      , D.decoWidth           = 200
      , D.windowTitleAddons   = []
      , D.windowTitleIcons    = []
      }

