{-# LANGUAGE OverloadedStrings #-}

import ClickableWidget
import Control.Monad.Trans.Class
import Data.Map (insert)
import Data.Maybe
import StatusNotifier.Tray
import System.Taffybar
import System.Taffybar.Information.CPU
import System.Taffybar.Information.EWMHDesktopInfo
import System.Taffybar.Information.X11DesktopInfo
import System.Taffybar.SimpleConfig
import System.Taffybar.Util
import System.Taffybar.Widget
import System.Taffybar.Widget.Generic.Graph
import System.Taffybar.Widget.Generic.PollingGraph
import System.Taffybar.Widget.Generic.PollingLabel

cpuCallback = do
  (_, systemLoad, totalLoad) <- cpuLoad
  return [totalLoad, systemLoad]

getFullWorkspaceNames :: X11Property [(WorkspaceId, String)]
getFullWorkspaceNames = go <$> readAsListOfString Nothing "_NET_DESKTOP_FULL_NAMES"
  where
    go = zip [WorkspaceId i | i <- [0 ..]]

workspaceNamesLabelSetter workspace =
  remapNSP . fromMaybe "" . lookup (workspaceIdx workspace)
    <$> liftX11Def [] getFullWorkspaceNames
  where
    remapNSP "NSP" = "S"
    remapNSP n = n

main = do
  let cpuCfg =
        defaultGraphConfig
          { graphDataColors = [(0, 1, 0, 1), (1, 0, 1, 0.5)]
          }
      -- \61463
      clock = textClockNewWith $ defaultClockConfig {clockFormatString = "%H:%M %a, %d %b"}
      -- cpu = pollingGraphNew cpuCfg 0.5 cpuCallback
      workspaces =
        workspacesNew
          defaultWorkspacesConfig
            { showWorkspaceFn = hideEmpty,
              updateRateLimitMicroseconds = 1000,
              getWindowIconPixbuf = scaledWindowIconPixbufGetter  getWindowIconPixbufFromEWMH,
              urgentWorkspaceState = True
            }

      -- workspaces =
      --   flip widgetSetClassGI "workspaces"
      --     =<< workspacesNew
      --       defaultWorkspacesConfig
      --         { minIcons = 1,
      --           getWindowIconPixbuf =
      --             scaledWindowIconPixbufGetter $
      --               getWindowIconPixbufFromChrome
      --                 <|||> unscaledDefaultGetWindowIconPixbuf
      --                 <|||> (\size _ -> lift $ loadPixbufByName size "application-default-icon"),
      --           widgetGap = 0,
      --           showWorkspaceFn = hideEmpty,
      --           updateRateLimitMicroseconds = 100000
      --         }
      vpn =
        clickableWidget
          ClickableWidgetConfig
            { pollingPeriod = 2,
              command = "~/.config/polybar/wg-status.sh --status",
              onLeftClick = "~/.config/polybar/wg-status.sh",
              onFail = "Failed"
            }
      tray = sniTrayNewFromParams defaultTrayParams
      simpleConfig =
        defaultSimpleTaffyConfig
          { startWidgets =
              [ workspaces
              ],
            barHeight = ScreenRatio $ 1 / 35,
            centerWidgets =
              [ clock
              ],
            endWidgets =
              [ -- cpu,
                sniTrayNew,
                commandRunnerNew 6000 "curl" ["-s", "https://wttr.in/?format=%c%20%t%20(%f)"] "Failed",
                vpn
              ],
            barPosition = Bottom,
            monitorsAction = useAllMonitors
          }
  simpleTaffybar simpleConfig
