{-# LANGUAGE OverloadedStrings #-}

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Class
import Data.Map (insert)
import Data.Maybe
import Data.Ratio
import qualified Data.Text as T
import SimpleCmd
import StatusNotifier.Tray
import System.IO (IOMode (ReadMode), openFile, withFile, hSetEncoding, utf8_bom, hGetContents)
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
import System.Taffybar.Widget.WttrIn

twitchChat :: IO T.Text
twitchChat =
  do
    h <- openFile "/home/andrew/build/twitch-chat-cli/test.txt" ReadMode
    hSetEncoding h utf8_bom
    text <- hGetContents h
    return $ T.pack $ last $ lines text

main = do
  let -- \61463
      clock = textClockNewWith $ defaultClockConfig {clockFormatString = "%H:%M %a, %d %b"}
      workspaces =
        workspacesNew
          defaultWorkspacesConfig
            { showWorkspaceFn = hideEmpty,
              updateRateLimitMicroseconds = 1000,
              getWindowIconPixbuf = scaledWindowIconPixbufGetter getWindowIconPixbufFromEWMH,
              urgentWorkspaceState = True
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
              [ sniTrayNew,
                -- commandRunnerNew
                --   0.1
                --   "tail"
                --   ["-n", "1", "/home/andrew/build/twitch-chat-cli/test.txt"]
                --   "FAIL"
                  pollingLabelNew 0.1 twitchChat
                  -- textWttrNew "http://wttr.in/?format=%c%20%t%20(%f)" 60
              ],
            barPosition = Bottom
          }
  simpleTaffybar simpleConfig

--  | ansifilter -M -f
