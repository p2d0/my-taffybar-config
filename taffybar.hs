{-# LANGUAGE OverloadedStrings #-}

import Control.Exception (SomeException, handle)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Class
import Data.Map (insert)
import Data.Maybe
import Data.Ratio
import qualified Data.Text as T
import GHC.IO.Encoding (setLocaleEncoding)
import Network.HTTP.Types.URI
import SimpleCmd
import StatusNotifier.Tray
import System.IO (IOMode (ReadMode), hGetContents, hSetEncoding, openFile, utf8, utf8_bom, withFile)
import System.Log.Logger
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
    text <- readFile "/home/andrew/build/twitch-chat-cli/test.txt"
    return $ T.pack $ last $ lines text

main = do
  let -- \61463
      clock = textClockNewWith $ defaultClockConfig {clockFormatString = "%H:%M %a, %d %b"}
      workspaces =
        workspacesNew
          defaultWorkspacesConfig
            { showWorkspaceFn = hideEmpty,
              updateEvents = [ewmhActiveWindow
                             , ewmhStateHidden
                             -- , ewmhCurrentDesktop
                             ],
              updateRateLimitMicroseconds = 1000000
              -- updateRateLimitMicroseconds = 1000,
              -- getWindowIconPixbuf = scaledWindowIconPixbufGetter getWindowIconPixbufFromClass
              -- urgentWorkspaceState = True
            }
      tray = sniTrayNewFromParams defaultTrayParams

      simpleConfig =
        defaultSimpleTaffyConfig
          { startWidgets =
              [
                workspaces
              ],
            barHeight = ScreenRatio $ 1 / 35,
            centerWidgets =
              [ clock,
                commandRunnerNew 1800 "curl" ["-s", "https://wttr.in/?format=%c%20%t%20(%f)"] "Fail"
              ],
            endWidgets =
              [ sniTrayNew
                   -- commandRunnerNew 0.1 "tail" ["-n", "1", "/home/andrew/build/twitch-chat-cli/test.txt"] "FAIL"
                   -- pollingLabelNew 0.1 twitchChat
              ],
            barPosition = Bottom
          }
  setLocaleEncoding utf8
  handle logException $ simpleTaffybar simpleConfig

-- Logs an Http Exception and returns wttr.in's weather unknown label.
logException :: SomeException -> IO ()
logException e = do
  let errmsg = show e
  logM
    "Pepega"
    ERROR
    ("Warning: Couldn't call wttr.in. \n" ++ errmsg)
  return ()
